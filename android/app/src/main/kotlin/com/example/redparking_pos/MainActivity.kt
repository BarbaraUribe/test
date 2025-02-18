package com.example.redparking_pos

import android.content.Intent
import io.flutter.embedding.android.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import android.content.pm.PackageManager
import android.app.Activity
import androidx.activity.result.ActivityResult
import androidx.activity.result.contract.ActivityResultContracts


class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "payment_channel"
    private var paymentResult: MethodChannel.Result? = null

    private val paymentLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result: ActivityResult -> 
        handlePaymentResult(result) 
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "processPayment" -> {
                    paymentResult = result
                    val paymentData = call.arguments as Map<String, Any>
                    launchPaymentApp(paymentData)
                }
                "checkPaymentApp" -> {
                    result.success(isPaymentAppInstalled())
                }
                "checkPaymentStatus" -> {
                    val transactionId = call.argument<String>("transactionId")
                    checkPaymentStatus(transactionId, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isPaymentAppInstalled(): Boolean {
        val packageName = "com.haulmer.paymentapp.dev" // Cambiar a producción cuando sea necesario
        return try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun launchPaymentApp(paymentData: Map<String, Any>) {
        try {
            val intent = Intent().apply {
                setPackage("com.haulmer.paymentapp.dev") // Cambiar a producción cuando sea necesario
                action = "android.intent.action.SEND"
                type = "text/json"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK

                val jsonData = JSONObject(paymentData)
                putExtra("android.intent.extra.TEXT", jsonData.toString())
            }

            if (packageManager.resolveActivity(intent, 0) != null) {
                paymentLauncher.launch(intent)
            } else {
                handlePaymentError("APP_NOT_FOUND", "La aplicación de pagos no está instalada")
            }
        } catch (e: Exception) {
            handlePaymentError("LAUNCH_ERROR", "Error al iniciar la app de pagos: ${e.message}")
        }
    }

    private fun handlePaymentResult(result: ActivityResult) {
        when (result.resultCode) {
            Activity.RESULT_OK -> {
                val response = result.data?.getStringExtra("paymentResponse") ?: "{}"
                paymentResult?.success(response)
            }
            Activity.RESULT_CANCELED -> {
                handlePaymentError("CANCELLED", "La transacción fue cancelada")
            }
            else -> {
                handlePaymentError("UNKNOWN", "Error en proceso de pago")
            }
        }
    }

    private fun handlePaymentError(code: String, message: String) {
        val error = JSONObject().apply {
            put("errorCode", code)
            put("errorMessage", message)
        }
        paymentResult?.success(error.toString())
    }

    private fun checkPaymentStatus(transactionId: String?, result: MethodChannel.Result) {
        if (transactionId == null) {
            result.error("INVALID_TRANSACTION", "ID de transacción inválido", null)
            return
        }

        result.success(JSONObject().apply {
            put("status", "COMPLETED")
            put("transactionId", transactionId)
        }.toString())
    }
}
