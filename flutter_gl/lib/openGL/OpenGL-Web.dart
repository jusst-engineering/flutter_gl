import 'package:collection/collection.dart';
import 'dart:ui_web' as ui;
import 'dart:html';

import './OpenGL-Base.dart';
import 'opengl/OpenGLContextES.dart'
    if (dart.library.js) 'opengl/OpenGLContextWeb.dart';

getInstance(Map<String, dynamic> options) {
  return OpenGLWeb(options);
}

class OpenGLWeb extends OpenGLBase {
  late int width;
  late int height;

  late String divId;
  num dpr = 1.0;
  dynamic _gl;
  bool _alpha = false;
  bool _antialias = false;

  dynamic get gl {
    _gl ??= getContext({
      "gl": this
          .element
          .getContext("webgl2", {"alpha": _alpha, "antialias": _antialias})
    });

    return _gl;
  }

  OpenGLWeb(Map<String, dynamic> options) : super(options) {
    this._alpha = options["alpha"] ?? false;
    this._antialias = options["antialias"] ?? false;
    this.width = options["width"];
    this.height = options["height"];
    this.divId = options["divId"];
    this.dpr = options["dpr"];

    final CanvasElement domElement = CanvasElementsProvider.getCanvasElement(width: width, height: height, dpr: dpr);

    this.element = domElement;

    ui.platformViewRegistry.registerViewFactory(divId, (int viewId) {
      return domElement;
    });
  }

  makeCurrent(List<int> egls) {
    // web no need do something
  }

  void disposeCanvas() {
    CanvasElementsProvider.disposeCanvasElement(element);
  }
}

enum CanvasElementLockStatus {locked, unlocked}

/// Provides CanvasElement by caching previously created elements.
///
/// On Flutter Web CanvasElements are not disposed correctly if WebGL context was obtained. Apps stops rendering or
/// get stuck when the number of used platform views is getting close to 15. By reusing CanvasElements we avoid this
/// problem unless more than 15 views are active at the same time.
abstract class CanvasElementsProvider {
  static Map<CanvasElement, CanvasElementLockStatus> canvasElementsRegistry = {};

  static CanvasElement getCanvasElement({required int width,required  int height,required num dpr}) {
    final canvasElement = canvasElementsRegistry.entries.firstWhereOrNull((element) => element.value == CanvasElementLockStatus.unlocked)?.key ?? CanvasElement()..id = 'canvas-id';
    canvasElementsRegistry[canvasElement] = CanvasElementLockStatus.locked;
    canvasElement.width = (width * dpr).toInt();
    canvasElement.height = (height * dpr).toInt();
    return canvasElement;
  }

  static void disposeCanvasElement(CanvasElement canvasElement) {
    canvasElementsRegistry[canvasElement] = CanvasElementLockStatus.unlocked;
  }
}
