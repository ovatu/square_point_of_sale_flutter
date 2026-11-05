import Flutter
import UIKit
import SquarePointOfSaleSDK

public class SwiftSquarePosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "square_pos", binaryMessenger: registrar.messenger())
        let instance = SwiftSquarePosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func application(
        _: UIApplication,
        open url: URL,
        options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return PendingPaymentRegistry.complete(with: url)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            guard let applicationID = call.arguments as? String else {
                result(Self.reply(call.method, status: false, message: ["errors": "applicationID is required"]))
                return
            }
            SCCAPIRequest.setApplicationID(applicationID)
            result(Self.reply(call.method, status: true))
        case "canRequest":
            let canOpen = UIApplication.shared.canOpenURL(URL(string: "square-commerce-v1://test")!)
            result(Self.reply(call.method, status: canOpen))
        case "requestPayment":
            guard let payment = call.arguments as? [String: Any] else {
                result(Self.reply(call.method, status: false, message: [
                    "status": false,
                    "errors": "Invalid payment request",
                ]))
                return
            }
            requestPayment(payment, result: result)
        default:
            result(Self.reply(call.method, status: false, message: ["result": "Method not implemented"]))
        }
    }

    private func requestPayment(_ payment: [String: Any], result: @escaping FlutterResult) {
        let callerUserInfo = payment["userInfoString"] as? String
        let token = PendingPaymentRegistry.begin(result: result, userInfoString: callerUserInfo)

        do {
            guard
                let moneyDict = payment["money"] as? [String: Any],
                let amountCents = moneyDict["amountCents"] as? Int,
                let currencyCode = moneyDict["currencyCode"] as? String,
                let callbackString = payment["callbackURL"] as? String,
                let callbackURL = URL(string: callbackString)
            else {
                PendingPaymentRegistry.fail(token: token, message: "Invalid payment request")
                return
            }

            let money = try SCCMoney(amountCents: amountCents, currencyCode: currencyCode)
            let tenderTypes = Self.tenderTypes(from: payment["supportedTenderTypes"] as? [String] ?? [])

            let apiRequest = try SCCAPIRequest(
                callbackURL: callbackURL,
                amount: money,
                // Square echoes this back as the response `state`, on both
                // success and error, which is how the response finds its way
                // back to this request.
                userInfoString: PendingPaymentRegistry.encodeState(
                    token: token,
                    userInfoString: callerUserInfo
                ),
                locationID: payment["locationID"] as? String,
                notes: payment["notes"] as? String,
                customerID: payment["customerID"] as? String,
                supportedTenderTypes: tenderTypes,
                clearsDefaultFees: true,
                returnsAutomaticallyAfterPayment: (payment["returnsAutomaticallyAfterPayment"] as? Bool) ?? false,
                disablesKeyedInCardEntry: false,
                skipsReceipt: false
            )

            try SCCAPIConnection.perform(apiRequest)
        } catch let error as NSError {
            PendingPaymentRegistry.fail(token: token, message: error.localizedDescription)
        }
    }

    fileprivate static func reply(
        _ methodName: String,
        status: Bool,
        message: [String: Any?]? = nil
    ) -> [String: Any?] {
        return [
            "status": status,
            "message": message,
            "methodName": methodName,
        ]
    }

    private static func tenderTypes(from types: [String]) -> SCCAPIRequestTenderTypes {
        var result: SCCAPIRequestTenderTypes = []
        for type in types {
            switch type {
            case "CREDIT_CARD": result.insert(.card)
            case "CASH": result.insert(.cash)
            case "OTHER": result.insert(.other)
            case "SQUARE_GIFT_CARD": result.insert(.squareGiftCard)
            case "CARD_ON_FILE": result.insert(.cardOnFile)
            default: break
            }
        }
        return result
    }
}

/// Tracks Square payment requests across the whole process.
///
/// An app can run several Flutter engines at once (one per iPad window), and
/// each engine registers its own instance of this plugin. iOS hands Square's
/// callback URL to the app, and Flutter offers it to the plugin instances in
/// registration order, so the instance that receives the response is often not
/// the one whose window started the payment. Keeping pending requests here and
/// matching responses by the token carried in Square's `state` field lets
/// whichever instance receives the URL complete the right request.
///
/// All access happens on the main thread (method calls and URL opens).
private enum PendingPaymentRegistry {
    private struct Entry {
        let result: FlutterResult
        let userInfoString: String?
    }

    private static let statePrefix = "sqpos1:"
    private static var entries: [String: Entry] = [:]

    /// Registers a new request and returns its token.
    ///
    /// The Square app runs one payment at a time, so starting a new request
    /// means any earlier one can no longer complete. Those are failed now
    /// rather than left waiting forever.
    static func begin(result: @escaping FlutterResult, userInfoString: String?) -> String {
        let superseded = entries
        entries.removeAll()
        for (_, entry) in superseded {
            entry.result(failure(
                "A newer Square payment request was started before this one returned.",
                userInfoString: entry.userInfoString
            ))
        }

        let token = UUID().uuidString
        entries[token] = Entry(result: result, userInfoString: userInfoString)
        return token
    }

    static func fail(token: String, message: String) {
        guard let entry = entries.removeValue(forKey: token) else { return }
        entry.result(failure(message, userInfoString: entry.userInfoString))
    }

    /// Completes the request a Square callback URL belongs to.
    ///
    /// Returns `true` for every Square response, matched or not: no other
    /// plugin instance could match it either, since they share this registry.
    static func complete(with url: URL) -> Bool {
        guard SCCAPIResponse.isSquareResponse(url) else {
            return false
        }

        let response: SCCAPIResponse
        do {
            response = try SCCAPIResponse(responseURL: url)
        } catch let error as NSError {
            // An unreadable response carries no token. Only one request can be
            // in flight, so it can only belong to that one.
            if entries.count == 1, let token = entries.keys.first {
                fail(token: token, message: error.localizedDescription)
            } else {
                NSLog("square_pos: unreadable Square response with %d pending requests", entries.count)
            }
            return true
        }

        guard
            let token = decodeToken(response.userInfoString),
            let entry = entries.removeValue(forKey: token)
        else {
            NSLog("square_pos: Square response did not match a pending request")
            return true
        }

        if let error = response.error {
            entry.result(failure(error.localizedDescription, userInfoString: entry.userInfoString))
        } else {
            entry.result(SwiftSquarePosPlugin.reply("requestPayment", status: true, message: [
                "status": true,
                "clientTransactionID": response.clientTransactionID,
                "transactionID": response.transactionID,
                "userInfoString": entry.userInfoString,
            ]))
        }
        return true
    }

    /// Builds the `state` sent to Square: the token, then the caller's own
    /// userInfoString (if any) after a `|`.
    static func encodeState(token: String, userInfoString: String?) -> String {
        guard let userInfoString else {
            return statePrefix + token
        }
        return statePrefix + token + "|" + userInfoString
    }

    private static func decodeToken(_ state: String?) -> String? {
        guard let state, state.hasPrefix(statePrefix) else {
            return nil
        }
        let body = state.dropFirst(statePrefix.count)
        return body.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init)
    }

    private static func failure(_ message: String, userInfoString: String?) -> [String: Any?] {
        return SwiftSquarePosPlugin.reply("requestPayment", status: false, message: [
            "status": false,
            "errors": message,
            "userInfoString": userInfoString,
        ])
    }
}
