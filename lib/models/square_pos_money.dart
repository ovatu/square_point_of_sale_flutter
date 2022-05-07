/// Money object to send to native platform
class SquarePosMoney {
  int amountCents;
  String currencyCode;

  SquarePosMoney({required this.amountCents, required this.currencyCode});

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
