package com.domenklay.mybalance.photos;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ImageDecoder;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.util.Base64;
import androidx.core.content.FileProvider;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;

public final class MyBalancePhotos extends GodotPlugin {
    private static final int CAMERA=19352, GALLERY=19353, EXPORT_BACKUP=19354, IMPORT_BACKUP=19355;
    private static final long BACKUP_LIMIT=112000000L;
    private static final SignalInfo BACKUP=new SignalInfo("progress_backup_result",String.class);
    private static final SignalInfo PHOTO=new SignalInfo("progress_photo",String.class);
    private static final SignalInfo ERROR=new SignalInfo("progress_photo_error",String.class);
    private static final SignalInfo CANCEL=new SignalInfo("progress_photo_cancelled");
    private final AtomicBoolean busy=new AtomicBoolean(false);
    private File capture;
    private Uri captureUri;
    public MyBalancePhotos(Godot godot){super(godot);}
    @Override public String getPluginName(){return "MyBalancePhotos";}
    @Override public Set<SignalInfo> getPluginSignals(){return new HashSet<>(Arrays.asList(PHOTO,ERROR,CANCEL,BACKUP));}
    @UsedByGodot public String privateFolder(){
        Activity a=getActivity();
        return a==null?"":new File(a.getNoBackupFilesDir(),"progress_photos_v1").getAbsolutePath();
    }
    @UsedByGodot public void pickPhoto(boolean camera){
        Activity a=getActivity();
        if(a==null||!busy.compareAndSet(false,true)){emitSignal(ERROR.getName(),"Фото уже выбирается или недоступно.");return;}
        a.runOnUiThread(()->{
            try {
                if(camera){
                    File directory=new File(a.getCacheDir(),"progress_capture");
                    if(!directory.isDirectory()&&!directory.mkdirs())throw new IllegalStateException();
                    File[] old=directory.listFiles();
                    if(old!=null)for(File f:old)f.delete();
                    capture=File.createTempFile("progress_",".jpg",directory);
                    captureUri=FileProvider.getUriForFile(a,a.getPackageName()+".nutritionocr",capture);
                    Intent intent=new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                    intent.putExtra(MediaStore.EXTRA_OUTPUT,captureUri);
                    intent.setClipData(ClipData.newRawUri("progress",captureUri));
                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
                    a.startActivityForResult(intent,CAMERA);
                }else{
                    Intent intent=new Intent(Intent.ACTION_OPEN_DOCUMENT);
                    intent.addCategory(Intent.CATEGORY_OPENABLE);
                    intent.setType("image/*");
                    a.startActivityForResult(intent,GALLERY);
                }
            }catch(Exception e){cleanup(a);busy.set(false);emitSignal(ERROR.getName(),"Не удалось открыть камеру или галерею.");}
        });
    }
    private void cleanup(Activity a){
        if(captureUri!=null)try{a.revokeUriPermission(captureUri,Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_GRANT_WRITE_URI_PERMISSION);}catch(Exception ignored){}
        if(capture!=null)capture.delete();
        capture=null;captureUri=null;
    }
    @UsedByGodot public void pickBackup(boolean exporting){
        Activity a=getActivity();
        if(a==null||!busy.compareAndSet(false,true)){emitSignal(BACKUP.getName(),"error");return;}
        a.runOnUiThread(()->{
            try{
                Intent intent=new Intent(exporting?Intent.ACTION_CREATE_DOCUMENT:Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType(exporting?"application/zip":"*/*");
                if(exporting)intent.putExtra(Intent.EXTRA_TITLE,"MyBalance-Photos-"+new java.text.SimpleDateFormat("yyyy-MM-dd",java.util.Locale.ROOT).format(new java.util.Date())+".zip");
                a.startActivityForResult(intent,exporting?EXPORT_BACKUP:IMPORT_BACKUP);
            }catch(Exception e){busy.set(false);emitSignal(BACKUP.getName(),"error");}
        });
    }
    private void backupResult(int code,int result,Intent data){
        Activity a=getActivity();
        if(a==null){busy.set(false);return;}
        Uri uri=data==null?null:data.getData();
        if(result!=Activity.RESULT_OK||uri==null){busy.set(false);emitSignal(BACKUP.getName(),"cancelled");return;}
        new Thread(()->{
            String status="error";
            File path=new File(privateFolder(),"transfer.zip");
            try{
                if(code==EXPORT_BACKUP){
                    if(!path.isFile()||path.length()>BACKUP_LIMIT)throw new IllegalStateException();
                    try(InputStream in=new FileInputStream(path);OutputStream out=a.getContentResolver().openOutputStream(uri,"wt")){
                        copyBounded(in,out);
                    }
                    status="exported";
                }else{
                    try(InputStream in=a.getContentResolver().openInputStream(uri);OutputStream out=new FileOutputStream(path)){
                        copyBounded(in,out);
                    }
                    status="imported";
                }
            }catch(Exception e){path.delete();}
            finally{busy.set(false);}
            final String output=status;
            a.runOnUiThread(()->emitSignal(BACKUP.getName(),output));
        },"MyBalancePhotoBackup").start();
    }
    private static void copyBounded(InputStream in,OutputStream out)throws java.io.IOException{
        if(in==null||out==null)throw new java.io.IOException("Stream unavailable");
        byte[] buffer=new byte[65536];
        long total=0;
        int count;
        while((count=in.read(buffer))!=-1){
            total+=count;
            if(total>BACKUP_LIMIT)throw new java.io.IOException("Backup too large");
            out.write(buffer,0,count);
        }
        out.flush();
        if(total==0)throw new java.io.IOException("Empty backup");
    }
    @Override public void onMainActivityResult(int code,int result,Intent data){
        if(code==EXPORT_BACKUP||code==IMPORT_BACKUP){backupResult(code,result,data);return;}
        if(code!=CAMERA&&code!=GALLERY)return;
        Activity a=getActivity();
        if(a==null){busy.set(false);return;}
        Uri uri=code==CAMERA?captureUri:data==null?null:data.getData();
        if(result!=Activity.RESULT_OK||uri==null){cleanup(a);busy.set(false);emitSignal(CANCEL.getName());return;}
        new Thread(()->{
            Bitmap image=null;
            String encoded=null;
            try{
                if(Build.VERSION.SDK_INT>=28){
                    image=ImageDecoder.decodeBitmap(ImageDecoder.createSource(a.getContentResolver(),uri),(decoder,info,source)->{
                        int w=info.getSize().getWidth(),h=info.getSize().getHeight();
                        float scale=Math.min(1f,1440f/Math.max(w,h));
                        decoder.setTargetSize(Math.max(1,Math.round(w*scale)),Math.max(1,Math.round(h*scale)));
                        decoder.setAllocator(ImageDecoder.ALLOCATOR_SOFTWARE);
                    });
                }else{
                    BitmapFactory.Options options=new BitmapFactory.Options();
                    options.inJustDecodeBounds=true;
                    try(InputStream in=a.getContentResolver().openInputStream(uri)){BitmapFactory.decodeStream(in,null,options);}
                    options.inSampleSize=1;
                    while(Math.max(options.outWidth,options.outHeight)/options.inSampleSize>1440)options.inSampleSize*=2;
                    options.inJustDecodeBounds=false;
                    try(InputStream in=a.getContentResolver().openInputStream(uri)){image=BitmapFactory.decodeStream(in,null,options);}
                    if(image!=null&&Build.VERSION.SDK_INT>=24){
                        int orientation=1;
                        try(InputStream in=a.getContentResolver().openInputStream(uri)){orientation=new ExifInterface(in).getAttributeInt(ExifInterface.TAG_ORIENTATION,1);}catch(Exception ignored){}
                        Matrix matrix=new Matrix();
                        switch(orientation){
                            case 2:matrix.setScale(-1,1);break;
                            case 3:matrix.setRotate(180);break;
                            case 4:matrix.setScale(1,-1);break;
                            case 5:matrix.setRotate(90);matrix.postScale(-1,1);break;
                            case 6:matrix.setRotate(90);break;
                            case 7:matrix.setRotate(-90);matrix.postScale(-1,1);break;
                            case 8:matrix.setRotate(-90);break;
                            default:break;
                        }
                        if(!matrix.isIdentity()){
                            Bitmap corrected=Bitmap.createBitmap(image,0,0,image.getWidth(),image.getHeight(),matrix,true);
                            if(corrected!=image)image.recycle();
                            image=corrected;
                        }
                    }
                }
                if(image==null||Math.min(image.getWidth(),image.getHeight())<16)throw new IllegalStateException();
                for(int quality:new int[]{85,75,65,50,35}){
                    ByteArrayOutputStream out=new ByteArrayOutputStream();
                    if(image.compress(Bitmap.CompressFormat.JPEG,quality,out)&&out.size()<=400000){
                        encoded=Base64.encodeToString(out.toByteArray(),Base64.NO_WRAP);break;
                    }
                }
            }catch(Exception|OutOfMemoryError e){encoded=null;}
            finally{if(image!=null)image.recycle();cleanup(a);busy.set(false);}
            final String output=encoded;
            a.runOnUiThread(()->{if(output==null)emitSignal(ERROR.getName(),"Не удалось обработать фото.");else emitSignal(PHOTO.getName(),output);});
        },"MyBalanceProgressPhoto").start();
    }
}
