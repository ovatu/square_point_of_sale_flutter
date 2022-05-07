/// Money object to send to native platform
class SquarePosMoney {
  /// Amount in cents to charge (100 = 1.00)
  int amountCents;

  /// Currency code to charge in
  String currencyCode;

  SquarePosMoney({required this.amountCents, required this.currencyCode});

  /// Render a string repesentation of the response
  @override
  String toString() {
    return 'Amount: $amountCents, Currency: $currencyCode';
  }

  /// Map to send to native platform
  Map<String, dynamic> toMap() => {
        'amountCents': amountCents,
        'currencyCode': currencyCode,
      };
}
