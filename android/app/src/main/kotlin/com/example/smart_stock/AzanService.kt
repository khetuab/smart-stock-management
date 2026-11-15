package com.tixolve.smart_stocks_ts   // <-- change to your applicationId / package

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

/**
 * Plays the azan as the *notification sound* of a foreground notification.
 *
 *  • Opening the notification panel  → Android itself silences a playing
 *    notification sound (no code needed).
 *  • Pressing power / volume keys    → this service sees the screen-state /
 *    volume broadcast and removes the notification, which stops the sound.
 *  • "Stop" button / swipe-away      → stops too.
 *  • Safety timeout                  → stops after 4 minutes at most.
 */
class AzanService : Service() {

    companion object {
        const val ACTION_PLAY = "app.azan.PLAY"
        const val ACTION_STOP = "app.azan.STOP"
        private const val NOTIF_ID = 7001
        private const val MAX_MS = 4 * 60 * 1000L
        private const val VOLUME_ACTION = "android.media.VOLUME_CHANGED_ACTION"
    }

    private val handler = Handler(Looper.getMainLooper())
    private val stopper = Runnable { shutdown() }
    private var startedAt = 0L
    private var registered = false

    private val keyReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {
            val since = SystemClock.elapsedRealtime() - startedAt
            when (i.action) {
                // power / side key toggles the screen state
                Intent.ACTION_SCREEN_OFF, Intent.ACTION_SCREEN_ON -> if (since > 2500) shutdown()
                // volume rocker changes the alarm / ring volume
                VOLUME_ACTION -> if (since > 1200) shutdown()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            shutdown()
            return START_NOT_STICKY
        }

        val title = intent?.getStringExtra("title") ?: "Azan"
        val body = intent?.getStringExtra("body") ?: ""
        val sound = intent?.getStringExtra("sound") ?: ""

        startedAt = SystemClock.elapsedRealtime()
        val notification = buildNotification(title, body, sound)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIF_ID, notification)
        }

        if (!registered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(VOLUME_ACTION)
            }
            ContextCompat.registerReceiver(this, keyReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
            registered = true
        }

        handler.removeCallbacks(stopper)
        handler.postDelayed(stopper, MAX_MS)
        return START_NOT_STICKY
    }

    private fun buildNotification(title: String, body: String, sound: String): Notification {
        val channelId = ensureChannel(sound)

        val open = packageManager.getLaunchIntentForPackage(packageName)
        val contentPi = PendingIntent.getActivity(
            this, 0, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val stopPi = PendingIntent.getService(
            this, 1,
            Intent(this, AzanService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val b = NotificationCompat.Builder(this, channelId)
            // TIP: replace with a monochrome status-bar icon, e.g. R.drawable.ic_stat_azan
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(contentPi)
            .setDeleteIntent(stopPi)
            .addAction(0, "Stop", stopPi)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            b.setSound(soundUri(sound), android.media.AudioManager.STREAM_ALARM)
        }
        return b.build()
    }

    /** Channel sounds are immutable, so every azan voice gets its own channel. */
    private fun ensureChannel(sound: String): String {
        val id = "azan_${sound.ifEmpty { "default" }}_v1"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(id) == null) {
                val ch = NotificationChannel(id, "Azan · ${sound.ifEmpty { "default" }}", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "Call to prayer at prayer times"
                    setSound(
                        soundUri(sound),
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                    )
                    enableVibration(false)
                    setShowBadge(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                nm.createNotificationChannel(ch)
            }
        }
        return id
    }

    private fun soundUri(sound: String): Uri {
        val res = if (sound.isEmpty()) 0 else resources.getIdentifier(sound, "raw", packageName)
        return if (res != 0) Uri.parse("android.resource://$packageName/$res")
        else RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
    }

    private fun shutdown() {
        handler.removeCallbacks(stopper)
        if (registered) {
            try { unregisterReceiver(keyReceiver) } catch (_: Exception) {}
            registered = false
        }
        // Removing the notification is what stops the sound.
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        getSystemService(NotificationManager::class.java).cancel(NOTIF_ID)
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(stopper)
        if (registered) {
            try { unregisterReceiver(keyReceiver) } catch (_: Exception) {}
            registered = false
        }
        super.onDestroy()
    }
}
