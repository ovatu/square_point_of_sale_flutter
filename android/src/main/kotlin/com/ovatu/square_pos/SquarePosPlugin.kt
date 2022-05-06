package com.ovatu.square_pos

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat.startActivityForResult
import com.squareup.sdk.pos.ChargeRequest
import com.squareup.sdk.pos.CurrencyCode
import com.squareup.sdk.pos.PosClient
import com.squareup.sdk.pos.PosSdk
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.TimeUnit


/** SquarePosPlugin */
class SquarePosPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  private val tag = "_SquarePosPlugin"

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var activity: Activity

  private var operations: MutableMap<String, SquarePosPluginResponseWrapper> = mutableMapOf()
  private lateinit var currentOperation: SquarePosPluginResponseWrapper

  private var posClient: PosClient? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(tag, "onAttachedToEngine")
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "square_pos")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(tag, "onDetachedFromEngine")
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    Log.d(tag, "onAttachedToActivity")
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Log.d(tag, "onDetachedFromActivityForConfigChanges")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    Log.d(tag, "onReattachedToActivityForConfigChanges")
  }

  override fun onDetachedFromActivity() {
    Log.d(tag, "onDetachedFromActivity")
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    Log.d(tag, "onMethodCall: ${call.method}")
    if (!operations.containsKey(call.method)) {
      operations[call.method] = SquarePosPluginResponseWrapper(result)
    }

    val pluginResponseWrapper = operations[call.method]!!
    pluginResponseWrapper.methodResult = result
    pluginResponseWrapper.response = SquarePosPluginResponse(call.method)

    currentOperation = pluginResponseWrapper

    when (call.method) {
      "init" -> init(call.arguments as String).flutterResult()
      "canRequest" -> canRequest().flutterResult()
      "requestPayment" -> requestPayment(call.arguments as Map<*, *>)
      else -> result.notImplemented()
    }
  }

  private fun init(@NonNull applicationID: String): SquarePosPluginResponseWrapper {
    val currentOp = operations["init"]!!
    try {
      posClient = PosSdk.createClient(activity, applicationID)

      currentOp.response.message = mutableMapOf("initialized" to true)
      currentOp.response.status = true
    } catch (e: Exception) {
      currentOp.response.message = mutableMapOf("initialized" to false, "errors" to e.message)
      currentOp.response.status = false
    }
    return currentOp
  }

  private fun canRequest(): SquarePosPluginResponseWrapper {
    val currentOp = operations["canRequest"]!!
    try {
      Log.d(tag, "canRequest:")

      var result = posClient!!.isPointOfSaleInstalled
      Log.d(tag, "canRequest: result $result")

      currentOp.response.status = result
      currentOp.response.message = mutableMapOf("canRequest" to true)
    } catch (e: Exception) {
      Log.d(tag, "canRequest: error $e")

      currentOp.response.message = mutableMapOf("errors" to e.message)
      currentOp.response.status = false
    }
    return currentOp
  }

  private fun requestPayment(@NonNull args: Map<*, *>) {
    Log.d(tag, "requestPayment: $args")

    val money = args["money"] as Map<*, *>

    val request = ChargeRequest.Builder(money["amountCents"] as Int, CurrencyCode.valueOf(money["currencyCode"] as String))
    request.requestMetadata(args["userInfoString"] as String?)
    request.enforceBusinessLocation(args["locationID"] as String?)
    request.note(args["notes"] as String?)
    request.customerId(args["customerID"] as String?)
    request.restrictTendersTo(_tenderTypesFromArray(args["supportedTenderTypes"] as Collection<String>))

    if (args["returnsAutomaticallyAfterPayment"] as Boolean) {
      request.autoReturn(4, TimeUnit.SECONDS)
    }

    try {
      val intent = posClient!!.createChargeIntent(request.build())
      startActivityForResult(activity, intent, SquarePosTask.REQUEST_PAYMENT.code, null)
    } catch (e: ActivityNotFoundException) {
      posClient!!.openPointOfSalePlayStoreListing()
    }
  }

  fun _tenderTypesFromArray(types: Collection<String>): Collection<ChargeRequest.TenderType> {
    var returnTypes = mutableListOf<ChargeRequest.TenderType>()

    for (name in types) {
      var type = _tenderTypeFromString(name)
      if (type != null) {
        returnTypes.add(type)
      }
    }

    return returnTypes;
  }

  fun _tenderTypeFromString(name: String): ChargeRequest.TenderType? {
    when (name) {
      "CREDIT_CARD" -> return ChargeRequest.TenderType.CARD
      "CASH" -> return ChargeRequest.TenderType.CASH
      "OTHER" -> return ChargeRequest.TenderType.OTHER
      "SQUARE_GIFT_CARD" -> return null
      "CARD_ON_FILE" -> return ChargeRequest.TenderType.CARD_ON_FILE
    }

    return null;
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    Log.d(tag, "onActivityResult - RequestCode: $requestCode - Result Code: $resultCode")

    val currentOp: SquarePosPluginResponseWrapper = when (SquarePosTask.valueOf(requestCode)) {
      SquarePosTask.REQUEST_PAYMENT -> operations["requestPayment"]!!
      else -> currentOperation
    }

    if (data != null && data.extras != null) {
      val result = resultCode == Activity.RESULT_OK

      currentOp.response.status = result

      when (SquarePosTask.valueOf(requestCode)) {
        SquarePosTask.REQUEST_PAYMENT -> {
          if (result) {
            val success = posClient!!.parseChargeSuccess(data)
            Log.d(tag, "clientTransactionId: ${success.clientTransactionId}")
            Log.d(tag, "serverTransactionId: ${success.serverTransactionId}")
            Log.d(tag, "requestMetadata: ${success.requestMetadata}")

            currentOp.response.message = mutableMapOf(
                    "clientTransactionID" to success.clientTransactionId,
                    "transactionID" to success.serverTransactionId,
                    "userInfoString" to success.requestMetadata,
            )

          } else {
            val error = posClient!!.parseChargeError(data)

            currentOp.response.message = mutableMapOf(
                    "errors" to error.debugDescription,
            )
          }

          currentOp.flutterResult()
        }
        else -> {
          currentOp.response.message = mutableMapOf("errors" to "Intent Data and/or Extras are null or empty")
          currentOp.response.status = false
          currentOp.flutterResult()
        }
      }
    } else {
      currentOp.response.message = mutableMapOf("errors" to "Intent Data and/or Extras are null or empty")
      currentOp.response.status = false
      currentOp.flutterResult()
    }
    return currentOp.response.status
  }
}

enum class SquarePosTask(val code: Int) {
  REQUEST_PAYMENT(1);

  companion object {
    fun valueOf(value: Int) = values().find { it.code == value }
  }
}

class SquarePosPluginResponseWrapper(@NonNull var methodResult: Result) {
  lateinit var response: SquarePosPluginResponse
  fun flutterResult() {
    methodResult.success(response.toMap())
  }
}

class SquarePosPluginResponse(@NonNull var methodName: String) {
  var status: Boolean = false
  lateinit var message: MutableMap<String, Any?>
  fun toMap(): Map<String, Any?> {
    return mapOf("status" to status, "message" to message, "methodName" to methodName)
  }
}
