class SquarePosMoney {
  int amountCents;
  String currencyCode;

  SquarePosMoney({ required this.amountCents, required this.currencyCode });

  @override
  String toString() {
    return 'Amount: $amountCents, Currency: $currencyCode';
  }

  Map<String, dynamic> toMap() => {
    'amountCents': amountCents,
    'currencyCode': currencyCode,
  };
}
