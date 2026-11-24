package com.domenklay.mybalance.reminders;

import android.Manifest;
import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import org.json.JSONObject;
import java.util.Calendar;

public final class ReminderReceiver extends BroadcastReceiver {
    static final String CHANNEL = "mybalance_reminders";
    private static final String ACTION = "com.domenklay.mybalance.REMINDER";
    private static final String[] KEYS = {"water","breakfast","lunch","dinner","snack","weight","workout"};
    private static final String[] MESSAGES = {"Время сделать паузу и выпить воды, если хочется.","Напоминание о завтраке.","Напоминание об обеде.","Напоминание об ужине.","Напоминание о перекусе.","Напоминание о записи веса.","Напоминание о запланированной тренировке."};

    private static android.content.SharedPreferences prefs(Context ctx) {
        return ctx.getSharedPreferences("mybalance_reminders", Context.MODE_PRIVATE);
    }
    private static boolean valid(JSONObject obj) {
        if (obj.length() != KEYS.length) return false;
        for (String key : KEYS) {
            JSONObject entry = obj.optJSONObject(key);
            if (entry == null || !(entry.opt("enabled") instanceof Boolean) || !entry.optString("time","").matches("(?:[01][0-9]|2[0-3]):[0-5][0-9]")) return false;
            Object day = entry.opt("day");
            if (!(day instanceof Number)) return false;
            double d = ((Number)day).doubleValue();
            if (d < 0 || d > 7 || d != Math.floor(d)) return false;
        }
        return true;
    }
    static synchronized boolean setSchedule(Context ctx, String json) {
        try {
            JSONObject data = new JSONObject(json);
            if (!valid(data)) return false;
            if (!prefs(ctx).edit().putString("schedule",json).commit()) return false;
            reschedule(ctx, data);
            return true;
        } catch (Exception e) {
            android.util.Log.w("MyBalanceReminders","Schedule could not be installed",e);
            return false;
        }
    }
    private static PendingIntent alarm(Context ctx, int i) {
        Intent intent = new Intent(ctx, ReminderReceiver.class).setAction(ACTION).putExtra("index",i);
        return PendingIntent.getBroadcast(ctx, 7610+i, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }
    private static long nextTime(JSONObject item) {
        Calendar next = Calendar.getInstance();
        String time = item.optString("time");
        next.set(Calendar.HOUR_OF_DAY,Integer.parseInt(time.substring(0,2)));
        next.set(Calendar.MINUTE,Integer.parseInt(time.substring(3)));
        next.set(Calendar.SECOND,0);
        next.set(Calendar.MILLISECOND,0);
        int weekday = item.optInt("day",0);
        long now = System.currentTimeMillis();
        while (next.getTimeInMillis() <= now || (weekday != 0 && (next.get(Calendar.DAY_OF_WEEK)+5)%7+1 != weekday)) {
            next.add(Calendar.DAY_OF_YEAR,1);
            next.set(Calendar.HOUR_OF_DAY,Integer.parseInt(time.substring(0,2)));
            next.set(Calendar.MINUTE,Integer.parseInt(time.substring(3)));
        }
        return next.getTimeInMillis();
    }
    private static void scheduleOne(Context ctx, JSONObject data, int index) {
        AlarmManager manager = ctx.getSystemService(AlarmManager.class);
        if (manager == null) throw new IllegalStateException("Alarm service unavailable");
        PendingIntent pending = alarm(ctx,index);
        manager.cancel(pending);
        JSONObject item = data.optJSONObject(KEYS[index]);
        if (item.optBoolean("enabled")) {
            // Inexact alarms intentionally do not require special exact-alarm privileges.
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextTime(item), pending);
        }
    }
    private static void reschedule(Context ctx, JSONObject data) {
        for (int i=0;i<KEYS.length;i++) scheduleOne(ctx,data,i);
    }
    private static void notifyUser(Context ctx, int index) {
        if (Build.VERSION.SDK_INT >= 33 && ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return;
        NotificationManager manager = ctx.getSystemService(NotificationManager.class);
        if (manager == null || !manager.areNotificationsEnabled()) return;
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(new NotificationChannel(CHANNEL,"Напоминания",NotificationManager.IMPORTANCE_DEFAULT));
        Intent launch = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
        Notification.Builder builder = Build.VERSION.SDK_INT >= 26 ? new Notification.Builder(ctx,CHANNEL) : new Notification.Builder(ctx);
        builder.setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle("Мой баланс").setContentText(MESSAGES[index])
            .setAutoCancel(true).setVisibility(Notification.VISIBILITY_PRIVATE);
        if (launch != null) builder.setContentIntent(PendingIntent.getActivity(ctx,761,launch,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE));
        manager.notify(7610+index,builder.build());
    }
    @Override public void onReceive(Context ctx, Intent intent) {
        try {
            JSONObject data = new JSONObject(prefs(ctx).getString("schedule","{}"));
            if (!valid(data)) return;
            if (ACTION.equals(intent.getAction())) {
                int index = intent.getIntExtra("index",-1);
                if (index < 0 || index >= KEYS.length) return;
                JSONObject item = data.optJSONObject(KEYS[index]);
                if (!item.optBoolean("enabled")) return;
                scheduleOne(ctx,data,index);
                notifyUser(ctx,index);
            } else {
                reschedule(ctx,data);
            }
        } catch (Exception e) {
            android.util.Log.w("MyBalanceReminders","Reminder delivery failed",e);
        }
    }
}
