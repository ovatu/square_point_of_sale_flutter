/// Payment response returned from native platform
class SquarePosPaymentResponse {
  /// Server ID for the transation
  late bool status;

  /// Server ID for the transation
  late String? errors;

  /// Server ID for the transation
  late String? transactionID;

  /// Client ID for the transaction
  late String? clientTransactionID;

  /// The userInfo that you passed in with the request
  late String? userInfoString;

  SquarePosPaymentResponse({
    required this.status,
    this.errors,
    this.transactionID,
    this.clientTransactionID,
    this.userInfoString,
  });

  /// Build response using map recieved from native platform
  SquarePosPaymentResponse.fromMap(Map<dynamic, dynamic> response) {
    status = response['status'];
    errors = response['errors'];
    transactionID = response['transactionID'];
    clientTransactionID = response['clientTransactionID'];
    userInfoString = response['userInfoString'];
  }
}
