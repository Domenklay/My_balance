package com.domenklay.mybalance.cloud;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.IntentSender;
import com.google.android.gms.auth.api.identity.AuthorizationClient;
import com.google.android.gms.auth.api.identity.AuthorizationRequest;
import com.google.android.gms.auth.api.identity.AuthorizationResult;
import com.google.android.gms.auth.api.identity.Identity;
import com.google.android.gms.auth.api.identity.RevokeAccessRequest;
import com.google.android.gms.common.api.Scope;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Optional Google Drive appDataFolder backup provider for MyBalance.
 *
 * No server or embedded OAuth secret is used. Google Play Services provides
 * scoped authorization and this plugin keeps short-lived bearer tokens only
 * in RAM. All HTTP requests go to fixed Google Drive API endpoints.
 * A remote checksum must match before overwriting an existing backup.
 */
public final class MyBalanceGoogleDrive extends GodotPlugin {
    private static final String SCOPE = "https://www.googleapis.com/auth/drive.appdata";
    private static final String FILENAME = "mybalance-backup-v1.json";
    private static final String LIST_URL =
        "https://www.googleapis.com/drive/v3/files?spaces=appDataFolder"
        + "&q=name%3D%27mybalance-backup-v1.json%27"
        + "&fields=nextPageToken,files(id,name,md5Checksum,modifiedTime)&pageSize=20";
    private static final int AUTH_REQUEST = 19346;
    private static final int MAX_BACKUP = 5_000_000;

    private static final SignalInfo CONNECTED = new SignalInfo("google_connected");
    private static final SignalInfo DISCONNECTED = new SignalInfo("google_disconnected");
    private static final SignalInfo STATUS = new SignalInfo("google_status",
        Boolean.class, String.class, String.class);
    private static final SignalInfo BACKUP = new SignalInfo("google_backup_loaded", String.class);
    private static final SignalInfo SAVED = new SignalInfo("google_backup_saved", String.class);
    private static final SignalInfo DELETED = new SignalInfo("google_backup_deleted");
    private static final SignalInfo ERROR = new SignalInfo("google_error", String.class);

    private final ExecutorService io = Executors.newSingleThreadExecutor();
    private volatile String accessToken = null;

    public MyBalanceGoogleDrive(Godot godot) {
        super(godot);
    }

    @Override public String getPluginName() { return "MyBalanceGoogleDrive"; }

