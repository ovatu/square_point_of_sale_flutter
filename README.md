# Square POS SDK for Flutter

[![pub package](https://img.shields.io/pub/v/square_pos.svg)](https://pub.dev/packages/square_pos) [![likes](https://badges.bar/square_pos/likes)](https://pub.dev/packages/square_pos/score) [![popularity](https://badges.bar/square_pos/popularity)](https://pub.dev/packages/square_pos/score)  [![pub points](https://badges.bar/square_pos/pub%20points)](https://pub.dev/packages/square_pos/score)

A Flutter wrapper to use the Square POS SDK.

With this plugin, your app can easily request payment via the Square POS app on Android and iOS.

## Prerequisites

1) Registered for a Square developer account via [Square](https://squareup.com/signup?v=developers).
2) Deployment Target iOS 12.0 or higher.
3) Android minSdkVersion 21 or higher.

## Add URL schemes (iOS)

1) Add the request URL scheme as a LSApplicationQueriesSchemes key into your Info.plist file to indicate that your application uses the square-commerce-v1 URL scheme to open Square Point of Sale.

```
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>square-commerce-v1</string>
</array>
```

2) Add your custom response URL scheme as CFBundleURLTypes keys in your Info.plist file.

```
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>YOUR_BUNDLE_URL_NAME</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp-url-scheme</string>
    </array>
  </dict>
</array>
```

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