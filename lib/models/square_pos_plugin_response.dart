/// Response returned from native platform
class SquarePosPluginResponse {
  /// Build response using map recieved from native platform
  SquarePosPluginResponse.fromMap(Map<dynamic, dynamic> response)
      : methodName = response['methodName'],
        status = response['status'],
        message = response['message'];

  String methodName;
  bool status;
  Map<dynamic, dynamic>? message;

  @override
  String toString() {
    return 'Method: $methodName, status: $status, message: $message';
  }
}
