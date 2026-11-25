package com.domenklay.mybalance.widgets;

import android.app.PendingIntent;
import android.app.AlarmManager;
import java.util.Calendar;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.*;
import android.graphics.Color;
import android.view.View;
import android.widget.RemoteViews;
import org.json.JSONObject;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class BalanceWidget extends AppWidgetProvider {
    static final String PREFS="mybalance_widget_v1";
    static final String ROLLOVER="com.domenklay.mybalance.WIDGET_ROLLOVER";
    static SharedPreferences prefs(Context c){return c.getSharedPreferences(PREFS,Context.MODE_PRIVATE);}
    static String today(){return new SimpleDateFormat("yyyy-MM-dd",Locale.US).format(new Date());}
    static int resource(Context c,String type,String name){return c.getResources().getIdentifier(name,type,c.getPackageName());}
    static int id(Context c,String name){return resource(c,"id",name);}
    static void text(Context c,RemoteViews v,String name,String value,int color){
        v.setTextViewText(id(c,name),value); v.setTextColor(id(c,name),color);
    }
    static PendingIntent open(Context c,int widget,String action){
        Intent i=new Intent(c,WidgetOpenActivity.class).putExtra("widget_action",action);
        i.setData(android.net.Uri.parse("mybalance-widget://"+widget+"/"+action));
        return PendingIntent.getActivity(c,0,i,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
    }
    // Inexact alarm avoids requesting special exact-alarm access.
    static void scheduleRollover(Context c){
        AppWidgetManager manager=AppWidgetManager.getInstance(c);
        AlarmManager alarms=(AlarmManager)c.getSystemService(Context.ALARM_SERVICE);
        if(alarms==null)return;
        Intent intent=new Intent(c,CompactWidget.class).setAction(ROLLOVER);
        PendingIntent pending=PendingIntent.getBroadcast(c,731,intent,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        if(manager.getAppWidgetIds(new ComponentName(c,CompactWidget.class)).length==0&&manager.getAppWidgetIds(new ComponentName(c,ExpandedWidget.class)).length==0){
            alarms.cancel(pending);return;
        }
        Calendar next=Calendar.getInstance();
        next.add(Calendar.DAY_OF_YEAR,1);
        next.set(Calendar.HOUR_OF_DAY,0);next.set(Calendar.MINUTE,0);next.set(Calendar.SECOND,0);next.set(Calendar.MILLISECOND,0);
        alarms.setWindow(AlarmManager.RTC,next.getTimeInMillis(),15*60000L,pending);
    }
    public static void refresh(Context c){
        AppWidgetManager manager=AppWidgetManager.getInstance(c);
        for(Class<?> type:new Class<?>[]{CompactWidget.class,ExpandedWidget.class}){
            int[] ids=manager.getAppWidgetIds(new ComponentName(c,type));
            for(int widget:ids)render(c,manager,widget,type==ExpandedWidget.class);
        }
    }
    static String macro(JSONObject macros,String key,String label){
        JSONObject m=macros.optJSONObject(key);
        return m==null?"":label+" "+m.optInt("used")+"/"+m.optInt("goal")+" г";
    }
    static void render(Context c,AppWidgetManager manager,int widget,boolean expanded){
        JSONObject data;
        try{data=new JSONObject(prefs(c).getString("snapshot","{}"));}catch(Exception e){data=new JSONObject();}
        JSONObject days=data.optJSONObject("days");
        if(days!=null){
            JSONObject current=days.optJSONObject(today());
            JSONObject fallback=days.optJSONObject(data.optString("date"));
            if(current!=null)data=current;
            else if(fallback!=null)data=fallback;
        }
        boolean en="en".equals(data.optString("language"));
        boolean allowed=prefs(c).getBoolean("visible",false);
        boolean valid=allowed&&data.optBoolean("ready")&&today().equals(data.optString("date"));
        String theme=data.optString("theme","forest");
        String bg="#194B38";
        switch(theme){case "mint":bg="#126882";break;case "sand":bg="#8C5C3B";break;case "dark":bg="#223D5D";break;case "botanical":bg="#543456";break;}
        int fg=Color.WHITE,muted=Color.parseColor("#F0F0F0");
        RemoteViews v=new RemoteViews(c.getPackageName(),resource(c,"layout",expanded?"mybalance_widget_expanded":"mybalance_widget_compact"));
        v.setInt(id(c,"mb_widget_root"),"setBackgroundResource",resource(c,"drawable","mb_widget_"+(theme.matches("forest|mint|sand|dark|botanical")?theme:"forest")));
        text(c,v,"mb_widget_title",en?"My Balance":"Мой баланс",fg);
        int eaten=Math.max(0,data.optInt("eaten")),goal=Math.max(1,data.optInt("goal",1800));
        if(valid){
            text(c,v,"mb_widget_value",Math.max(0,goal-eaten)+(en?" kcal":" ккал"),fg);
            text(c,v,"mb_widget_subtitle",eaten>goal?(en?"Above target: ":"Сверх цели: ")+(eaten-goal):(en?"Remaining today":"Осталось сегодня"),muted);
            v.setProgressBar(id(c,"mb_widget_progress"),goal,Math.min(goal,eaten),false);
            v.setViewVisibility(id(c,"mb_widget_progress"),View.VISIBLE);
        }else{
            text(c,v,"mb_widget_value","—",fg);
            text(c,v,"mb_widget_subtitle",allowed?(en?"Open app to refresh":"Открой приложение для обновления"):(en?"Data hidden in settings":"Данные скрыты в настройках"),muted);
            v.setViewVisibility(id(c,"mb_widget_progress"),View.GONE);
        }
        v.setOnClickPendingIntent(id(c,"mb_widget_root"),open(c,widget,allowed?"day":"settings"));
        text(c,v,"mb_widget_food",en?"+ Food":"+ Еда",fg);
        v.setOnClickPendingIntent(id(c,"mb_widget_food"),open(c,widget,"food"));
        if(expanded){
            JSONObject macros=data.optJSONObject("macros");
            String macroLine="";
            if(valid&&macros!=null&&macros.length()>0){
                for(String[] item:new String[][]{{"p",en?"P":"Б"},{"f",en?"F":"Ж"},{"c",en?"C":"У"}}){
                    String value=macro(macros,item[0],item[1]);
                    if(!value.isEmpty())macroLine+=(macroLine.isEmpty()?"":"  ·  ")+value;
                }
            }
            v.setViewVisibility(id(c,"mb_widget_macros"),macroLine.isEmpty()?View.GONE:View.VISIBLE);
            text(c,v,"mb_widget_macros",macroLine,muted);
            int steps=data.optInt("steps",0);
            if(valid&&"auto".equals(data.optString("step_source"))){
                int sensor=c.getSharedPreferences("mybalance_step_sensor_v1",Context.MODE_PRIVATE).getInt("day_"+today(),0);
                steps=Math.max(steps,sensor);
            }
            text(c,v,"mb_widget_water",en?"Water":"Вода",fg);
            text(c,v,"mb_widget_water_value",valid?data.optInt("water")+"/"+data.optInt("water_goal",2000)+(en?" ml":" мл"):"—",muted);
            text(c,v,"mb_widget_steps",en?"Steps":"Шаги",fg);
            text(c,v,"mb_widget_steps_value",valid?Integer.toString(steps):"—",muted);
            v.setOnClickPendingIntent(id(c,"mb_widget_water_box"),open(c,widget,"water"));
            v.setOnClickPendingIntent(id(c,"mb_widget_steps_box"),open(c,widget,"sport"));
        }
        manager.updateAppWidget(widget,v);
    }
    @Override public void onUpdate(Context c,AppWidgetManager manager,int[] ids){
        for(int widget:ids)render(c,manager,widget,this instanceof ExpandedWidget);
        scheduleRollover(c);
    }
    @Override public void onDisabled(Context c){scheduleRollover(c);}
    @Override public void onAppWidgetOptionsChanged(Context c,AppWidgetManager manager,int id,android.os.Bundle options){
        render(c,manager,id,this instanceof ExpandedWidget);
    }
    @Override public void onReceive(Context c,Intent intent){
        super.onReceive(c,intent);
        String action=intent.getAction();
        if(ROLLOVER.equals(action)||Intent.ACTION_DATE_CHANGED.equals(action)||Intent.ACTION_TIME_CHANGED.equals(action)||Intent.ACTION_TIMEZONE_CHANGED.equals(action)||Intent.ACTION_MY_PACKAGE_REPLACED.equals(action)||Intent.ACTION_BOOT_COMPLETED.equals(action)){refresh(c);scheduleRollover(c);}
    }
}
