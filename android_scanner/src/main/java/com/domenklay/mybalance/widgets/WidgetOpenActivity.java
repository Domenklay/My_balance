package com.domenklay.mybalance.widgets;
import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
public final class WidgetOpenActivity extends Activity {
    @Override public void onCreate(Bundle state){
        super.onCreate(state);
        String action=getIntent().getStringExtra("widget_action");
        if(action!=null&&action.matches("day|food|water|sport|settings")){
            BalanceWidget.prefs(this).edit().putString("action",action).putLong("action_time",System.currentTimeMillis()).commit();
        }
        Intent launch=getPackageManager().getLaunchIntentForPackage(getPackageName());
        if(launch!=null){launch.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP);startActivity(launch);}
        finish();
    }
}
