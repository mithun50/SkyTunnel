import 'dart:io';
import 'logger_service.dart';

/// Result of a port scan.
class PortScanResult {
  final int port;
  final bool isOccupied;
  final String? processName;
  final int? processPid;

  const PortScanResult({
    required this.port,
    required this.isOccupied,
    this.processName,
    this.processPid,
  });

  String get displayName {
    if (!isOccupied) return 'Port $port is free';
    final proc = processName != null ? ' ($processName)' : '';
    return 'Port $port is in use$proc';
  }
}

/// Service to detect if ports are in use by game servers.
class PortDetectionService {
  final LoggerService _logger;

  PortDetectionService(this._logger);

  /// Checks if a specific port is occupied.
  Future<PortScanResult> checkPort(int port) async {
    try {
      final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      await server.close();
      return PortScanResult(port: port, isOccupied: false);
    } catch (e) {
      // Port is occupied - try to identify the process.
      final processInfo = await _getProcessOnPort(port);
      return PortScanResult(
        port: port,
        isOccupied: true,
        processName: processInfo?.name,
        processPid: processInfo?.pid,
      );
    }
  }

  /// Checks multiple ports at once.
  Future<List<PortScanResult>> checkPorts(List<int> ports) async {
    final results = <PortScanResult>[];
    for (final port in ports) {
      results.add(await checkPort(port));
    }
    return results;
  }

  /// Checks if a list of common game server ports are available.
  Future<Map<int, bool>> scanCommonPorts() async {
    const commonPorts = [
      25565, // Minecraft Java
      19132, // Minecraft Bedrock
      7777, // Terraria
      2456, // Valheim
      34197, // Factorio
      8211, // Palworld
      8080, // Generic HTTP
      27015, // Source Engine
      27036, // Steam
    ];

    final results = <int, bool>{};
    for (final port in commonPorts) {
      final scan = await checkPort(port);
      results[port] = scan.isOccupied;
    }
    return results;
  }

  /// Gets the process info for whatever is using a port.
  Future<_ProcessInfo?> _getProcessOnPort(int port) async {
    try {
      final platform = Platform.operatingSystem;

      if (platform == 'linux' || platform == 'macos') {
        // Use lsof or ss to find the process.
        final result = await Process.run('lsof', ['-i', ':$port', '-t']);
        if (result.exitCode == 0) {
          final pids = (result.stdout as String).trim().split('\n');
          if (pids.isNotEmpty && pids.first.isNotEmpty) {
            final pid = int.tryParse(pids.first.trim());
            if (pid != null) {
              // Get process name.
              final nameResult =
                  await Process.run('ps', ['-p', '$pid', '-o', 'comm=']);
              final name = (nameResult.stdout as String).trim();
              return _ProcessInfo(name: name, pid: pid);
            }
          }
        }
      } else if (platform == 'windows') {
        // Use netstat on Windows.
        final result = await Process.run(
          'netstat',
          ['-ano', '-p', 'TCP'],
        );
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          for (final line in output.split('\n')) {
            if (line.contains(':$port') && line.contains('LISTENING')) {
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.isNotEmpty) {
                final pid = int.tryParse(parts.last);
                if (pid != null) {
                  final nameResult = await Process.run(
                    'tasklist',
                    ['/FI', 'PID eq $pid', '/FO', 'CSV', '/NH'],
                  );
                  final nameOutput = (nameResult.stdout as String).trim();
                  final name = nameOutput.isNotEmpty
                      ? nameOutput.split(',').first.replaceAll('"', '')
                      : 'Unknown';
                  return _ProcessInfo(name: name, pid: pid);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.debug('Failed to get process on port $port: $e',
          source: 'PortDetection');
    }
    return null;
  }
}

class _ProcessInfo {
  final String name;
  final int pid;

  const _ProcessInfo({required this.name, required this.pid});
}
