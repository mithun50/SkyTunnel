import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Information about a running process.
class ProcessInfo {
  final int pid;
  final String command;
  final DateTime startedAt;
  Stream<String>? stdout;
  Stream<String>? stderr;

  ProcessInfo({
    required this.pid,
    required this.command,
    required this.startedAt,
    this.stdout,
    this.stderr,
  });
}

/// Manages system processes (primarily the ngrok process).
class ProcessManager {
  final Map<String, ProcessInfo> _processes = {};
  final Map<String, Process> _rawProcesses = {};

  /// Returns info about all managed processes.
  Map<String, ProcessInfo> get processes => Map.unmodifiable(_processes);

  /// Whether a specific process is running.
  bool isRunning(String processId) {
    return _rawProcesses.containsKey(processId);
  }

  /// Starts a process and tracks it.
  Future<ProcessInfo?> startProcess({
    required String processId,
    required String executable,
    required List<String> arguments,
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    try {
      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        mode: ProcessStartMode.normal,
      );

      final stdoutStream = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      final stderrStream = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      final info = ProcessInfo(
        pid: process.pid,
        command: '$executable ${arguments.join(' ')}',
        startedAt: DateTime.now(),
        stdout: stdoutStream,
        stderr: stderrStream,
      );

      _processes[processId] = info;
      _rawProcesses[processId] = process;

      return info;
    } catch (e) {
      return null;
    }
  }

  /// Stops a managed process.
  Future<bool> stopProcess(String processId) async {
    final process = _rawProcesses[processId];
    if (process == null) return false;

    try {
      process.kill(ProcessSignal.sigterm);
      // Wait briefly for graceful shutdown, then force kill.
      try {
        await process.exitCode.timeout(const Duration(seconds: 3));
      } catch (_) {
        process.kill(ProcessSignal.sigkill);
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      _processes.remove(processId);
      _rawProcesses.remove(processId);
    }
  }

  /// Stops all managed processes.
  Future<void> stopAllProcesses() async {
    final processIds = List<String>.from(_processes.keys);
    for (final id in processIds) {
      await stopProcess(id);
    }
  }

  /// Finds the ngrok executable path.
  Future<String?> findNgrokExecutable() async {
    // Check common locations.
    final platform = Platform.operatingSystem;

    final searchPaths = _getNgrokSearchPaths(platform);

    for (final path in searchPaths) {
      if (await File(path).exists()) {
        return path;
      }
    }

    // Try to find via PATH.
    try {
      final result = await Process.run(
        platform == 'windows' ? 'where' : 'which',
        ['ngrok'],
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim();
        if (output.isNotEmpty) {
          final firstLine = output.split('\n').first.trim();
          if (await File(firstLine).exists()) {
            return firstLine;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  List<String> _getNgrokSearchPaths(String platform) {
    switch (platform) {
      case 'windows':
        return [
          r'C:\ngrok\ngrok.exe',
          '${Platform.environment['USERPROFILE']}\\ngrok\\ngrok.exe',
          '${Platform.environment['LOCALAPPDATA']}\\ngrok\\ngrok.exe',
          '${Platform.environment['PROGRAMFILES']}\\ngrok\\ngrok.exe',
          '${Platform.environment['PROGRAMFILES(X86)']}\\ngrok\\ngrok.exe',
        ];
      case 'linux':
        return [
          '${Platform.environment['HOME']}/ngrok',
          '${Platform.environment['HOME']}/.local/bin/ngrok',
          '/usr/local/bin/ngrok',
          '/usr/bin/ngrok',
          '/opt/ngrok/ngrok',
        ];
      case 'macos':
        return [
          '${Platform.environment['HOME']}/ngrok',
          '${Platform.environment['HOME']}/.local/bin/ngrok',
          '/usr/local/bin/ngrok',
          '/opt/homebrew/bin/ngrok',
          '/usr/bin/ngrok',
        ];
      default:
        return [];
    }
  }

  /// Gets the platform-specific download URL for ngrok.
  String getNgrokDownloadUrl() {
    final platform = Platform.operatingSystem;
    switch (platform) {
      case 'windows':
        return 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip';
      case 'linux':
        return 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz';
      case 'macos':
        if (Platform.version.contains('arm64') ||
            Platform.version.contains('aarch64')) {
          return 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.tgz';
        }
        return 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.tgz';
      default:
        return 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz';
    }
  }

  /// Gets the default ngrok install directory for the current platform.
  String getDefaultNgrokDirectory() {
    final platform = Platform.operatingSystem;
    switch (platform) {
      case 'windows':
        return '${Platform.environment['USERPROFILE']}\\ngrok';
      case 'linux':
        return '${Platform.environment['HOME']}/.local/bin';
      case 'macos':
        return '${Platform.environment['HOME']}/.local/bin';
      default:
        return '${Platform.environment['HOME']}/.local/bin';
    }
  }

  /// Gets the ngrok executable name for the current platform.
  String getNgrokExecutableName() {
    return Platform.isWindows ? 'ngrok.exe' : 'ngrok';
  }

  void dispose() {
    for (final process in _rawProcesses.values) {
      try {
        process.kill(ProcessSignal.sigkill);
      } catch (_) {}
    }
    _processes.clear();
    _rawProcesses.clear();
  }
}
