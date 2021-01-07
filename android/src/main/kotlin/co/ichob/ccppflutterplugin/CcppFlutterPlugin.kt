package co.ichob.ccppflutterplugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.ccpp.pgw.sdk.android.builder.CardPaymentBuilder
import com.ccpp.pgw.sdk.android.builder.CardTokenPaymentBuilder
import com.ccpp.pgw.sdk.android.builder.PGWSDKParamsBuilder
import com.ccpp.pgw.sdk.android.builder.TransactionResultRequestBuilder
import com.ccpp.pgw.sdk.android.callback.APIResponseCallback
import com.ccpp.pgw.sdk.android.core.PGWSDK
import com.ccpp.pgw.sdk.android.enums.APIEnvironment
import com.ccpp.pgw.sdk.android.enums.APIResponseCode
import com.ccpp.pgw.sdk.android.model.PaymentCode
import com.ccpp.pgw.sdk.android.model.api.TransactionResultRequest
import com.ccpp.pgw.sdk.android.model.api.TransactionResultResponse
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener

class CcppFlutterPlugin : MethodCallHandler, FlutterPlugin, ActivityAware, ActivityResultListener {
    private var activity: Activity? = null
    private var applicationContext: Context? = null
    private var result: MethodChannel.Result? = null
    private var methodChannel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(binding.applicationContext, binding.binaryMessenger)
    }

    private fun onAttachedToEngine(applicationContext: Context, messenger: BinaryMessenger) {
        this.applicationContext = applicationContext
        this.methodChannel = MethodChannel(messenger, CHANNEL_NAME)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addActivityResultListener(this)
        activity = binding.activity
        methodChannel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onDetachedFromActivity() {
        activity = null
        applicationContext = null
        methodChannel?.setMethodCallHandler(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        binding.addActivityResultListener(this)
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        this.result = result
        when (call.method) {
            "initialize" -> {
                val isSandbox = call.argument<Boolean>("isSandBox") ?: true
                val environment = if(isSandbox) APIEnvironment.Sandbox else APIEnvironment.Production

                val params = PGWSDKParamsBuilder(activity!!, environment).build()
                PGWSDK.initialize(params)
                result.success(null)
            }
            "paymentWithCreditCard" -> {
                val paymentToken = call.argument<String>("paymentToken") ?: ""
                val ccNumber = call.argument<String>("ccNumber") ?: ""
                val expMonth = call.argument<Int>("expMonth") ?: 0
                val expYear = call.argument<Int>("expYear") ?: 0
                val securityCode = call.argument<String>("securityCode") ?: ""
                val storeCard = call.argument<Boolean>("storeCard") ?: false
                paymentWithCreditCard(result, paymentToken, ccNumber, expMonth, expYear, securityCode, storeCard)
            }
            "paymentWithToken" -> {
                val paymentToken = call.argument<String>("paymentToken") ?: ""
                val cardToken = call.argument<String>("cardToken") ?: ""
                val securityCode = call.argument<String>("securityCode") ?: ""
                paymentWithToken(result, paymentToken,cardToken, securityCode)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun paymentWithCreditCard(result: MethodChannel.Result, paymentToken: String, ccNumber: String, expMonth: Int, expYear: Int, securityCode: String, storeCard: Boolean) {
        val paymentCode = PaymentCode("CC")

        //Construct credit card request
        val paymentRequest = CardPaymentBuilder(paymentCode, ccNumber)
                .setExpiryMonth(expMonth)
                .setExpiryYear(expYear)
                .setSecurityCode(securityCode)
                .setTokenize(storeCard)
                .build()

        //Construct transaction request
        val transactionRequest = TransactionResultRequestBuilder(paymentToken)
                .with(paymentRequest)
                .build()

        //Execute payment request
        proceedTransaction(result, transactionRequest)
    }

    private fun paymentWithToken(result: MethodChannel.Result, paymentToken: String, cardToken: String, securityCode: String) {
        val paymentCode = PaymentCode("CC")

        //Construct credit card request
        val paymentRequest = CardTokenPaymentBuilder(paymentCode, cardToken)
                .setSecurityCode(securityCode)
                .build()

        //Construct transaction request
        val transactionRequest = TransactionResultRequestBuilder(paymentToken)
                .with(paymentRequest)
                .build()

        proceedTransaction(result, transactionRequest)
    }

    private fun proceedTransaction(result: MethodChannel.Result, transactionResultRequest: TransactionResultRequest) {
        PGWSDK.getInstance().proceedTransaction(transactionResultRequest, object: APIResponseCallback<TransactionResultResponse> {
            override fun onResponse(transactionResultResponse: TransactionResultResponse) {
                when(transactionResultResponse.responseCode) {
                    APIResponseCode.TransactionAuthenticateRedirect, APIResponseCode.TransactionAuthenticateFullRedirect -> {
                        val redirectUrl = transactionResultResponse.data

                        //Open WebView for 3DS
                        val i = Intent(activity, WebViewActivity::class.java)
                        i.putExtra("redirect", redirectUrl)
                        activity?.startActivityForResult(i, CCPP_AUTH_REQUEST_CODE)
                    }
                    APIResponseCode.TransactionCompleted -> {
                        val invoiceNo = transactionResultResponse.invoiceNo
                        val response = mapOf<String, Any>("invoiceNo" to invoiceNo)
                        result.success(response)
                    }
                    else -> {
                        //Get error response and display error
                        val response = mapOf<String, Any>("errorMessage" to transactionResultResponse.responseDescription)
                        result.success(response)
                    }
                }
            }

            override fun onFailure(error: Throwable) {
                //Get error response and display error
                val response = mapOf<String, Any>("errorMessage" to (error.message ?: "Unknown error"))
                result.success(response)
            }
        })
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        if (requestCode == CCPP_AUTH_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                val invoiceNo = intent?.getStringExtra("invoiceNo")
                val errorMessage = intent?.getStringExtra("errorMessage")

                val response = mapOf<String, Any?>(
                        "invoiceNo" to invoiceNo,
                        "errorMessage" to errorMessage
                )
                result?.success(response)
                return true
            }
            return true
        }
        return false
    }

    companion object {
        const val CHANNEL_NAME = "co.ichob/ccpp"
        const val CCPP_AUTH_REQUEST_CODE = 5152
    }

}