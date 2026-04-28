package com.example.drink_water_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.math.min

class WaterWidgetSmallProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val waterTotal = widgetData.getInt("water_total", 0)
            val waterGoal = widgetData.getInt("water_goal", 2000)
            val waterUnit = widgetData.getString("water_unit", "ml")
            val themeMode = widgetData.getString("theme_mode", "system")

            val safeGoal = if (waterGoal <= 0) 1 else waterGoal
            val progressPercent = min(((waterTotal.toFloat() / safeGoal.toFloat()) * 100f).toInt(), 999)
            val ringLevel = min(progressPercent, 100) * 100
            val isDark = themeMode == "dark" || themeMode == "oled"

            val backgroundRes = if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light
            val progressColor = if (isDark) Color.parseColor("#5AA7FF") else Color.parseColor("#1A86FF")
            val trackColor = if (isDark) Color.parseColor("#2D3B4A") else Color.parseColor("#D7E5F5")
            val primaryTextColor = if (isDark) Color.parseColor("#EAF3FF") else Color.parseColor("#12324E")
            val secondaryTextColor = if (isDark) Color.parseColor("#9FB1C5") else Color.parseColor("#4E6A86")

            val views = RemoteViews(context.packageName, R.layout.water_widget_small).apply {
                val formattedAmount = if (waterUnit == "oz") {
                    "%.1f".format(waterTotal / 29.5735) + " oz"
                } else {
                    "$waterTotal ml"
                }

                setTextViewText(R.id.progress_percent_small, "$progressPercent%")
                setTextViewText(R.id.water_amount_small, formattedAmount)

                setInt(R.id.widget_small_container, "setBackgroundResource", backgroundRes)
                setInt(R.id.ring_progress_small, "setImageLevel", ringLevel)
                setInt(R.id.ring_progress_small, "setColorFilter", progressColor)
                setInt(R.id.ring_track_small, "setColorFilter", trackColor)
                setTextColor(R.id.progress_percent_small, primaryTextColor)
                setTextColor(R.id.water_amount_small, secondaryTextColor)

                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_small_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
