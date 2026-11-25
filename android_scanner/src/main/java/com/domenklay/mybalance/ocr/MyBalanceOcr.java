package com.domenklay.mybalance.ocr;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ImageDecoder;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import androidx.core.content.FileProvider;
import com.googlecode.tesseract.android.TessBaseAPI;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;

public final class MyBalanceOcr extends GodotPlugin {
    private static final int PHOTO = 19348, GALLERY = 19349;
    private static final SignalInfo TEXT = new SignalInfo("ocr_text", String.class);
    private static final SignalInfo ERROR = new SignalInfo("ocr_error", String.class);
    private static final SignalInfo CANCEL = new SignalInfo("ocr_cancelled");
    private final AtomicBoolean busy = new AtomicBoolean(false);
    private File capture;
    private Uri captureUri;
    public MyBalanceOcr(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "MyBalanceOcr"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(TEXT, ERROR, CANCEL));
    }
    @UsedByGodot public void pickLabel(boolean camera) {
        Activity activity = getActivity();
        if (activity == null || !busy.compareAndSet(false,true)) {
            emitSignal(ERROR.getName(),"Распознавание недоступно или уже выполняется.");
            return;
        }
        activity.runOnUiThread(() -> {
            try {
                if (camera) {
                    File directory = new File(activity.getCacheDir(),"ocr_capture");
                    if (!directory.isDirectory() && !directory.mkdirs()) throw new IllegalStateException();
                    for (File old : directory.listFiles() == null ? new File[0] : directory.listFiles()) old.delete();
                    capture = File.createTempFile("label_",".jpg",directory);
                    captureUri = FileProvider.getUriForFile(activity,activity.getPackageName()+".nutritionocr",capture);
                    Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                    intent.putExtra(MediaStore.EXTRA_OUTPUT,captureUri);
                    intent.setClipData(ClipData.newRawUri("label",captureUri));
                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
                    activity.startActivityForResult(intent,PHOTO);
                } else {
                    Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                    intent.addCategory(Intent.CATEGORY_OPENABLE);
                    intent.setType("image/*");
                    activity.startActivityForResult(intent,GALLERY);
                }
            } catch (Exception e) {
                cleanup(activity);
                busy.set(false);
                emitSignal(ERROR.getName(),"Не удалось открыть камеру или фотографии.");
            }
        });
    }
    private void cleanup(Activity a) {
        if (captureUri != null) {
            try { a.revokeUriPermission(captureUri,Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_WRITE_URI_PERMISSION); } catch(Exception ignored) {}
        }
        if (capture != null) capture.delete();
        capture = null;
        captureUri = null;
    }
    @Override public void onMainActivityResult(int requestCode,int resultCode,Intent data) {
        if (requestCode != PHOTO && requestCode != GALLERY) return;
        Activity a = getActivity();
        if (a == null) { busy.set(false); return; }
        Uri uri = requestCode == PHOTO ? captureUri : data == null ? null : data.getData();
        if (resultCode != Activity.RESULT_OK || uri == null) {
            cleanup(a); busy.set(false); emitSignal(CANCEL.getName()); return;
        }
        new Thread(() -> {
            TessBaseAPI tess = null;
            Bitmap image = null;
            String recognized = null;
            try {
                File base = new File(a.getFilesDir(),"nutrition_ocr_v1");
                File models = new File(base,"tessdata");
                if (!models.isDirectory() && !models.mkdirs()) throw new IllegalStateException();
                for (String lang : new String[]{"rus","eng","pol"}) {
                    File target = new File(models,lang+".traineddata");
                    if (!target.isFile() || target.length() < 100000) {
                        File temp = new File(models,lang+".tmp");
                        try (InputStream input = a.getAssets().open("nutrition_ocr/"+lang+".traineddata");
                             FileOutputStream output = new FileOutputStream(temp)) {
                            byte[] buffer = new byte[32768]; int n;
                            while ((n=input.read(buffer))!=-1) output.write(buffer,0,n);
                        }
                        if (!temp.renameTo(target)) throw new IllegalStateException();
                    }
                }
                if (Build.VERSION.SDK_INT >= 28) {
                    image = ImageDecoder.decodeBitmap(ImageDecoder.createSource(a.getContentResolver(),uri),
                        (decoder,info,source) -> {
                            int longest = Math.max(info.getSize().getWidth(),info.getSize().getHeight());
                            int sample = Math.max(1,(longest+2399)/2400);
                            decoder.setTargetSampleSize(sample);
                            decoder.setAllocator(ImageDecoder.ALLOCATOR_SOFTWARE);
                        });
                } else {
                    BitmapFactory.Options opt = new BitmapFactory.Options();
                    opt.inJustDecodeBounds = true;
                    try(InputStream in=a.getContentResolver().openInputStream(uri)) { BitmapFactory.decodeStream(in,null,opt); }
                    opt.inSampleSize=1;
                    while(Math.max(opt.outWidth,opt.outHeight)/opt.inSampleSize>2400) opt.inSampleSize*=2;
                    opt.inJustDecodeBounds=false;
                    opt.inPreferredConfig=Bitmap.Config.ARGB_8888;
                    try(InputStream in=a.getContentResolver().openInputStream(uri)) { image=BitmapFactory.decodeStream(in,null,opt); }
                }
                if (image == null) throw new IllegalStateException();
                if (image.getConfig()!=Bitmap.Config.ARGB_8888) {
                    Bitmap converted=image.copy(Bitmap.Config.ARGB_8888,false); image.recycle(); image=converted;
                }
                tess=new TessBaseAPI();
                if (!tess.init(base.getAbsolutePath(),"rus+eng+pol")) throw new IllegalStateException();
                tess.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO);
                tess.setImage(image);
                recognized=tess.getUTF8Text();
                if(recognized != null && recognized.length()>12000) recognized=recognized.substring(0,12000);
            } catch(Exception | LinkageError | OutOfMemoryError e) {
                recognized=null;
            } finally {
                if(tess!=null) tess.recycle();
                if(image!=null) image.recycle();
                cleanup(a); busy.set(false);
            }
            final String result=recognized;
            a.runOnUiThread(() -> {
                if(result==null || result.trim().isEmpty()) emitSignal(ERROR.getName(),"Не удалось прочитать этикетку. Сфотографируй крупнее или введи КБЖУ вручную.");
                else emitSignal(TEXT.getName(),result);
            });
        },"MyBalanceLabelOcr").start();
    }
}
