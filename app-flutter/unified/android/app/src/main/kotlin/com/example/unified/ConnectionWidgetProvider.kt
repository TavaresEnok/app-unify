package com.example.unified

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * Widget para exibir status da conexão na home screen
 */
class ConnectionWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Atualiza cada widget
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Primeiro widget adicionado
    }

    override fun onDisabled(context: Context) {
        // Último widget removido
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Cria views remotas para o widget
            val views = RemoteViews(context.packageName, R.layout.connection_widget)
            
            // TODO: Buscar dados reais do SharedPreferences ou API
            views.setTextViewText(R.id.widget_status, "Conexão Ativa")
            views.setTextViewText(R.id.widget_speed, "100 Mbps")
            views.setTextViewText(R.id.widget_updated, "Atualizado: Agora")
            
            // Atualiza o widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
