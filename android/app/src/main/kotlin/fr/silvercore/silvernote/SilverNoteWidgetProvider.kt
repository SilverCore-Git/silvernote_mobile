package fr.silvercore.silvernote

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent // Import crucial
import es.antonborri.home_widget.HomeWidgetProvider
import androidx.core.net.toUri

class SilverNoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // ON SUPPRIME LE SUPER (cause de l'erreur Abstract member)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {

                val uri = "https://app.silvernote.fr/edit/new".toUri()
                // On utilise HomeWidgetLaunchIntent directement, c'est le moteur du plugin
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    uri
                )

                setOnClickPendingIntent(R.id.widget_button, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}