package com.domenklay.mybalance.barcode;

import android.app.Activity;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import com.google.mlkit.vision.barcode.common.Barcode;
import com.google.mlkit.vision.codescanner.GmsBarcodeScanner;
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions;
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning;

import java.util.HashSet;
import java.util.Arrays;
import java.util.Set;

/**
 * Godot v2 Android plugin (registered through the Gradle template manifest).
 * Google's scanner UI owns the camera; this app receives just the decoded digits.
 * This API does not require CAMERA permission. Requires Google Play Services.
 */
public final class MyBalanceBarcode extends GodotPlugin {
    private static final SignalInfo SCANNED = new SignalInfo("barcode_scanned", String.class);
    private static final SignalInfo SCAN_ERROR = new SignalInfo("barcode_error", String.class);
    private static final SignalInfo SCAN_CANCELLED = new SignalInfo("barcode_cancelled");

    public MyBalanceBarcode(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "MyBalanceBarcode";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(SCANNED, SCAN_ERROR, SCAN_CANCELLED));
    }

    @UsedByGodot
    public void scanBarcode() {
        final Activity activity = getActivity();
        if (activity == null) {
            emitSignal(SCAN_ERROR.getName(), "Нет активного экрана Android");
            return;
        }
        activity.runOnUiThread(() -> {
            try {
                GmsBarcodeScannerOptions options = new GmsBarcodeScannerOptions.Builder()
                    .setBarcodeFormats(
                        Barcode.FORMAT_EAN_13,
                        Barcode.FORMAT_EAN_8,
                        Barcode.FORMAT_UPC_A,
                        Barcode.FORMAT_UPC_E,
                        Barcode.FORMAT_ITF,
                        Barcode.FORMAT_CODE_128)
                    .enableAutoZoom()
                    .build();
                GmsBarcodeScanner scanner = GmsBarcodeScanning.getClient(activity, options);
                scanner.startScan()
                    .addOnSuccessListener(barcode -> {
                        String value = barcode.getRawValue();
                        if (value == null || value.trim().isEmpty()) {
                            emitSignal(SCAN_ERROR.getName(), "Не удалось прочитать цифры штрихкода");
                        } else {
                            emitSignal(SCANNED.getName(), value.trim());
                        }
                    })
                    .addOnCanceledListener(() -> emitSignal(SCAN_CANCELLED.getName()))
                    .addOnFailureListener(error -> emitSignal(
                        SCAN_ERROR.getName(),
                        error.getLocalizedMessage() == null ? "Google Code Scanner недоступен" : error.getLocalizedMessage()));
            } catch (Exception exception) {
                emitSignal(SCAN_ERROR.getName(), "Нужны Google Play Services и установленный модуль сканера");
            }
        });
    }
}
