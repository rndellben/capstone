package com.example.hydrozap_app

import io.flutter.app.FlutterApplication
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.media.AudioAttributes
import android.provider.Settings

class Application : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        
        // Create notification channels for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "high_importance_channel"
            val channelName = "High Importance Notifications"
            val channelDescription = "This channel is used for important notifications."
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                vibrationPattern = longArrayOf(100, 200, 300, 400, 500)
                lightColor = 0xFF4CAF50.toInt() // Green color
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                setSound(Settings.System.DEFAULT_NOTIFICATION_URI, audioAttributes)
                // Explicitly set this to true to ensure heads-up notifications
                setBypassDnd(true)
            }
            
            // Register the channel with the system
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            
            // Log that the channel was created
            android.util.Log.d("HydroZap", "Created notification channel: $channelId")
        }
    }
} 