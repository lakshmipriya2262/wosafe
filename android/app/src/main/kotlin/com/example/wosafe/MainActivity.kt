package com.example.wosafe

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "wosafe/emergency_channel"
    private val SMS_PERMISSION_CODE = 2001
    private val CALL_PERMISSION_CODE = 2002
    private val AUDIO_PERMISSION_CODE = 2003

    private var methodChannel: MethodChannel? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var recognizerIntent: Intent? = null
    private var isListeningContinuous: Boolean = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendDirectSms" -> {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")

                    if (phone.isNullOrEmpty() || message.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENTS", "Phone or message is empty", null)
                        return@setMethodCallHandler
                    }

                    // Check runtime permission
                    if (ActivityCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS), SMS_PERMISSION_CODE)
                        result.error("PERMISSION_NOT_GRANTED", "SEND_SMS permission requested", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            applicationContext.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        val parts = smsManager.divideMessage(message)
                        if (parts.size > 1) {
                            smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                        } else {
                            smsManager.sendTextMessage(phone, null, message, null, null)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SMS_SEND_FAILED", e.localizedMessage, null)
                    }
                }

                "makeDirectCall" -> {
                    val phone = call.argument<String>("phone")
                    if (phone.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENTS", "Phone is empty", null)
                        return@setMethodCallHandler
                    }

                    val cleanPhone = phone.replace(Regex("[^0-9+]"), "")
                    try {
                        val hasCallPermission = ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED
                        val intent = if (hasCallPermission) {
                            Intent(Intent.ACTION_CALL, Uri.parse("tel:$cleanPhone"))
                        } else {
                            // Fallback to dialer if CALL_PHONE is not yet granted
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), CALL_PERMISSION_CODE)
                            Intent(Intent.ACTION_DIAL, Uri.parse("tel:$cleanPhone"))
                        }
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CALL_FAILED", e.localizedMessage, null)
                    }
                }

                "startSpeechRecognition" -> {
                    if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), AUDIO_PERMISSION_CODE)
                        result.error("PERMISSION_NOT_GRANTED", "RECORD_AUDIO permission required", null)
                        return@setMethodCallHandler
                    }

                    if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                        result.error("NOT_AVAILABLE", "Speech recognition service not available on this device", null)
                        return@setMethodCallHandler
                    }

                    mainHandler.post {
                        try {
                            isListeningContinuous = true
                            initSpeechRecognizer()
                            speechRecognizer?.startListening(recognizerIntent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SPEECH_INIT_FAILED", e.localizedMessage, null)
                        }
                    }
                }

                "stopSpeechRecognition" -> {
                    isListeningContinuous = false
                    mainHandler.post {
                        try {
                            speechRecognizer?.stopListening()
                            speechRecognizer?.destroy()
                            speechRecognizer = null
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SPEECH_STOP_FAILED", e.localizedMessage, null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun initSpeechRecognizer() {
        if (speechRecognizer != null) {
            try {
                speechRecognizer?.destroy()
            } catch (_: Exception) {}
        }

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "en-US")
            putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, false)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
        }

        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                mainHandler.post {
                    methodChannel?.invokeMethod("onSpeechStatus", mapOf("status" to "ready"))
                }
            }

            override fun onBeginningOfSpeech() {
                mainHandler.post {
                    methodChannel?.invokeMethod("onSpeechStatus", mapOf("status" to "speaking"))
                }
            }

            override fun onRmsChanged(rmsdB: Float) {
                mainHandler.post {
                    methodChannel?.invokeMethod("onSpeechRms", mapOf("rms" to rmsdB))
                }
            }

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                mainHandler.post {
                    methodChannel?.invokeMethod("onSpeechStatus", mapOf("status" to "processing"))
                }
            }

            override fun onError(error: Int) {
                mainHandler.post {
                    methodChannel?.invokeMethod("onSpeechError", mapOf("errorCode" to error))
                    if (isListeningContinuous && (error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT)) {
                        mainHandler.postDelayed({
                            if (isListeningContinuous) {
                                try {
                                    speechRecognizer?.startListening(recognizerIntent)
                                } catch (_: Exception) {}
                            }
                        }, 600)
                    }
                }
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val recognizedText = matches?.firstOrNull() ?: ""
                mainHandler.post {
                    methodChannel?.invokeMethod("onSpeechResult", mapOf(
                        "text" to recognizedText,
                        "matches" to (matches ?: arrayListOf<String>())
                    ))
                    if (isListeningContinuous) {
                        mainHandler.postDelayed({
                            if (isListeningContinuous) {
                                try {
                                    speechRecognizer?.startListening(recognizerIntent)
                                } catch (_: Exception) {}
                            }
                        }, 500)
                    }
                }
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val partialText = matches?.firstOrNull() ?: ""
                if (partialText.isNotEmpty()) {
                    mainHandler.post {
                        methodChannel?.invokeMethod("onSpeechPartial", mapOf("text" to partialText))
                    }
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
    }

    override fun onDestroy() {
        isListeningContinuous = false
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }
}
