package com.twlvstix.findmyfourth

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            fun channel(id: String, name: String, importance: Int, desc: String) =
                NotificationChannel(id, name, importance).apply { description = desc }
                    .also { nm.createNotificationChannel(it) }

            channel("critical",  "Account Alerts",  NotificationManager.IMPORTANCE_HIGH,    "Account standing notifications")
            channel("important", "Game Updates",    NotificationManager.IMPORTANCE_HIGH,    "Game-related notifications")
            channel("default",   "Round Activity",  NotificationManager.IMPORTANCE_DEFAULT, "Post-round check-ins and activity")
            channel("updates",   "Progress",        NotificationManager.IMPORTANCE_LOW,     "Badge progress and updates")
        }
    }
}
