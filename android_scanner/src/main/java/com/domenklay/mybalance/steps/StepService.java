package com.domenklay.mybalance.steps;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.PackageManager;
import android.content.pm.ServiceInfo;
import android.hardware.*;
import android.os.*;
import androidx.core.app.NotificationCompat;

public final class StepService extends Service implements SensorEventListener {
    static final String CHANNEL="mybalance_steps";
    static final String STOP="com.domenklay.mybalance.STOP_STEPS";
    static volatile boolean running=false;
    private SensorManager manager;
    private long lastTimestamp=0;
    private long lastWidgetUpdate=0;
    static boolean permission(Context c) {
        return Build.VERSION.SDK_INT<29 || c.checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION)==PackageManager.PERMISSION_GRANTED;
    }
    static boolean supported(Context c) {
        SensorManager m=(SensorManager)c.getSystemService(Context.SENSOR_SERVICE);
        return m!=null && m.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)!=null;
    }
    @Override public IBinder onBind(Intent i) { return null; }
    @Override public int onStartCommand(Intent intent,int flags,int id) {
        if(intent!=null && STOP.equals(intent.getAction())) {
            stopSelf(); return START_NOT_STICKY;
        }
        if(!permission(this)||!supported(this)) { stopSelf(); return START_NOT_STICKY; }
        if(running) return START_NOT_STICKY;
        try {
            NotificationManager nm=getSystemService(NotificationManager.class);
            if(Build.VERSION.SDK_INT>=26) nm.createNotificationChannel(new NotificationChannel(CHANNEL,"Шагомер",NotificationManager.IMPORTANCE_LOW));
            Intent launch=getPackageManager().getLaunchIntentForPackage(getPackageName());
            PendingIntent open=launch==null?null:PendingIntent.getActivity(this,190,launch,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
            Intent stopIntent=new Intent(this,StepService.class).setAction(STOP);
            PendingIntent stop=PendingIntent.getService(this,191,stopIntent,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
            Notification notice=new NotificationCompat.Builder(this,CHANNEL)
                .setSmallIcon(android.R.drawable.ic_menu_directions).setContentTitle("Мой баланс — шагомер")
                .setContentText("Автоматический учёт шагов включён").setOngoing(true).setOnlyAlertOnce(true)
                .setContentIntent(open).addAction(android.R.drawable.ic_menu_close_clear_cancel,"Остановить",stop).build();
            if(Build.VERSION.SDK_INT>=34) startForeground(194,notice,ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH);
            else startForeground(194,notice);
            manager=(SensorManager)getSystemService(SENSOR_SERVICE);
            // Never attribute steps before consent, after a stop, or across process restarts.
            StepLedger.resetBaseline(this);
            running=manager.registerListener(this,manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER),SensorManager.SENSOR_DELAY_NORMAL);
            if(!running) stopSelf();
        } catch(Exception e) { running=false; stopSelf(); }
        return START_NOT_STICKY;
    }
    @Override public void onSensorChanged(SensorEvent event) {
        if(!running || event.sensor.getType()!=Sensor.TYPE_STEP_COUNTER || event.values.length<1) return;
        if(event.timestamp<=lastTimestamp || Float.isNaN(event.values[0]) || Float.isInfinite(event.values[0]) || event.values[0]<0) return;
        lastTimestamp=event.timestamp;
        long age=Math.max(0L,(SystemClock.elapsedRealtimeNanos()-event.timestamp)/1000000L);
        long time=System.currentTimeMillis()-age;
        StepLedger.record(this,(long)event.values[0],time);
        long now=SystemClock.elapsedRealtime();
        if(now-lastWidgetUpdate>=60000L){
            lastWidgetUpdate=now;
            com.domenklay.mybalance.widgets.BalanceWidget.refresh(this);
        }
    }
    @Override public void onAccuracyChanged(Sensor s,int accuracy) {}
    @Override public void onDestroy() {
        running=false;
        if(manager!=null) manager.unregisterListener(this);
        StepLedger.resetBaseline(this);
        super.onDestroy();
    }
}
