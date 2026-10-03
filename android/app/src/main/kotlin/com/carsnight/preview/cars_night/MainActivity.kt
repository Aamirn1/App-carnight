package com.carsnight.preview.cars_night

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "carsnight/platform")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "openEmail" -> {
                            val gmail = packageManager.getLaunchIntentForPackage("com.google.android.gm")
                            if (gmail != null) startActivity(gmail)
                            else startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://mail.google.com/")))
                            result.success(true)
                        }
                        "shareText" -> {
                            val text = call.arguments as? String ?: ""
                            val share = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, text)
                            }
                            startActivity(Intent.createChooser(share, "Share from Cars Night"))
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) { result.success(false) }
            }
    }
}
