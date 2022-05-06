import Flutter
import UIKit
import SquarePointOfSaleSDK

public class SwiftSquarePosPlugin: NSObject, FlutterPlugin {
    private var operations: [String: SquarePosPluginResponseWrapper] = [:]
    private var currentOperation: SquarePosPluginResponseWrapper?

    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "square_pos", binaryMessenger: registrar.messenger())
    let instance = SwiftSquarePosPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)
      registrar.addApplicationDelegate(instance)
  }

    public func application(_: UIApplication, open: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        guard SCCAPIResponse.isSquareResponse(open) else {
            return false
        }

        let currentOp = operations["requestPayment"]!

        do {
            let response = try SCCAPIResponse(responseURL: open)

            if let error = response.error {
                // Handle a failed request.
                currentOp.response.status = false
                currentOp.response.message = ["errors": error.localizedDescription]
            } else {
                // Handle a successful request.
                currentOp.response.status = true
                currentOp.response.message = [
                    "clientTransactionID": response.clientTransactionID,
                    "transactionID": response.transactionID,
                    "userInfoString": response.userInfoString
                ]
            }

            currentOp.flutterResult()

        } catch let error as NSError {
            // Handle unexpected errors.
            currentOp.response.status = false
            currentOp.response.message = ["errors": error.localizedDescription]
            currentOp.flutterResult()
        }
        
        return true
    }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if (operations[call.method] == nil) {
          operations[call.method] = SquarePosPluginResponseWrapper(result: result)
      }

      let sumUpPluginResponseWrapper = operations[call.method]!
      sumUpPluginResponseWrapper.result = result
      sumUpPluginResponseWrapper.response = SquarePosPluginResponse(methodName: call.method)

      currentOperation = sumUpPluginResponseWrapper

      switch (call.method) {
        case "init": _init(call.arguments as! String).flutterResult()
        case "canRequest": _canRequest().flutterResult()
        case "requestPayment": _requestPayment(call.arguments as! [String:Any])
        default:
          sumUpPluginResponseWrapper.response.status = false
          sumUpPluginResponseWrapper.response.message = ["result": "Method not implemented"]
          sumUpPluginResponseWrapper.flutterResult()
      }
    }
    
    func _init(_ applicationID: String) -> SquarePosPluginResponseWrapper {
        let currentOp = operations["init"]!

        SCCAPIRequest.setApplicationID(applicationID)

        currentOp.response.status = true
        
        return currentOp
    }

    func _canRequest() -> SquarePosPluginResponseWrapper {
        let currentOp = operations["canRequest"]!

        currentOp.response.status = UIApplication.shared.canOpenURL(URL(string: "square-commerce-v1://test")!)

        return currentOp
    }

    func _requestPayment(_ payment: [String:Any]) {
        let currentOp = operations["requestPayment"]!

        do {
            let moneyDict = payment["money"] as! [String:Any]
            
            // Specify the amount of money to charge.
            let money = try SCCMoney(amountCents: moneyDict["amountCents"] as! Int, currencyCode: moneyDict["currencyCode"] as! String)

            // Create the request.
            let apiRequest =
                try SCCAPIRequest(
                    callbackURL: URL(string: payment["callbackURL"] as! String)!,
                    amount: money,
                    userInfoString: payment["userInfoString"] as? String,
                    locationID: payment["locationID"] as? String,
                    notes: payment["notes"] as? String,
                    customerID: payment["customerID"] as? String,
                    supportedTenderTypes: _requestTenderTypesFromStrings(payment["supportedTenderTypes"] as! Array<String>),
                    clearsDefaultFees: true,
                    returnsAutomaticallyAfterPayment: (payment["returnsAutomaticallyAfterPayment"] as? Bool) ?? false,
                    disablesKeyedInCardEntry: false,
                    skipsReceipt: false
            )

            // Open Point of Sale to complete the payment.
            try SCCAPIConnection.perform(apiRequest)
        } catch let error as NSError {
            currentOp.response.status = false
            currentOp.response.message = ["errors": error.localizedDescription]
            currentOp.flutterResult()
        }
    }
    
    func _requestTenderTypeFromString(_ type: String) -> SCCAPIRequestTenderTypes? {
        switch (type) {
            case "CREDIT_CARD":
                return SCCAPIRequestTenderTypes.card
            case "CASH":
                return SCCAPIRequestTenderTypes.cash
            case "OTHER":
                return SCCAPIRequestTenderTypes.other
            case "SQUARE_GIFT_CARD":
                return SCCAPIRequestTenderTypes.squareGiftCard
            case "CARD_ON_FILE":
                return SCCAPIRequestTenderTypes.cardOnFile
            default:
                break
        }
        
        return nil
    }
    
    func _requestTenderTypesFromStrings(_ types: Array<String>) -> SCCAPIRequestTenderTypes {
        var returnTypes: SCCAPIRequestTenderTypes = []
        
        for type in types {
            let resolvedType = _requestTenderTypeFromString(type)
            
            if (resolvedType != nil) {
                returnTypes.insert(resolvedType!)
            }
        }
                
        return returnTypes
    }
}

public class SquarePosPluginResponseWrapper: NSObject {
    var response: SquarePosPluginResponse!
    var result: FlutterResult!

    init(result: @escaping FlutterResult) {
        self.result = result
    }

    
    func flutterResult() {
        result(response.toDict())
    }
}

public class SquarePosPluginResponse: NSObject {
    var methodName: String
    var status: Bool = false
    var message: [String:Any?]?

    init(methodName: String) {
        self.methodName = methodName
    }


    func toDict() -> [String:Any?] {
        return [
            "status": status,
            "message": message,
            "methodName": methodName
        ]
    }
}
