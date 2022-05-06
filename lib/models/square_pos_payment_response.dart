class SquarePosPaymentResponse {
  late String? transactionID;
  late String clientTransactionID;
  late String? userInfoString;

  SquarePosPaymentResponse({
    required this.transactionID,
    required this.clientTransactionID,
    this.userInfoString,
  });

  SquarePosPaymentResponse.fromMap(Map<dynamic, dynamic> response) {
    transactionID = response['transactionID'];
    clientTransactionID = response['clientTransactionID'];
    userInfoString = response['userInfoString'];
  }
}
