package com.domenklay.mybalance.steps;

import android.content.Context;
import android.content.SharedPreferences;
import org.json.JSONObject;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

final class StepLedger {
    static final String PREFS = "mybalance_step_sensor_v1";
    static SharedPreferences prefs(Context c) { return c.getSharedPreferences(PREFS,Context.MODE_PRIVATE); }
    static String day(long ms) { return new SimpleDateFormat("yyyy-MM-dd",Locale.US).format(new Date(ms)); }
    static int delta(long previous,long current,String before,String after) {
        if(previous<0 || current<previous || !before.equals(after)) return 0;
        long difference=current-previous;
        return difference<=100000 ? (int)difference : 0;
    }
    static synchronized void record(Context c,long raw,long eventMs) {
        SharedPreferences p=prefs(c);
        String date=day(eventMs);
        String oldDate=p.getString("last_day","");
        long old=p.getLong("last_raw",-1);
        int add=delta(old,raw,oldDate,date);
        int total=Math.min(100000,p.getInt("day_"+date,0)+add);
        SharedPreferences.Editor edit=p.edit().putLong("last_raw",raw).putString("last_day",date)
            .putInt("day_"+date,total).putLong("updated",System.currentTimeMillis());
        // Bound local sensor history; Godot retains imported daily values.
        String cutoff=day(System.currentTimeMillis()-90L*86400000L);
        for(String k:p.getAll().keySet()) if(k.startsWith("day_") && k.substring(4).compareTo(cutoff)<0) edit.remove(k);
        edit.apply();
    }
    static synchronized void resetBaseline(Context c) {
        prefs(c).edit().remove("last_raw").remove("last_day").apply();
    }
    static synchronized String snapshot(Context c,boolean supported,boolean permission,boolean running) {
        SharedPreferences p=prefs(c);
        JSONObject result=new JSONObject(), days=new JSONObject();
        try {
            for(String k:p.getAll().keySet()) if(k.startsWith("day_")) days.put(k.substring(4),p.getInt(k,0));
            result.put("days",days).put("supported",supported).put("permission",permission)
                .put("running",running).put("updated",p.getLong("updated",0));
        } catch(Exception ignored) {}
        return result.toString();
    }
}
