package com.tixolve.smart_stocks_ts  // <-- change to your applicationId / package

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

data class AzanItem(
    val id: Int,
    val at: Long,
    val title: String,
    val body: String,
    val sound: String,
)

/** Schedules exact alarms and remembers them so they survive a reboot. */
object AzanAlarms {
    const val ACTION_FIRE = "app.azan.FIRE"
    private const val PREFS = "azan_schedule"
    private const val KEY = "items"

    fun canExact(ctx: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return am.canScheduleExactAlarms()
    }

    fun replaceAll(ctx: Context, items: List<AzanItem>) {
        cancelAll(ctx)
        save(ctx, items)
        items.forEach { arm(ctx, it) }
    }

    fun cancelAll(ctx: Context) {
        load(ctx).forEach { cancel(ctx, it.id) }
        save(ctx, emptyList())
    }

    /** After reboot / time change: drop past items and arm the rest again. */
    fun rearm(ctx: Context) {
        val now = System.currentTimeMillis()
        val future = load(ctx).filter { it.at > now }
        save(ctx, future)
        future.forEach { arm(ctx, it) }
    }

    fun markFired(ctx: Context, id: Int) {
        save(ctx, load(ctx).filter { it.id != id })
    }

    // ── internals ──

    private fun arm(ctx: Context, item: AzanItem) {
        if (item.at <= System.currentTimeMillis()) return
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(ctx, AzanReceiver::class.java).apply {
            action = ACTION_FIRE
            putExtra("id", item.id)
            putExtra("title", item.title)
            putExtra("body", item.body)
            putExtra("sound", item.sound)
        }
        val pi = PendingIntent.getBroadcast(
            ctx, item.id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        if (canExact(ctx)) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, item.at, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, item.at, pi)
        }
    }

    private fun cancel(ctx: Context, id: Int) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(ctx, AzanReceiver::class.java).apply { action = ACTION_FIRE }
        val pi = PendingIntent.getBroadcast(
            ctx, id, intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pi != null) {
            am.cancel(pi)
            pi.cancel()
        }
    }

    private fun save(ctx: Context, items: List<AzanItem>) {
        val arr = JSONArray()
        items.forEach {
            arr.put(JSONObject().apply {
                put("id", it.id); put("at", it.at); put("title", it.title)
                put("body", it.body); put("sound", it.sound)
            })
        }
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, arr.toString()).apply()
    }

    private fun load(ctx: Context): List<AzanItem> {
        val raw = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map {
                val o = arr.getJSONObject(it)
                AzanItem(o.getInt("id"), o.getLong("at"), o.getString("title"), o.getString("body"), o.getString("sound"))
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
