// Stub for JS interop on non-web platforms
class JsContext {
  dynamic callMethod(String name, [List? args]) => null;
}

final context = JsContext();
