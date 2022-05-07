/// Response returned from native platform
class SquarePosPluginResponse {
  /// Build response using map recieved from native platform
  SquarePosPluginResponse.fromMap(Map<dynamic, dynamic> response)
      : methodName = response['methodName'],
        status = response['status'],
        message = response['message'];

  // Name of the called method
  String methodName;
  // Status of the response
  bool status;
  // The retured object from native platform
  Map<dynamic, dynamic>? message;

  /// Render a string repesentation of the response
  @override
  String toString() {
    return 'Method: $methodName, status: $status, message: $message';
  }
}
