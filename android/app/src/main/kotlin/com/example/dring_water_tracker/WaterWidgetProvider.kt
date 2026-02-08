package com.example.drink_water_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WaterWidgetProvider : AppWidgetProvider() {
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

            val views = RemoteViews(context.packageName, R.layout.water_widget).apply {
                val formattedAmount = if (waterUnit == "oz") {
                    "%.1f oz".format(waterTotal / 29.5735)
                } else {
                    "$waterTotal ml"
                }
                
                val formattedGoal = if (waterUnit == "oz") {
                    "/ %.1f oz".format(waterGoal / 29.5735)
                } else {
                    "/ $waterGoal ml"
                }

                setTextViewText(R.id.water_amount, formattedAmount)
                setTextViewText(R.id.water_goal, formattedGoal)
                
                val progress = (waterTotal.toFloat() / waterGoal.toFloat() * 100).toInt()
                setProgressBar(R.id.water_progress, 100, progress, false)
                
                // Dodaj intent do otwarcia aplikacji
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
