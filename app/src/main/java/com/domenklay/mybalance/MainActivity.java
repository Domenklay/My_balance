package com.domenklay.mybalance;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.webkit.WebViewAssetLoader;

import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity {
    private static final int PICK_IMPORT = 1201;
    private static final int CREATE_BACKUP = 1202;
    private static final String APP_URL = "https://appassets.androidplatform.net/assets/index.html";

    private WebView web;
    private ValueCallback<Uri[]> pendingFileChooser;
    private String pendingExport;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WebViewAssetLoader assets = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();
        web = new WebView(this);
        setContentView(web);
        WebSettings settings = web.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(true);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        web.addJavascriptInterface(new BackupBridge(), "AndroidBackup");
        web.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                return assets.shouldInterceptRequest(request.getUrl());
            }
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                if ("appassets.androidplatform.net".equals(uri.getHost())
                        && "https".equals(uri.getScheme())) return false;
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, uri));
                } catch (Exception ignored) {
                    Toast.makeText(MainActivity.this, "Не удалось открыть ссылку", Toast.LENGTH_SHORT).show();
                }
                return true;
            }
        });
        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (pendingFileChooser != null) pendingFileChooser.onReceiveValue(null);
                pendingFileChooser = callback;
                Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("application/json");
                try {
                    startActivityForResult(intent, PICK_IMPORT);
                } catch (Exception ex) {
                    pendingFileChooser = null;
                    callback.onReceiveValue(null);
                    return false;
                }
                return true;
            }
        });
        web.loadUrl(APP_URL);
    }

    public final class BackupBridge {
        @JavascriptInterface
        public void saveJson(String contents) {
            if (contents == null || contents.length() > 5_000_000) return;
            runOnUiThread(() -> {
                pendingExport = contents;
                Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("application/json");
                intent.putExtra(Intent.EXTRA_TITLE, "moy-balans-backup.json");
                try {
                    startActivityForResult(intent, CREATE_BACKUP);
                } catch (Exception ex) {
                    Toast.makeText(MainActivity.this, "Не удалось выбрать файл", Toast.LENGTH_SHORT).show();
                }
            });
        }
    }

    @Override
    @Deprecated
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMPORT) {
            if (pendingFileChooser != null) {
                Uri[] result = resultCode == RESULT_OK && data != null && data.getData() != null
                        ? new Uri[]{data.getData()} : null;
                pendingFileChooser.onReceiveValue(result);
                pendingFileChooser = null;
            }
        } else if (requestCode == CREATE_BACKUP) {
            if (resultCode == RESULT_OK && data != null && data.getData() != null && pendingExport != null) {
                try (OutputStream output = getContentResolver().openOutputStream(data.getData())) {
                    if (output == null) throw new IllegalStateException("No output stream");
                    output.write(pendingExport.getBytes(StandardCharsets.UTF_8));
                    Toast.makeText(this, "Резервная копия сохранена", Toast.LENGTH_SHORT).show();
                } catch (Exception ex) {
                    Toast.makeText(this, "Не удалось сохранить резервную копию", Toast.LENGTH_LONG).show();
                }
            }
            pendingExport = null;
        }
    }

    @Override
    public void onBackPressed() {
        if (web != null && web.canGoBack()) {
            web.goBack();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onDestroy() {
        if (pendingFileChooser != null) {
            pendingFileChooser.onReceiveValue(null);
            pendingFileChooser = null;
        }
        if (web != null) web.destroy();
        super.onDestroy();
    }
}
