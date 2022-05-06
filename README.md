# square_pos

[![pub package](https://img.shields.io/pub/v/square_pos.svg)](https://pub.dev/packages/square_pos) [![likes](https://badges.bar/square_pos/likes)](https://pub.dev/packages/square_pos/score) [![popularity](https://badges.bar/square_pos/popularity)](https://pub.dev/packages/square_pos/score)  [![pub points](https://badges.bar/square_pos/pub%20points)](https://pub.dev/packages/square_pos/score)

A Flutter wrapper to use the Square POS SDK.

With this plugin, your app can easily request payment via the Square POD app on Android and iOS.

## Prerequisites

1) Registered for a Square developer account via [Square](https://squareup.com/signup?v=developers).
2) Deployment Target iOS 12.0 or higher.
3) Android minSdkVersion 21 or higher.

## Installing

Add square_pos to your pubspec.yaml:

```yaml
dependencies:
  square_pos:
```

Import square_pos:

```dart
import 'package:square_pos/square_pos.dart';
```

## Getting Started

Init SquarePos SDK:

```dart
SquarePos.init(applicationID, callbackScheme);
```

Check if Square POS is installed on device:

```dart
SquarePos.canRequest;
```

Complete a transaction:

```dart
var request = SquarePosPaymentRequest(
    money: SquarePosMoney(amountCents: 100, currencyCode: "USD"),
    supportedTenderTypes: [
        SquarePosTenderType.card,
        SquarePosTenderType.cardOnFile,
        SquarePosTenderType.squareGiftCard
    ]);
SquarePos.requestPayment(request);
```

## Available APIs

```dart
SquarePos.init(applicationID, callbackScheme);

SquarePos.canRequest;

SquarePos.requestPayment(request);
```