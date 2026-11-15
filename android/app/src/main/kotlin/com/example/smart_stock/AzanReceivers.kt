package com.tixolve.smart_stocks_ts   // <-- change to your applicationId / package

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/** Fired by AlarmManager at prayer time → starts the azan service. */
class AzanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AzanAlarms.markFired(context, intent.getIntExtra("id", 0))
        val svc = Intent(context, AzanService::class.java).apply {
            action = AzanService.ACTION_PLAY
            putExtras(intent)
        }
        ContextCompat.startForegroundService(context, svc)
    }
}

/** Re-arms alarms after reboot, app update, or a clock / timezone change. */
class AzanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AzanAlarms.rearm(context)
    }
}
