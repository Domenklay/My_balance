package com.domenklay.mybalance.reminders;

import android.Manifest;
import android.app.Activity;
import android.app.NotificationManager;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.provider.Settings;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

public final class MyBalanceReminders extends GodotPlugin {
    public MyBalanceReminders(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "MyBalanceReminders"; }

    @UsedByGodot public boolean setSchedule(String json) {
        Activity activity = getActivity();
        return activity != null && ReminderReceiver.setSchedule(activity, json);
    }

    @UsedByGodot public boolean notificationsAllowed() {
        Activity activity = getActivity();
        if (activity == null) return false;
        if (Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false;
        NotificationManager manager = activity.getSystemService(NotificationManager.class);
        if (manager == null || !manager.areNotificationsEnabled()) return false;
        if (Build.VERSION.SDK_INT >= 26) {
            android.app.NotificationChannel channel = manager.getNotificationChannel(ReminderReceiver.CHANNEL);
            if (channel != null && channel.getImportance() == NotificationManager.IMPORTANCE_NONE) return false;
        }
        return true;
    }

    @UsedByGodot public void requestNotifications() {
        Activity activity = getActivity();
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            if (Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                && !activity.getPreferences(0).getBoolean("reminder_permission_requested", false)) {
                activity.getPreferences(0).edit().putBoolean("reminder_permission_requested", true).apply();
                activity.requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 761);
            } else {
                Intent intent = new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, activity.getPackageName());
                activity.startActivity(intent);
            }
        });
    }
}
