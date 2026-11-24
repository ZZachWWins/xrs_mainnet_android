package io.xeris.wallet

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class XerisBalanceWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)

            val balance = widgetData.getString("xrs_balance", "-- XRS") ?: "-- XRS"
            val usdValue = widgetData.getString("usd_value", "\$--") ?: "\$--"
            val updatedAt = widgetData.getString("updated_at", "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.xeris_widget_layout)
            views.setTextViewText(R.id.widget_balance, balance)
            views.setTextViewText(R.id.widget_usd_value, usdValue)
            views.setTextViewText(R.id.widget_updated_at, updatedAt)

            // Tap widget to open app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_balance, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
