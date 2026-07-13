import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'logger_service.dart';

/// Manages the desktop application window.
class WindowService with WindowListener {
  final LoggerService _logger;
  WindowManager? _windowManager;

  WindowService(this._logger);

  /// Initializes the window with preferred settings.
  Future<void> init() async {
    // Skip on web or non-desktop platforms.
    if (kIsWeb) return;

    try {
      _windowManager = WindowManager.instance;
      await _windowManager!.ensureInitialized();

      // Window options.
      const windowOptions = WindowOptions(
        size: Size(1200, 800),
        minimumSize: Size(900, 600),
        center: true,
        title: 'SkyTunnel',
        titleBarStyle: TitleBarStyle.normal,
        windowButtonVisibility: true,
      );

      await _windowManager!.waitUntilReadyToShow(windowOptions, () async {
        await _windowManager!.show();
        await _windowManager!.focus();
      });

      _windowManager!.addListener(this);

      _logger.info('Window initialized', source: 'WindowService');
    } catch (e) {
      _logger.warning('Window init failed (non-desktop?): $e',
          source: 'WindowService');
    }
  }

  /// Sets the window title.
  Future<void> setTitle(String title) async {
    await _windowManager?.setTitle(title);
  }

  /// Sets the window size.
  Future<void> setSize(Size size) async {
    await _windowManager?.setSize(size);
  }

  /// Sets the minimum window size.
  Future<void> setMinimumSize(Size size) async {
    await _windowManager?.setMinimumSize(size);
  }

  /// Centers the window on screen.
  Future<void> center() async {
    await _windowManager?.center();
  }

  /// Minimizes the window.
  Future<void> minimize() async {
    await _windowManager?.minimize();
  }

  /// Maximizes the window.
  Future<void> maximize() async {
    await _windowManager?.maximize();
  }

  /// Restores the window from minimized/maximized state.
  Future<void> restore() async {
    await _windowManager?.restore();
  }

  /// Closes the window.
  Future<void> close() async {
    await _windowManager?.close();
  }

  /// Returns whether the window is maximized.
  Future<bool> isMaximized() async {
    return await _windowManager?.isMaximized() ?? false;
  }

  /// Returns whether the window is minimized.
  Future<bool> isMinimized() async {
    return await _windowManager?.isMinimized() ?? false;
  }

  /// Sets the window to always be on top.
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    await _windowManager?.setAlwaysOnTop(alwaysOnTop);
  }

  /// Gets the current window bounds.
  Future<Rect?> getBounds() async {
    return await _windowManager?.getBounds();
  }

  // WindowListener callbacks.

  @override
  void onWindowClose() {
    _logger.info('Window closing', source: 'WindowService');
  }

  @override
  void onWindowMaximize() {
    _logger.debug('Window maximized', source: 'WindowService');
  }

  @override
  void onWindowUnmaximize() {
    _logger.debug('Window unmaximized', source: 'WindowService');
  }

  @override
  void onWindowMinimize() {
    _logger.debug('Window minimized', source: 'WindowService');
  }

  @override
  void onWindowRestore() {
    _logger.debug('Window restored', source: 'WindowService');
  }

  @override
  void onWindowResize() {
    // Could save window size to settings.
  }

  @override
  void onWindowMove() {
    // Could save window position to settings.
  }

  void dispose() {
    _windowManager?.removeListener(this);
  }
}
