package com.example.hydrozap_app

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set flags to wake screen for notifications
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        
        // Handle notification intent if app was started from notification
        if (intent.extras?.containsKey("google.message_id") == true) {
            handleNotificationIntent(intent)
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle notification intent if app was already running
        if (intent.extras?.containsKey("google.message_id") == true) {
            handleNotificationIntent(intent)
        }
    }
    
    private fun handleNotificationIntent(intent: Intent) {
        // This is where you can extract data from the notification intent
        // and route to the appropriate screen in your app if needed
        val messageId = intent.extras?.getString("google.message_id")
        println("Notification clicked with message ID: $messageId")
        
        // Log details about the notification for debugging
        intent.extras?.keySet()?.forEach { key ->
            android.util.Log.d("HydroZap", "Notification data: $key = ${intent.extras?.get(key)}")
        }
    }
}
