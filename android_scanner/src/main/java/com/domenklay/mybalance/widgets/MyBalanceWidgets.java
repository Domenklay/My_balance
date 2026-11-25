package com.domenklay.mybalance.widgets;
import android.app.Activity;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import org.json.JSONObject;

public final class MyBalanceWidgets extends GodotPlugin {
    public MyBalanceWidgets(Godot godot){super(godot);}
    @Override public String getPluginName(){return "MyBalanceWidgets";}
    @UsedByGodot public boolean dataVisible(){
        Activity a=getActivity();return a!=null&&BalanceWidget.prefs(a).getBoolean("visible",false);
    }
    @UsedByGodot public void setDataVisible(boolean enabled){
        Activity a=getActivity();if(a==null)return;
        android.content.SharedPreferences.Editor edit=BalanceWidget.prefs(a).edit().putBoolean("visible",enabled);
        if(!enabled)edit.remove("snapshot");
        edit.apply();
        a.runOnUiThread(()->BalanceWidget.refresh(a));
    }
    @UsedByGodot public void publish(String raw){
        Activity a=getActivity();if(a==null||!dataVisible()||raw==null||raw.length()>4096)return;
        try{
            JSONObject obj=new JSONObject(raw);
            if(!BalanceWidget.today().equals(obj.optString("date")))return;
            if(!raw.equals(BalanceWidget.prefs(a).getString("snapshot",""))){
                BalanceWidget.prefs(a).edit().putString("snapshot",raw).apply();
                a.runOnUiThread(()->BalanceWidget.refresh(a));
            }
        }catch(Exception ignored){}
    }
    @UsedByGodot public String takeAction(){
        Activity a=getActivity();if(a==null)return "";
        android.content.SharedPreferences p=BalanceWidget.prefs(a);
        String action=p.getString("action","");
        long time=p.getLong("action_time",0);
        if(!action.isEmpty())p.edit().remove("action").remove("action_time").apply();
        return System.currentTimeMillis()-time<60000?action:"";
    }
}
