import 'dart:async';

import 'package:flutter/services.dart';

import 'models/square_pos_money.dart';
import 'models/square_pos_plugin_response.dart';
import 'models/square_pos_payment_request.dart';
import 'models/square_pos_payment_response.dart';

export 'models/square_pos_money.dart';
export 'models/square_pos_plugin_response.dart';
export 'models/square_pos_payment_request.dart';
export 'models/square_pos_payment_response.dart';

class SquarePos {
  static const MethodChannel _channel = MethodChannel('square_pos');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static bool _isInitialized = false;
  static String? _scheme;

  static void _throwIfNotInitialized() {
    if (!_isInitialized || _scheme == null) {
      throw Exception(
          'Square POS SDK is not initialized. You should call SquarePos.init(applicationID, scheme)');
    }
  }

  /// Initializes Square POS SDK with your [affiliateKey] and [scheme].
  ///
  /// Must be called before anything else
  static Future<SquarePosPluginResponse> init(
      String applicationID, String scheme) async {
    _scheme = scheme;

    final method = await _channel.invokeMethod('init', applicationID);
    final response = SquarePosPluginResponse.fromMap(method);
    if (response.status) {
      _isInitialized = true;
    }
    return response;
  }

  /// Checks if the Square POS app is installed on the device and can make requests
  static Future<bool?> get canRequest async {
    _throwIfNotInitialized();
    final method = await _channel.invokeMethod('canRequest');
    print(method);
    return SquarePosPluginResponse.fromMap(method).status;
  }

  /// Starts a checkout process with [paymentRequest].
  static Future<SquarePosPaymentResponse> requestPayment(
      SquarePosPaymentRequest paymentRequest) async {
    _throwIfNotInitialized();
    final request = paymentRequest.toMap();
    final callback = '$_scheme://';
    request['callbackURL'] = callback;

    final method = await _channel.invokeMethod('requestPayment', request);
    final response = SquarePosPluginResponse.fromMap(method);

    if (!response.status) {
      throw response.message?['errors'] ??
          'There was an error processing payment with Square POS.';
    }

    return SquarePosPaymentResponse.fromMap(response.message!);
  }
}
