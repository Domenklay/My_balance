package com.domenklay.mybalance.steps;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

public final class MyBalanceSteps extends GodotPlugin {
    private static final int REQUEST=19351;
    public MyBalanceSteps(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "MyBalanceSteps"; }
    @UsedByGodot public String snapshot() {
        Activity a=getActivity();
        return a==null?"{}":StepLedger.snapshot(a,StepService.supported(a),StepService.permission(a),StepService.running);
    }
    private void start(Activity a) {
        if(!StepService.permission(a) || !StepService.supported(a)) return;
        try {
            Intent i=new Intent(a,StepService.class);
            if(Build.VERSION.SDK_INT>=26) a.startForegroundService(i); else a.startService(i);
        } catch(Exception ignored) {}
    }
    @UsedByGodot public void startSteps() {
        Activity a=getActivity();
        if(a==null) return;
        a.runOnUiThread(()->{
            if(!StepService.supported(a)) return;
            if(!StepService.permission(a) && Build.VERSION.SDK_INT>=29) {
                a.requestPermissions(new String[]{Manifest.permission.ACTIVITY_RECOGNITION},REQUEST);
            } else start(a);
        });
    }
    @Override public void onMainRequestPermissionsResult(int requestCode,String[] permissions,int[] grantResults) {
        if(requestCode!=REQUEST || grantResults.length==0 || grantResults[0]!=PackageManager.PERMISSION_GRANTED) return;
        Activity a=getActivity(); if(a!=null) a.runOnUiThread(()->start(a));
    }
    @UsedByGodot public void stopSteps() {
        Activity a=getActivity();
        if(a!=null) a.runOnUiThread(()->a.stopService(new Intent(a,StepService.class)));
    }
    @UsedByGodot public void openStepSettings() {
        Activity a=getActivity();
        if(a!=null) a.runOnUiThread(()->{
            try { a.startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:"+a.getPackageName()))); } catch(Exception ignored) {}
        });
    }
}
