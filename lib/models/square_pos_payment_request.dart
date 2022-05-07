import 'package:square_pos/models/square_pos_money.dart';

enum SquarePosTenderType { card, cash, other, squareGiftCard, cardOnFile }

extension SquarePosTenderTypeValue on SquarePosTenderType {
  String get mapValue {
    switch (this) {
      case SquarePosTenderType.card:
        return "CREDIT_CARD";
      case SquarePosTenderType.cash:
        return "CASH";
      case SquarePosTenderType.other:
        return "OTHER";
      case SquarePosTenderType.squareGiftCard:
        return "SQUARE_GIFT_CARD";
      case SquarePosTenderType.cardOnFile:
        return "CARD_ON_FILE";
    }
  }
}

/// Payment request send to native platform
class SquarePosPaymentRequest {
  SquarePosMoney money;
  String? userInfoString;
  String? locationID;
  String? notes;
  String? customerID;
  List<SquarePosTenderType>? supportedTenderTypes;
  bool returnsAutomaticallyAfterPayment;

  SquarePosPaymentRequest({
    required this.money,
    this.userInfoString,
    this.locationID,
    this.notes,
    this.customerID,
    this.supportedTenderTypes = SquarePosTenderType.values,
    this.returnsAutomaticallyAfterPayment = true,
  });

  @override
  String toString() {
    return 'Money: $money, UserInfoString: $userInfoString, LocationID: $locationID, Notes: $notes, CustomerID: $customerID, SupportedTenderTypes: $supportedTenderTypes, ReturnsAutomaticallyAfterPayment: $returnsAutomaticallyAfterPayment';
  }

  /// Map to send to native platform
  Map<String, dynamic> toMap() => {
        'money': money.toMap(),
        'userInfoString': userInfoString,
        'locationID': locationID,
        'notes': notes,
        'customerID': customerID,
        'supportedTenderTypes':
            supportedTenderTypes?.map((e) => e.mapValue).toList(),
        'returnsAutomaticallyAfterPayment': returnsAutomaticallyAfterPayment
      };
}
