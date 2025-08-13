// Web stub for window_manager

mixin WindowListener {
  void onWindowClose() async {}
  void onWindowEvent(String eventName) {}
  void onWindowBlur() {}
  void onWindowFocus() {}
  void onWindowMaximize() {}
  void onWindowMinimize() {}
  void onWindowRestore() {}
}

class WindowOptions {
  const WindowOptions({
    this.size,
    this.minimumSize,
    this.center,
    this.backgroundColor,
    this.skipTaskbar,
    this.titleBarStyle,
  });

  final Size? size;
  final Size? minimumSize;
  final bool? center;
  final dynamic backgroundColor;
  final bool? skipTaskbar;
  final dynamic titleBarStyle;
}

class TitleBarStyle {
  static const normal = 'normal';
}

class Size {
  const Size(this.width, this.height);
  final double width;
  final double height;
}

class WindowManagerStub {
  Future<void> ensureInitialized() async {}
  Future<void> show() async {}
  Future<void> focus() async {}
  Future<void> setPreventClose(bool prevent) async {}
  Future<void> setFullScreen(bool fullScreen) async {}
  Future<void> maximize() async {}
  void waitUntilReadyToShow(WindowOptions options, Function callback) {}
  void addListener(dynamic listener) {}
  void removeListener(dynamic listener) {}
  Future<bool> isPreventClose() async => false;
  Future<void> destroy() async {}
}

final windowManager = WindowManagerStub();