    @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(CONNECTED, DISCONNECTED, STATUS,
            BACKUP, SAVED, DELETED, ERROR));
    }

    @UsedByGodot public boolean isConnected() {
        return accessToken != null && !accessToken.isEmpty();
    }

    @UsedByGodot public void authorize() {
        final Activity activity = getActivity();
        if (activity == null) {
            error("Подключение Google доступно только на Android.");
            return;
        }
        activity.runOnUiThread(() -> {
            AuthorizationRequest request = AuthorizationRequest.builder()
                .setRequestedScopes(Collections.singletonList(new Scope(SCOPE)))
                .build();
            try {
                AuthorizationClient client = Identity.getAuthorizationClient(activity);
                client.authorize(request).addOnSuccessListener(result -> {
                    if (result.hasResolution()) {
                        PendingIntent intent = result.getPendingIntent();
                        if (intent == null) {
                            error("Google не предоставил окно разрешения.");
                            return;
                        }
                        try {
                            activity.startIntentSenderForResult(intent.getIntentSender(),
                                AUTH_REQUEST, null, 0, 0, 0);
                        } catch (IntentSender.SendIntentException e) {
                            error("Не удалось открыть подтверждение Google.");
                        }
                    } else {
                        connected(result);
                    }
                }).addOnFailureListener(e -> error(
                    "Не удалось авторизовать Google Диск. Проверь OAuth, Google Play Services и интернет."));
            } catch (Exception e) {
                error("Google Play Services недоступны на устройстве.");
            }
        });
    }

    @Override public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != AUTH_REQUEST) return;
        if (resultCode != Activity.RESULT_OK || data == null) {
            error("Доступ к Google Диску не предоставлен.");
            return;
        }
        try {
            connected(Identity.getAuthorizationClient(getActivity())
                .getAuthorizationResultFromIntent(data));
        } catch (Exception ignored) {
            error("Google не подтвердил разрешение на резервные копии.");
        }
    }

    private void connected(AuthorizationResult result) {
        String token = result.getAccessToken();
        if (token == null || token.trim().isEmpty() ||
                !result.getGrantedScopes().contains(SCOPE)) {
            error("Не предоставлен доступ к папке данных приложения.");
            return;
        }
        accessToken = token;
        signal(CONNECTED);
    }

    @UsedByGodot public void disconnect() {
        accessToken = null;
        signal(DISCONNECTED);
    }

    @UsedByGodot public void revoke() {
        Activity activity = getActivity();
        accessToken = null;
        if (activity == null) {
            signal(DISCONNECTED);
            return;
        }
        activity.runOnUiThread(() -> {
            RevokeAccessRequest request = RevokeAccessRequest.builder()
                .setScopes(Collections.singletonList(new Scope(SCOPE))).build();
            Identity.getAuthorizationClient(activity).revokeAccess(request)
                .addOnCompleteListener(task -> {
                    signal(DISCONNECTED);
                    if (!task.isSuccessful()) error("Не удалось отозвать разрешение Google.");
                });
        });
    }

    @UsedByGodot public void checkBackup() {
        background(() -> {
            JSONObject file = findBackup();
            signal(STATUS, file != null,
                file == null ? "" : file.optString("modifiedTime", ""),
                file == null ? "" : file.optString("md5Checksum", ""));
        });
    }

    @UsedByGodot public void downloadBackup() {
        background(() -> {
            JSONObject file = findBackup();
            if (file == null) { error("В Google Диске нет резервной копии."); return; }
            HttpResponse content = request("GET", "https://www.googleapis.com/drive/v3/files/"
                + file.getString("id") + "?alt=media", null, null);
            if (content.code != 200) throw new Exception("Не удалось загрузить резервную копию.");
            signal(BACKUP, content.body);
        });
    }

    @UsedByGodot public void uploadBackup(String json, String expectedMd5) {
        if (json == null || json.isEmpty() || json.getBytes(StandardCharsets.UTF_8).length > MAX_BACKUP) {
            error("Резервная копия превышает 5 МБ.");
            return;
        }
        background(() -> {
            // Refuse to overwrite remote changes since the last check.
            JSONObject file = findBackup();
            String actual = file == null ? "" : file.optString("md5Checksum", "");
            if (expectedMd5 == null || !actual.equals(expectedMd5)) {
                error("Облачная копия изменилась. Проверь её перед сохранением.");
                signal(STATUS, file != null,
                    file == null ? "" : file.optString("modifiedTime", ""), actual);
                return;
            }
            HttpResponse response;
            if (file != null) {
                response = request("PATCH", "https://www.googleapis.com/upload/drive/v3/files/"
                    + file.getString("id") + "?uploadType=media",
                    "application/json; charset=utf-8", json);
            } else {
                String boundary = "mybalance-android-backup-boundary";
                String multipart = "--" + boundary + "\r\n"
                    + "Content-Type: application/json; charset=UTF-8\r\n\r\n"
                    + "{\"name\":\"" + FILENAME + "\",\"parents\":[\"appDataFolder\"]}\r\n"
                    + "--" + boundary + "\r\n"
                    + "Content-Type: application/json; charset=UTF-8\r\n\r\n"
                    + json + "\r\n--" + boundary + "--\r\n";
                response = request("POST",
                    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
                    + "&fields=id,modifiedTime", "multipart/related; boundary=" + boundary, multipart);
            }
            if (response.code < 200 || response.code >= 300)
                throw new Exception("Google Диск не принял резервную копию.");
            JSONObject saved = findBackup();
            if (saved == null) throw new Exception("Копия отправлена, но не подтверждена Google Диском.");
            signal(SAVED, saved.optString("modifiedTime", ""));
            signal(STATUS, true, saved.optString("modifiedTime", ""),
                saved.optString("md5Checksum", ""));
        });
    }

    @UsedByGodot public void deleteBackup() {
        background(() -> {
            JSONObject file = findBackup();
            if (file == null) { signal(DELETED); signal(STATUS, false, "", ""); return; }
            HttpResponse result = request("DELETE",
                "https://www.googleapis.com/drive/v3/files/" + file.getString("id"), null, null);
            if (result.code != 204) throw new Exception("Google Диск отказал в удалении копии.");
            signal(DELETED);
            signal(STATUS, false, "", "");
        });
    }

    private JSONObject findBackup() throws Exception {
        HttpResponse response = request("GET", LIST_URL, null, null);
        if (response.code != 200) throw new Exception("Не удалось открыть папку данных Google Диска.");
        JSONArray files = new JSONObject(response.body).optJSONArray("files");
        if (files == null || files.length() == 0) return null;
        if (files.length() > 1) throw new Exception(
            "Найдено несколько облачных копий. Безопасное обновление остановлено.");
        return files.getJSONObject(0);
    }

    private interface CloudAction { void execute() throws Exception; }
    private void background(CloudAction action) {
        if (!isConnected()) { error("Сначала подключи Google Диск."); return; }
        io.execute(() -> {
            try { action.execute(); }
            catch (Exception ex) {
                // Never log tokens or remote personal data.
                if (ex.getMessage() != null && ex.getMessage().startsWith("HTTP 401"))
                    error("Срок разрешения Google истёк. Подключись ещё раз.");
                else error(ex.getMessage() == null ? "Ошибка связи с Google Диском." : ex.getMessage());
            }
        });
    }

    private HttpResponse request(String method, String url, String mime, String body) throws Exception {
        final String token = accessToken;
        if (token == null || token.isEmpty()) throw new Exception("Сначала подключи Google Диск.");
        HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
        connection.setRequestMethod(method);
        connection.setConnectTimeout(14000);
        connection.setReadTimeout(16000);
        connection.setRequestProperty("Authorization", "Bearer " + token);
        connection.setRequestProperty("Accept", "application/json");
        connection.setUseCaches(false);
        if (body != null) {
            connection.setDoOutput(true);
            connection.setRequestProperty("Content-Type", mime);
            byte[] raw = body.getBytes(StandardCharsets.UTF_8);
            connection.setFixedLengthStreamingMode(raw.length);
            try (OutputStream out = connection.getOutputStream()) { out.write(raw); }
        }
        int code = connection.getResponseCode();
        if (code < 200 || code >= 300) {
            connection.disconnect();
            throw new Exception("HTTP " + code + " — проверь доступ Google Диска и подключение.");
        }
        InputStream in = code == 204 ? null : connection.getInputStream();
        ByteArrayOutputStream data = new ByteArrayOutputStream();
        if (in != null) {
            try (InputStream stream = in) {
                byte[] block = new byte[8192];
                int count;
                while ((count = stream.read(block)) != -1) {
                    if (data.size() + count > MAX_BACKUP + 50_000)
                        throw new Exception("Данные Google Диска превышают лимит.");
                    data.write(block, 0, count);
                }
            }
        }
        connection.disconnect();
        return new HttpResponse(code, data.toString("UTF-8"));
    }

    private static final class HttpResponse {
        final int code;
        final String body;
        HttpResponse(int code, String body) { this.code = code; this.body = body; }
    }

    private void signal(SignalInfo signal, Object... args) {
        Activity activity = getActivity();
        if (activity != null) activity.runOnUiThread(() -> emitSignal(signal.getName(), args));
    }

    private void error(String message) {
        signal(ERROR, message);
    }
}
