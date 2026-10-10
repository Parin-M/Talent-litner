package com.parin.parin_litner;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.res.AssetFileDescriptor;
import android.database.Cursor;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Vibrator;
import android.provider.OpenableColumns;
import android.view.KeyEvent;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;
import android.graphics.Color;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.util.Locale;
import java.util.Random;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import android.util.Base64;

@SuppressLint({"SetJavaScriptEnabled", "JavascriptInterface"})
public class MainActivity extends Activity {
    private static final int PICK_IMAGE = 1401;
    private static final int PICK_BACKUP = 1402;
    private static final Charset UTF8 = Charset.forName("UTF-8");
    private WebView webView;
    private Bridge bridge;
    private JSONObject pickedFile;
    private boolean canGoBack = false;
    private AudioTrack audioTrack;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        webView = new WebView(this);
        webView.setBackgroundColor(Color.WHITE);
        webView.setVerticalScrollBarEnabled(false);
        webView.setHorizontalScrollBarEnabled(false);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.getSettings().setDatabaseEnabled(true);
        webView.getSettings().setAllowFileAccess(true);
        webView.getSettings().setSupportZoom(false);
        webView.getSettings().setBuiltInZoomControls(false);
        webView.setWebChromeClient(new WebChromeClient());
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url != null && (url.startsWith("http://") || url.startsWith("https://"))) {
                    try {
                        startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
                    } catch (ActivityNotFoundException ignored) { }
                    return true;
                }
                return !url.startsWith("file:///android_asset/");
            }
        });
        bridge = new Bridge();
        webView.addJavascriptInterface(bridge, "Native");
        setContentView(webView);
        webView.loadUrl("file:///android_asset/index.html");
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if ((requestCode == PICK_IMAGE || requestCode == PICK_BACKUP) && resultCode == RESULT_OK && data != null) {
            Uri uri = data.getData();
            if (uri != null) {
                try {
                    byte[] bytes = readAll(getContentResolver().openInputStream(uri));
                    String name = queryName(uri);
                    String type = getContentResolver().getType(uri);
                    if (name == null) name = requestCode == PICK_IMAGE ? "image" : "backup";
                    if (type == null) type = requestCode == PICK_IMAGE ? "image/*" : "application/octet-stream";
                    pickedFile = new JSONObject();
                    pickedFile.put("name", name);
                    pickedFile.put("type", type);
                    pickedFile.put("base64", Base64.encodeToString(bytes, Base64.NO_WRAP));
                } catch (Exception ex) {
                    pickedFile = null;
                    toast("Could not read the selected file.");
                }
            }
        }
        if (webView != null) {
            final String callback = requestCode == PICK_IMAGE ? "onNativePickedImage" : "onNativePickedBackup";
            webView.post(new Runnable() {
                @Override public void run() {
                    webView.loadUrl("javascript:if(window." + callback + "){window." + callback + "();}");
                }
            });
        }
    }

    private byte[] readAll(InputStream input) throws IOException {
        if (input == null) throw new IOException("Unable to open file.");
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = input.read(buf)) != -1) out.write(buf, 0, n);
            return out.toByteArray();
        } finally { input.close(); }
    }

    private String queryName(Uri uri) {
        Cursor cursor = null;
        try {
            cursor = getContentResolver().query(uri, null, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                int index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                if (index >= 0) return cursor.getString(index);
            }
        } catch (Exception ignored) {
        } finally { if (cursor != null) cursor.close(); }
        String last = uri.getLastPathSegment();
        return last == null ? null : last;
    }

    private File downloadsDirectory() {
        File dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
        if (dir == null) dir = new File(Environment.getExternalStorageDirectory(), "Download");
        if (!dir.exists()) dir.mkdirs();
        return dir;
    }

    private void toast(final String message) {
        runOnUiThread(new Runnable() {
            @Override public void run() { Toast.makeText(MainActivity.this, message, Toast.LENGTH_LONG).show(); }
        });
    }

    @Override
    public void onBackPressed() {
        if (canGoBack && webView != null) {
            webView.loadUrl("javascript:if(window.handleNativeBack){window.handleNativeBack();}");
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onDestroy() {
        stopMusic();
        if (webView != null) {
            webView.removeJavascriptInterface("Native");
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }

    private synchronized void stopMusic() {
        if (audioTrack != null) {
            try { audioTrack.pause(); audioTrack.flush(); audioTrack.release(); } catch (Exception ignored) { }
            audioTrack = null;
        }
    }

    private synchronized void playMusic(String track, double volume) {
        stopMusic();
        final int sampleRate = 22050;
        final int length = sampleRate * 12;
        short[] pcm = new short[length];
        Random random = new Random(20261010L);
        double rainState = 0;
        for (int i = 0; i < length; i++) {
            double t = (double) i / (double) sampleRate;
            double value;
            if ("rainy_focus".equals(track)) {
                double white = random.nextDouble() * 2.0 - 1.0;
                rainState = 0.985 * rainState + 0.015 * white;
                value = 0.26 * (white - rainState)
                    + 0.16 * Math.sin(2 * Math.PI * 98.0 * t)
                    + 0.08 * Math.sin(2 * Math.PI * 147.0 * t);
            } else if ("deep_focus".equals(track)) {
                double pulse = 0.5 + 0.5 * Math.sin(2 * Math.PI * t / 8.0);
                value = 0.62 * (0.75 + 0.25 * pulse)
                    * (0.30 * Math.sin(2 * Math.PI * 110.0 * t)
                    + 0.16 * Math.sin(2 * Math.PI * 220.0 * t)
                    + 0.08 * Math.sin(2 * Math.PI * 164.81 * t) * pulse);
            } else {
                double env = Math.min(1.0, Math.min((t % 12.0) / 1.8, (12.0 - (t % 12.0)) / 1.8));
                double chord = 0.28 * Math.sin(2 * Math.PI * 174.61 * t)
                    + 0.20 * Math.sin(2 * Math.PI * 261.63 * t)
                    + 0.13 * Math.sin(2 * Math.PI * 329.63 * t);
                double bell = 0.05 * Math.sin(2 * Math.PI * 523.25 * t)
                    * (0.5 + 0.5 * Math.sin(2 * Math.PI * t / 4.0));
                value = 0.42 * env * (0.72 + 0.28 * (0.5 + 0.5 * Math.sin(2 * Math.PI * t / 7.0))) * (chord + bell);
            }
            if (value > 1) value = 1;
            if (value < -1) value = -1;
            pcm[i] = (short) (value * 23000);
        }
        int bytes = pcm.length * 2;
        audioTrack = new AudioTrack(AudioManager.STREAM_MUSIC, sampleRate,
            AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT, bytes, AudioTrack.MODE_STATIC);
        int written = audioTrack.write(pcm, 0, pcm.length);
        if (written > 0) {
            try { audioTrack.setLoopPoints(0, written, -1); } catch (Exception ignored) { }
            audioTrack.setStereoVolume((float) volume, (float) volume);
            audioTrack.play();
        }
    }

    public final class Bridge {
        @JavascriptInterface public String loadData() {
            File file = new File(getFilesDir(), "parin_litner_legacy.json");
            if (!file.exists()) return "";
            try { return new String(readAll(new FileInputStream(file)), UTF8); }
            catch (Exception ignored) { return ""; }
        }

        @JavascriptInterface public void saveData(String data) {
            if (data == null || data.length() > 100000000) return;
            File file = new File(getFilesDir(), "parin_litner_legacy.json");
            File temp = new File(getFilesDir(), "parin_litner_legacy.tmp");
            FileOutputStream out = null;
            try {
                out = new FileOutputStream(temp);
                out.write(data.getBytes(UTF8));
                out.flush();
                out.getFD().sync();
                out.close();
                out = null;
                if (file.exists() && !file.delete()) throw new IOException("Could not replace saved data.");
                if (!temp.renameTo(file)) throw new IOException("Could not save data.");
            } catch (Exception ex) {
                if (out != null) try { out.close(); } catch (Exception ignored) { }
                toast("Could not save study data.");
            }
        }

        @JavascriptInterface public void setCanGoBack(boolean value) { canGoBack = value; }

        @JavascriptInterface public void pickImage() { launchPicker(PICK_IMAGE, "image/*"); }
        @JavascriptInterface public void pickBackupFile() { launchPicker(PICK_BACKUP, "*/*"); }

        @JavascriptInterface public String consumePickedFile() {
            if (pickedFile == null) return "";
            String value = pickedFile.toString();
            pickedFile = null;
            return value;
        }

        private void launchPicker(final int requestCode, final String type) {
            runOnUiThread(new Runnable() {
                @Override public void run() {
                    try {
                        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
                        intent.setType(type);
                        intent.addCategory(Intent.CATEGORY_OPENABLE);
                        startActivityForResult(Intent.createChooser(intent, "Select file"), requestCode);
                    } catch (Exception ex) { toast("No file picker is available on this device."); }
                }
            });
        }

        @JavascriptInterface public String listBackupFiles() {
            JSONArray result = new JSONArray();
            File[] files = downloadsDirectory().listFiles();
            if (files != null) {
                for (File file : files) {
                    if (file.isFile() && (file.getName().toLowerCase(Locale.US).endsWith(".plbackup")
                        || file.getName().toLowerCase(Locale.US).endsWith(".json"))) {
                        result.put(file.getName());
                    }
                }
            }
            return result.toString();
        }

        @JavascriptInterface public String readBackupFile(String name) {
            if (name == null || name.length() > 255 || name.contains("/") || name.contains("\\")) return "";
            File file = new File(downloadsDirectory(), name);
            if (!file.isFile()) return "";
            try { return Base64.encodeToString(readAll(new FileInputStream(file)), Base64.NO_WRAP); }
            catch (Exception ignored) { return ""; }
        }

        @JavascriptInterface public String exportBackup(String base64, String name) {
            if (base64 == null || base64.length() > 100000000) return "ERROR";
            if (name == null || (!name.endsWith(".plbackup") && !name.endsWith(".json"))) name = "parin_litner_backup.plbackup";
            name = name.replace("/", "_").replace("\\", "_");
            File outFile = new File(downloadsDirectory(), name);
            try {
                byte[] bytes = Base64.decode(base64, Base64.DEFAULT);
                FileOutputStream out = new FileOutputStream(outFile);
                try { out.write(bytes); out.flush(); out.getFD().sync(); } finally { out.close(); }
                toast("Backup saved to Downloads/" + name);
                return outFile.getAbsolutePath();
            } catch (Exception ex) {
                toast("Could not save the backup file.");
                return "ERROR";
            }
        }

        @JavascriptInterface public void openUrl(String url) {
            if (url == null || !(url.startsWith("https://") || url.startsWith("http://"))) return;
            try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); }
            catch (Exception ignored) { toast("Unable to open link."); }
        }

        @JavascriptInterface public void vibrate(long milliseconds) {
            try {
                Vibrator vibrator = (Vibrator) getSystemService(VIBRATOR_SERVICE);
                if (vibrator != null && vibrator.hasVibrator()) vibrator.vibrate(Math.max(0L, Math.min(milliseconds, 300L)));
            } catch (Exception ignored) { }
        }

        @JavascriptInterface public void playMusic(String id, double volume) {
            final String track = id == null ? "lofi_night" : id;
            final double level = Math.max(0.0, Math.min(1.0, volume));
            runOnUiThread(new Runnable() { @Override public void run() { MainActivity.this.playMusic(track, level); } });
        }

        @JavascriptInterface public void pauseMusic() {
            runOnUiThread(new Runnable() { @Override public void run() { synchronized (MainActivity.this) { if (audioTrack != null) audioTrack.pause(); } } });
        }

        @JavascriptInterface public void stopMusic() {
            runOnUiThread(new Runnable() { @Override public void run() { MainActivity.this.stopMusic(); } });
        }

        @JavascriptInterface public void setMusicVolume(double volume) {
            final float level = (float) Math.max(0.0, Math.min(1.0, volume));
            runOnUiThread(new Runnable() { @Override public void run() {
                synchronized (MainActivity.this) { if (audioTrack != null) audioTrack.setStereoVolume(level, level); }
            }});
        }

        @JavascriptInterface public int androidApiLevel() { return android.os.Build.VERSION.SDK_INT; }
    }
}
