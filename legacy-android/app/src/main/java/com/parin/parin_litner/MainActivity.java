package com.parin.parin_litner;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Vibrator;
import android.provider.Settings;
import android.util.Base64;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.AlphaAnimation;
import android.view.inputmethod.EditorInfo;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.ArrayAdapter;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.TimeZone;

public class MainActivity extends Activity {
    private static final Charset UTF8 = Charset.forName("UTF-8");
    private static final byte[] BACKUP_MAGIC = new byte[] {80, 76, 73, 84, 66, 75, 48, 49};
    private static final int REQ_IMAGE = 401;
    private static final int REQ_IMPORT = 402;
    private static final int REQ_STORAGE = 403;
    private static final String PREF_FILE = "FlutterSharedPreferences";
    private static final String DATA_KEY = "flutter.parin_litner_v4_data";

    private SharedPreferences prefs;
    private JSONArray decks = new JSONArray();
    private JSONObject translationRoot = new JSONObject();
    private JSONArray themes = new JSONArray();
    private JSONObject currentTheme = new JSONObject();
    private int themeIndex = 0;
    private String appearanceMode = "aero";
    private String languageCode = "fa";
    private boolean glass = true, animations = true, haptics = true, autoReveal = false;
    private boolean showProgress = true, showTimer = true, showXp = true, confirmExit = true;
    private boolean compactSettings = false, musicEnabled = false;
    private double glassOpacity = 0.62, musicVolume = 0.35;
    private int dailyGoal = 20, xp = 0, streak = 0;
    private String lastStudyDay = "", lastRewardDay = "", musicTrack = "lofi_night";
    private final ArrayList<String> reviewDays = new ArrayList<String>();

    private LinearLayout root;
    private LinearLayout body;
    private Runnable backAction;
    private JSONObject editorDeck;
    private JSONObject editorCard;
    private EditText frontField, backField, tagsField;
    private String frontImage, backImage;
    private int imageSelectionSide = 0;

    private final ArrayList<StudyItem> studyItems = new ArrayList<StudyItem>();
    private int studyIndex = 0;
    private boolean answerRevealed = false;
    private boolean studyFinished = false;
    private long studyStartedAt = 0;
    private long studyElapsedSeconds = 0;
    private Handler handler = new Handler();
    private Runnable focusTick;
    private int focusRemainingSeconds = 25 * 60;
    private boolean focusRunning = false;
    private MediaPlayer player;
    private TextView focusTimerView;
    private TextView studyTimerView;
    private final Runnable studyTick = new Runnable() {
        @Override public void run() {
            if (studyTimerView != null && studyItems.size() > 0 && !studyFinished) {
                studyTimerView.setText(t("timer") + " • " + formatDuration((System.currentTimeMillis()-studyStartedAt)/1000));
                handler.postDelayed(this, 1000);
            }
        }
    };

    private static class StudyItem {
        JSONObject deck;
        JSONObject card;
        StudyItem(JSONObject d, JSONObject c) { deck = d; card = c; }
    }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        prefs = getSharedPreferences(PREF_FILE, MODE_PRIVATE);
        loadAssets();
        loadSettings();
        loadData();
        showHome();
    }

    private void loadAssets() {
        try {
            InputStream in = getAssets().open("translations.json");
            translationRoot = new JSONObject(new String(readAll(in), UTF8));
            in.close();
        } catch (Exception ignored) { translationRoot = new JSONObject(); }
        try {
            InputStream in = getAssets().open("themes.json");
            themes = new JSONArray(new String(readAll(in), UTF8));
            in.close();
        } catch (Exception ignored) { themes = new JSONArray(); }
        updateTheme();
    }

    private byte[] readAll(InputStream in) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buffer = new byte[8192];
        int n;
        while ((n = in.read(buffer)) != -1) out.write(buffer, 0, n);
        return out.toByteArray();
    }

    private void loadSettings() {
        themeIndex = Math.max(0, Math.min(49, prefInt("theme_index", 0)));
        appearanceMode = prefString("appearance_mode", "aero");
        if (!Arrays.asList("light", "dark", "aero", "amoled").contains(appearanceMode)) appearanceMode = "aero";
        languageCode = prefString("language_code", "fa");
        if (!translationRoot.has(languageCode)) languageCode = "fa";
        glass = prefBool("glass", true);
        animations = prefBool("animations", true);
        haptics = prefBool("haptics", true);
        autoReveal = prefBool("auto_reveal", false);
        showProgress = prefBool("show_progress", true);
        showTimer = prefBool("show_timer", true);
        showXp = prefBool("show_xp", true);
        confirmExit = prefBool("confirm_exit", true);
        compactSettings = prefBool("compact_settings", false);
        musicEnabled = prefBool("music_enabled", false);
        glassOpacity = Math.max(0.30, Math.min(0.90, prefDouble("glass_opacity", 0.62)));
        musicVolume = Math.max(0, Math.min(1, prefDouble("music_volume", 0.35)));
        dailyGoal = Math.max(5, Math.min(100, prefInt("daily_goal", 20)));
        musicTrack = prefString("music_track", "lofi_night");
        if (!Arrays.asList("lofi_night", "rainy_focus", "deep_focus").contains(musicTrack)) musicTrack = "lofi_night";
        xp = Math.max(0, prefInt("xp", 0));
        streak = Math.max(0, prefInt("streak", 0));
        lastStudyDay = prefString("last_study_day", "");
        lastRewardDay = prefString("last_reward_day", "");
        Set<String> days = prefs.getStringSet("flutter.review_days", null);
        if (days != null) {
            reviewDays.clear();
            reviewDays.addAll(days);
            Collections.sort(reviewDays);
        }
        updateTheme();
    }

    private String prefString(String key, String fallback) {
        Object value = prefs.getAll().get("flutter." + key);
        return value == null ? fallback : String.valueOf(value);
    }
    private int prefInt(String key, int fallback) {
        Object value = prefs.getAll().get("flutter." + key);
        try { return value == null ? fallback : (value instanceof Number ? ((Number)value).intValue() : Integer.parseInt(String.valueOf(value))); }
        catch (Exception e) { return fallback; }
    }
    private double prefDouble(String key, double fallback) {
        Object value = prefs.getAll().get("flutter." + key);
        try { return value == null ? fallback : (value instanceof Number ? ((Number)value).doubleValue() : Double.parseDouble(String.valueOf(value))); }
        catch (Exception e) { return fallback; }
    }
    private boolean prefBool(String key, boolean fallback) {
        Object value = prefs.getAll().get("flutter." + key);
        return value == null ? fallback : (value instanceof Boolean ? ((Boolean)value).booleanValue() : Boolean.parseBoolean(String.valueOf(value)));
    }
    private void putString(String key, String value) { prefs.edit().putString("flutter." + key, value).apply(); }
    private void putInt(String key, int value) { prefs.edit().putInt("flutter." + key, value).apply(); }
    private void putDouble(String key, double value) { prefs.edit().putString("flutter." + key, String.valueOf(value)).apply(); }
    private void putBool(String key, boolean value) { prefs.edit().putBoolean("flutter." + key, value).apply(); }

    private void loadData() {
        try {
            String raw = prefs.getString(DATA_KEY, null);
            if (raw == null || raw.length() == 0) raw = getSharedPreferences("parin_native_legacy", MODE_PRIVATE).getString("decks", null);
            if (raw != null) decks = new JSONArray(raw);
        } catch (Exception ignored) { decks = new JSONArray(); }
        if (decks.length() == 0) {
            JSONObject deck = newDeckObject("شروع سریع", "کارت‌های نمونه");
            try {
                deck.getJSONArray("cards").put(newCardObject("Leitner چیست؟", "یک روش مرور فاصله‌دار برای انتقال کارت‌ها بین خانه‌ها."));
                deck.getJSONArray("cards").put(newCardObject("Flutter چیست؟", "فریم‌ورک ساخت رابط کاربری چندسکویی با Dart."));
                decks.put(deck);
            } catch (Exception ignored) {}
            saveData();
        }
    }

    private void saveData() {
        String value = decks.toString();
        prefs.edit().putString(DATA_KEY, value).apply();
        getSharedPreferences("parin_native_legacy", MODE_PRIVATE).edit().putString("decks", value).apply();
    }

    private void saveSetting(String key, String value) { putString(key, value); }
    private void putJson(JSONObject object, String key, Object value) {
        try { object.put(key, value); } catch (JSONException e) { throw new RuntimeException(e); }
    }
    private void updateTheme() {
        if (themes == null || themes.length() == 0) return;
        themeIndex = Math.max(0, Math.min(themes.length() - 1, themeIndex));
        currentTheme = themes.optJSONObject(themeIndex);
        if (currentTheme == null) currentTheme = new JSONObject();
    }

    private String t(String key) {
        JSONObject map = translationRoot.optJSONObject(languageCode);
        if (map == null) map = translationRoot.optJSONObject("en");
        String value = map == null ? null : map.optString(key, null);
        if (value == null || value.length() == 0 || "null".equals(value)) {
            JSONObject en = translationRoot.optJSONObject("en");
            value = en == null ? key : en.optString(key, key);
        }
        return value == null ? key : value;
    }

    private boolean rtl() { return "fa".equals(languageCode) || "ar".equals(languageCode) || "he".equals(languageCode); }
    private int primary() { return colorFromTheme("primary", 0xff3f51b5); }
    private int secondary() { return colorFromTheme("secondary", 0xff64b5f6); }
    private int colorFromTheme(String key, int fallback) {
        try { return (int) currentTheme.getLong(key); } catch (Exception e) { return fallback; }
    }
    private int background() {
        if ("amoled".equals(appearanceMode)) return Color.BLACK;
        if ("dark".equals(appearanceMode)) return 0xff101114;
        if ("aero".equals(appearanceMode)) return 0xffeaf0fa;
        return colorFromTheme("background", 0xffeff3ff);
    }
    private int surface() {
        if ("amoled".equals(appearanceMode)) return Color.BLACK;
        if ("dark".equals(appearanceMode)) return 0xff181a1f;
        if ("aero".equals(appearanceMode)) return blend(Color.WHITE, primary(), (float)(1.0 - glassOpacity) * 0.08f);
        return Color.WHITE;
    }
    private int textColor() { return ("dark".equals(appearanceMode) || "amoled".equals(appearanceMode)) ? Color.WHITE : 0xff202124; }
    private int mutedColor() { return ("dark".equals(appearanceMode) || "amoled".equals(appearanceMode)) ? 0xffc4c8d0 : 0xff5e6675; }
    private int blend(int first, int second, float ratio) {
        ratio = Math.max(0, Math.min(1, ratio));
        int a = (int)(Color.alpha(first) * (1-ratio) + Color.alpha(second) * ratio);
        int r = (int)(Color.red(first) * (1-ratio) + Color.red(second) * ratio);
        int g = (int)(Color.green(first) * (1-ratio) + Color.green(second) * ratio);
        int b = (int)(Color.blue(first) * (1-ratio) + Color.blue(second) * ratio);
        return Color.argb(a, r, g, b);
    }

    private int dp(float value) { return (int)(getResources().getDisplayMetrics().density * value + 0.5f); }
    private GradientDrawable rounded(int color, int radius, int stroke) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color); d.setCornerRadius(dp(radius));
        if (stroke != 0) d.setStroke(dp(1), stroke);
        return d;
    }
    private LinearLayout vertical() { LinearLayout l = new LinearLayout(this); l.setOrientation(LinearLayout.VERTICAL); return l; }
    private LinearLayout horizontal() { LinearLayout l = new LinearLayout(this); l.setOrientation(LinearLayout.HORIZONTAL); l.setGravity(Gravity.CENTER_VERTICAL); return l; }
    private LinearLayout.LayoutParams lp(int width, int height) { return new LinearLayout.LayoutParams(width < 0 ? width : dp(width), height < 0 ? height : dp(height)); }
    private void space(LinearLayout into, int height) { View v = new View(this); into.addView(v, lp(1, height)); }
    private TextView label(String value, int size, boolean bold) {
        TextView v = new TextView(this);
        v.setText(value == null ? "" : value); v.setTextSize(size); v.setTextColor(textColor());
        if (bold) v.setTypeface(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD);
        v.setGravity(rtl() ? Gravity.RIGHT : Gravity.LEFT);
        v.setPadding(dp(2), dp(3), dp(2), dp(3));
        return v;
    }
    private Button button(String value, final Runnable action) {
        Button b = new Button(this); b.setText(value); b.setTextSize(14); b.setAllCaps(false);
        b.setTextColor(Color.WHITE); b.setPadding(dp(10), dp(6), dp(10), dp(6));
        b.setBackgroundDrawable(rounded(primary(), 7, 0));
        if (action != null) b.setOnClickListener(v -> action.run());
        return b;
    }
    private Button secondaryButton(String value, final Runnable action) {
        Button b = new Button(this); b.setText(value); b.setTextSize(14); b.setAllCaps(false);
        b.setTextColor(textColor()); b.setPadding(dp(10), dp(6), dp(10), dp(6));
        b.setBackgroundDrawable(rounded(surface(), 7, blend(primary(), surface(), 0.65f)));
        if (action != null) b.setOnClickListener(v -> action.run());
        return b;
    }
    private LinearLayout panel() {
        LinearLayout p = vertical(); p.setPadding(dp(14), dp(12), dp(14), dp(12));
        int surfaceColor = surface();
        if ("aero".equals(appearanceMode) && glass) surfaceColor = blend(surfaceColor, Color.WHITE, (float)(glassOpacity * 0.12));
        p.setBackgroundDrawable(rounded(surfaceColor, "aero".equals(appearanceMode) ? 12 : 5, blend(primary(), background(), 0.86f)));
        return p;
    }
    private void addButton(LinearLayout into, String title, Runnable action) {
        Button b = button(title, action); LinearLayout.LayoutParams p = lp(-1, -2); p.topMargin = dp(5); p.bottomMargin = dp(4); into.addView(b, p);
    }
    private void addSecondaryButton(LinearLayout into, String title, Runnable action) {
        Button b = secondaryButton(title, action); LinearLayout.LayoutParams p = lp(-1, -2); p.topMargin = dp(4); p.bottomMargin = dp(4); into.addView(b, p);
    }
    private EditText edit(String hint, String value, int lines) {
        EditText e = new EditText(this); e.setTextColor(textColor()); e.setHintTextColor(mutedColor()); e.setHint(hint);
        e.setText(value == null ? "" : value); e.setTextSize(16); e.setPadding(dp(10), dp(8), dp(10), dp(8));
        e.setSingleLine(lines == 1); if (lines > 1) e.setMinLines(lines); e.setBackgroundDrawable(rounded(surface(), 5, blend(primary(), background(), 0.65f)));
        return e;
    }
    private void addPanel(LinearLayout into, View child) {
        LinearLayout p = panel(); p.addView(child, lp(-1, -2));
        LinearLayout.LayoutParams pp = lp(-1, -2); pp.bottomMargin = dp(10); into.addView(p, pp);
    }

    private void page(String title, boolean home, Runnable back) {
        backAction = back == null ? new Runnable() { public void run() { showHome(); } } : back;
        root = vertical(); root.setBackgroundColor(background());
        LinearLayout bar = horizontal(); bar.setPadding(dp(5), dp(4), dp(5), dp(4)); bar.setBackgroundColor(primary());
        if (!home) {
            Button b = button("‹", () -> backAction.run()); b.setTextSize(23); b.setBackgroundDrawable(rounded(primary(), 3, 0)); bar.addView(b, lp(52, 48));
        }
        TextView titleView = label(title, 19, true); titleView.setTextColor(Color.WHITE);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, dp(48), 1); titleView.setGravity(rtl() ? Gravity.RIGHT | Gravity.CENTER_VERTICAL : Gravity.LEFT | Gravity.CENTER_VERTICAL); bar.addView(titleView, titleParams);
        if (home) {
            Button imp = button("↓", () -> chooseImport()); imp.setBackgroundDrawable(rounded(primary(), 2, 0)); bar.addView(imp, lp(42, 46));
            Button exp = button("↑", () -> exportBackup()); exp.setBackgroundDrawable(rounded(primary(), 2, 0)); bar.addView(exp, lp(42, 46));
            Button set = button("⚙", () -> showSettings()); set.setBackgroundDrawable(rounded(primary(), 2, 0)); bar.addView(set, lp(42, 46));
        }
        root.addView(bar, lp(-1, 56));
        ScrollView scroll = new ScrollView(this); scroll.setFillViewport(true);
        body = vertical(); body.setPadding(dp(14), dp(14), dp(14), dp(24)); scroll.addView(body);
        root.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));
        setContentView(root);
        if (animations) { AlphaAnimation a = new AlphaAnimation(0.0f, 1.0f); a.setDuration(160); root.startAnimation(a); }
    }

    private JSONObject newDeckObject(String name, String description) {
        JSONObject d = new JSONObject();
        try {
            d.put("id", uid()); d.put("name", name); d.put("description", description); d.put("color", "3F51B5");
            JSONArray boxes = new JSONArray();
            String[] names = {"خانه ۱", "خانه ۲", "خانه ۳", "خانه ۴", "خانه ۵"};
            int[] colors = {0xff7c6cff,0xff4c8dff,0xff26a69a,0xffffa726,0xffef5350};
            for (int i=0;i<5;i++) { JSONObject b = new JSONObject(); b.put("id", "b"+(i+1)); b.put("name", names[i]); b.put("color", colors[i]); boxes.put(b); }
            d.put("boxes", boxes); d.put("cards", new JSONArray());
        } catch (Exception ignored) {}
        return d;
    }

    private JSONObject newCardObject(String front, String back) {
        JSONObject c = new JSONObject();
        try {
            c.put("id", uid()); c.put("front", front); c.put("back", back); c.put("tags", ""); c.put("box", 0);
            c.put("due", iso(new Date())); c.put("favorite", false); c.put("reviews", 0); c.put("lapses", 0);
            c.put("frontImage", JSONObject.NULL); c.put("backImage", JSONObject.NULL);
        } catch (Exception ignored) {}
        return c;
    }

    private String uid() { return String.valueOf(System.currentTimeMillis()) + "_" + new Random().nextInt(999999); }
    private String iso(Date date) {
        SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US);
        f.setTimeZone(TimeZone.getDefault()); return f.format(date);
    }
    private Date dateFrom(Object value) {
        if (value == null || value == JSONObject.NULL) return new Date(0);
        String raw = String.valueOf(value);
        try {
            SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US); f.setLenient(true);
            return f.parse(raw);
        } catch (Exception ignored) {
            try { SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US); return f.parse(raw); } catch (Exception e) { return new Date(); }
        }
    }
    private boolean due(JSONObject card) { return !dateFrom(card.opt("due")).after(new Date()); }
    private int dueCount(JSONObject deck) {
        int count=0; JSONArray cards=deck.optJSONArray("cards"); if(cards==null)return 0;
        for(int i=0;i<cards.length();i++) if(due(cards.optJSONObject(i))) count++;
        return count;
    }
    private int totalCards() {
        int total=0; for(int i=0;i<decks.length();i++) { JSONObject d=decks.optJSONObject(i); if(d!=null) total += d.optJSONArray("cards")==null?0:d.optJSONArray("cards").length(); } return total;
    }
    private String safeName(JSONObject deck) { return deck.optString("name", t("new_deck")); }

    private void showHome() {
        page("Parin Litner", true, null);
        int total = totalCards(), due = 0;
        for(int i=0;i<decks.length();i++) due += dueCount(decks.optJSONObject(i));
        LinearLayout progressPanel = panel();
        TextView ready = label(due > 0 ? t("cards_ready") : t("ready"), 20, true); progressPanel.addView(ready);
        space(progressPanel, 8);
        ProgressBar progress = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        progress.setMax(Math.max(1,dailyGoal)); progress.setProgress(Math.min(dailyGoal,due)); progressPanel.addView(progress, lp(-1, 12));
        space(progressPanel, 6);
        progressPanel.addView(label(due + " / " + dailyGoal + " • " + total + " " + t("cards_count"), 14, false));
        addPanel(body, progressPanel);

        LinearLayout stats = horizontal();
        LinearLayout first = panel(); first.addView(label(t("cards"),13,false)); first.addView(label(String.valueOf(total),23,true));
        LinearLayout second = panel(); second.addView(label(t("today"),13,false)); second.addView(label(String.valueOf(due),23,true));
        LinearLayout.LayoutParams half = new LinearLayout.LayoutParams(0,-2,1); half.rightMargin=dp(5); stats.addView(first,half);
        LinearLayout.LayoutParams half2 = new LinearLayout.LayoutParams(0,-2,1); half2.leftMargin=dp(5); stats.addView(second,half2); body.addView(stats,lp(-1,-2));
        space(body, 8);
        addButton(body, t("focus_mode") + "  •  " + t("focus_sub"), () -> showFocus());
        addButton(body, t("smart_mix"), () -> startSmartMix());
        addButton(body, t("achievement_center"), () -> showAchievements());
        space(body, 8);
        TextView deckHeader = label(t("decks") + " (" + decks.length() + ")", 21, true); body.addView(deckHeader);
        space(body,5);
        addButton(body, "+  " + t("new_deck"), () -> createDeck());
        if (decks.length()==0) body.addView(label(t("no_cards"),16,false));
        for (int i=0;i<decks.length();i++) {
            final JSONObject d=decks.optJSONObject(i);
            if(d==null) continue;
            LinearLayout p=panel();
            TextView name=label(safeName(d),18,true); p.addView(name);
            String desc=d.optString("description","");
            if(desc.length()>0) p.addView(label(desc,13,false));
            p.addView(label(d.optJSONArray("cards")==null? "0":String.valueOf(d.optJSONArray("cards").length())+" "+t("cards_count")+" • "+dueCount(d)+" "+t("ready_count"),13,false));
            addSecondaryButton(p,t("study"),()->showDeck(d));
            LinearLayout.LayoutParams pp=lp(-1,-2); pp.bottomMargin=dp(9); body.addView(p,pp);
        }
        space(body, 6);
        addSecondaryButton(body, t("about"), () -> showAbout());
    }

    private void createDeck() {
        final EditText input=edit(t("new_deck_hint"),"",1);
        new AlertDialog.Builder(this).setTitle(t("new_deck")).setView(input)
          .setNegativeButton(t("cancel"),null).setPositiveButton(t("build"),(d,w)->{
             String name=input.getText().toString().trim(); if(name.length()==0)return;
             decks.put(newDeckObject(name,"")); saveData(); showHome();
          }).show();
    }

    private void showDeck(final JSONObject deck) {
        page(safeName(deck), false, () -> showHome());
        addButton(body, "+  " + t("new_card"), () -> editCard(deck,null));
        addButton(body, t("study_type") + " • " + t("all"), () -> startStudy(deck,"all"));
        addButton(body, t("study") + " • " + t("cards_ready"), () -> startStudy(deck,"due"));
        addButton(body, t("favorite_only"), () -> startStudy(deck,"favorite"));
        addSecondaryButton(body,t("rename"),()->renameDeck(deck));
        addSecondaryButton(body,t("delete"),()->deleteDeck(deck));
        addButton(body,t("boxes"),()->manageBoxes(deck));
        final EditText search=edit(t("search"),"",1);
        LinearLayout searchRow=horizontal(); searchRow.addView(search,new LinearLayout.LayoutParams(0,dp(46),1));
        Button go=secondaryButton(t("search"),null); searchRow.addView(go,lp(90,46)); body.addView(searchRow,lp(-1,-2));
        final LinearLayout list=vertical(); body.addView(list,lp(-1,-2));
        Runnable fill=()->{
            list.removeAllViews();
            JSONArray cards=deck.optJSONArray("cards"); if(cards==null)return;
            String q=search.getText().toString().trim().toLowerCase(Locale.ROOT);
            for(int i=0;i<cards.length();i++) {
                final JSONObject card=cards.optJSONObject(i); if(card==null)continue;
                String content=card.optString("front","")+" "+card.optString("back","")+" "+card.optString("tags","");
                if(q.length()>0 && !content.toLowerCase(Locale.ROOT).contains(q))continue;
                LinearLayout p=panel(); TextView head=label(card.optString("front",""),17,true); p.addView(head);
                TextView back=label(card.optString("back",""),14,false); p.addView(back);
                p.addView(label(card.optString("tags",""),12,false));
                p.addView(label(t("box")+" "+(card.optInt("box",0)+1)+" • "+(due(card)?t("ready_count"):t("done")),12,false));
                addSecondaryButton(p,card.optBoolean("favorite",false)?"★":"☆",()->{
                    putJson(card,"favorite",!card.optBoolean("favorite",false)); saveData(); fill.run();
                });
                addSecondaryButton(p,t("edit_card"),()->editCard(deck,card));
                LinearLayout.LayoutParams pp=lp(-1,-2); pp.bottomMargin=dp(7); list.addView(p,pp);
            }
        };
        go.setOnClickListener(v->fill.run()); search.setOnEditorActionListener((v,id,event)->{if(id==EditorInfo.IME_ACTION_SEARCH){fill.run();return true;}return false;});
        fill.run();
    }

    private void renameDeck(final JSONObject deck) {
        final EditText input=edit(t("new_deck_hint"),deck.optString("name",""),1);
        new AlertDialog.Builder(this).setTitle(t("rename")).setView(input).setNegativeButton(t("cancel"),null)
          .setPositiveButton(t("save"),(d,w)->{String name=input.getText().toString().trim();if(name.length()>0)putJson(deck,"name",name);saveData();showDeck(deck);}).show();
    }
    private void deleteDeck(final JSONObject deck) {
        new AlertDialog.Builder(this).setTitle(t("delete")).setMessage(t("delete_deck_confirm"))
          .setNegativeButton(t("cancel"),null).setPositiveButton(t("delete"),(d,w)->{
              JSONArray newList=new JSONArray();
              for(int i=0;i<decks.length();i++){JSONObject x=decks.optJSONObject(i);if(x!=deck && !x.optString("id").equals(deck.optString("id")))newList.put(x);}
              decks=newList;saveData();showHome();
          }).show();
    }

    private void manageBoxes(final JSONObject deck) {
        final JSONArray boxes=deck.optJSONArray("boxes");
        if(boxes==null || boxes.length()==0){toast(t("boxes"));return;}
        final String[] names=new String[boxes.length()];
        for(int i=0;i<boxes.length();i++) names[i]=boxes.optJSONObject(i).optString("name","Box "+(i+1));
        new AlertDialog.Builder(this).setTitle(t("boxes")).setItems(names,(dialog,which)->{
            JSONObject box=boxes.optJSONObject(which); final EditText input=edit(t("box"),box.optString("name",""),1);
            new AlertDialog.Builder(this).setTitle(t("rename")).setView(input).setNegativeButton(t("cancel"),null)
             .setPositiveButton(t("save"),(d,w)->{String name=input.getText().toString().trim();if(name.length()>0)putJson(box,"name",name);saveData();showDeck(deck);}).show();
        }).setNegativeButton(t("cancel"),null).show();
    }

    private void editCard(final JSONObject deck, final JSONObject card) {
        editorDeck=deck; editorCard=card;
        frontImage=card==null?null:nullableString(card.opt("frontImage"));
        backImage=card==null?null:nullableString(card.opt("backImage"));
        page(card==null?t("new_card"):t("edit_card"),false,()->showDeck(deck));
        frontField=edit(t("card_front"),card==null?"":card.optString("front",""),4);
        backField=edit(t("card_back"),card==null?"":card.optString("back",""),5);
        tagsField=edit(t("tags"),card==null?"":card.optString("tags",""),1);
        body.addView(label(t("card_front"),15,true)); body.addView(frontField,lp(-1,-2));
        addSecondaryButton(body,t("front_image") + (frontImage==null?" • +":" • ✓"),()->pickImage(1));
        body.addView(label(t("card_back"),15,true)); body.addView(backField,lp(-1,-2));
        addSecondaryButton(body,t("back_image") + (backImage==null?" • +":" • ✓"),()->pickImage(2));
        body.addView(label(t("tags"),15,true)); body.addView(tagsField,lp(-1,-2));
        space(body,7);
        int currentBox=card==null?0:card.optInt("box",0);
        JSONArray boxes=deck.optJSONArray("boxes"); final ArrayList<String> boxNames=new ArrayList<String>();
        if(boxes!=null)for(int i=0;i<boxes.length();i++)boxNames.add(boxes.optJSONObject(i).optString("name","Box "+(i+1)));
        if(boxNames.size()==0)boxNames.add("Box 1");
        Spinner spinner=new Spinner(this);
        ArrayAdapter<String> adapter=new ArrayAdapter<String>(this,android.R.layout.simple_spinner_item,boxNames);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item); spinner.setAdapter(adapter); spinner.setSelection(Math.max(0,Math.min(currentBox,boxNames.size()-1)));
        body.addView(label(t("box"),15,true)); body.addView(spinner,lp(-1,48));
        if(card!=null) addSecondaryButton(body,t("delete"),()->{
            new AlertDialog.Builder(this).setTitle(t("delete_card")).setMessage(t("delete_card_confirm"))
             .setNegativeButton(t("cancel"),null).setPositiveButton(t("delete"),(d,w)->{
                JSONArray arr=deck.optJSONArray("cards"), next=new JSONArray();
                if(arr!=null)for(int i=0;i<arr.length();i++){JSONObject c=arr.optJSONObject(i);if(c!=card && !c.optString("id").equals(card.optString("id")))next.put(c);}
                putJson(deck,"cards",next);saveData();showDeck(deck);
             }).show();
        });
        addButton(body,t("save_card"),()->{
            String front=frontField.getText().toString().trim(), back=backField.getText().toString().trim();
            if(front.length()==0 && frontImage==null || back.length()==0 && backImage==null){toast(t("save_card"));return;}
            JSONObject c=card==null?newCardObject("",""):card;
            putJson(c,"front",front);putJson(c,"back",back);putJson(c,"tags",tagsField.getText().toString().trim());
            putJson(c,"box",spinner.getSelectedItemPosition());
            putJson(c,"frontImage",frontImage==null?JSONObject.NULL:frontImage);
            putJson(c,"backImage",backImage==null?JSONObject.NULL:backImage);
            if(card==null){JSONArray arr=deck.optJSONArray("cards");if(arr==null){arr=new JSONArray();putJson(deck,"cards",arr);}arr.put(0,c);}
            saveData();showDeck(deck);
        });
    }

    private String nullableString(Object value) { return value==null||value==JSONObject.NULL?null:String.valueOf(value); }
    private void pickImage(int side) {
        imageSelectionSide=side;
        try { Intent i=new Intent(Intent.ACTION_GET_CONTENT); i.setType("image/*"); startActivityForResult(Intent.createChooser(i,t("add_image")),REQ_IMAGE); }
        catch(Exception e){toast(t("image_error"));}
    }
    private void cacheEditorFields() {}
    @Override protected void onActivityResult(int requestCode,int resultCode,Intent data) {
        super.onActivityResult(requestCode,resultCode,data);
        if(resultCode!=RESULT_OK||data==null||data.getData()==null)return;
        Uri uri=data.getData();
        if(requestCode==REQ_IMAGE) {
            try {
                InputStream in=getContentResolver().openInputStream(uri);
                byte[] bytes=readAll(in);in.close();
                if(bytes.length==0)return;
                String encoded=Base64.encodeToString(bytes,Base64.NO_WRAP);
                if(imageSelectionSide==1)frontImage=encoded;else if(imageSelectionSide==2)backImage=encoded;
                renderEditorAgain();
            } catch(Exception e){toast(t("image_error"));}
        } else if(requestCode==REQ_IMPORT) {
            try {
                InputStream in=getContentResolver().openInputStream(uri);byte[] bytes=readAll(in);in.close();
                importBytes(bytes);
            } catch(Exception e){toast(t("backup_invalid"));}
        }
    }
    private void renderEditorAgain() {
        if(editorDeck==null)return;
        String f=frontField==null?"":frontField.getText().toString();
        String b=backField==null?"":backField.getText().toString();
        String tags=tagsField==null?"":tagsField.getText().toString();
        JSONObject old=editorCard;
        // Reconstruct page and restore the user's unsaved text after returning from image picker.
        editCard(editorDeck,old);
        frontField.setText(f);backField.setText(b);tagsField.setText(tags);
        toast(imageSelectionSide==1?t("front_image"):t("back_image"));
    }

    private void startStudy(JSONObject deck,String mode) {
        studyItems.clear();
        if(deck!=null) {
            JSONArray cards=deck.optJSONArray("cards");if(cards!=null)for(int i=0;i<cards.length();i++){
                JSONObject c=cards.optJSONObject(i);if(c==null)continue;
                if("due".equals(mode)&&!due(c))continue;
                if("favorite".equals(mode)&&!c.optBoolean("favorite",false))continue;
                studyItems.add(new StudyItem(deck,c));
            }
        } else {
            for(int i=0;i<decks.length();i++) {
                JSONObject d=decks.optJSONObject(i);if(d==null)continue;
                JSONArray cards=d.optJSONArray("cards");if(cards==null)continue;
                for(int j=0;j<cards.length();j++){JSONObject c=cards.optJSONObject(j);if(c!=null&&due(c))studyItems.add(new StudyItem(d,c));}
            }
            Collections.shuffle(studyItems);
        }
        if(studyItems.size()==0){new AlertDialog.Builder(this).setMessage(t("no_review")).setPositiveButton(t("great"),null).show();return;}
        studyIndex=0;answerRevealed=false;studyFinished=false;studyStartedAt=System.currentTimeMillis();studyElapsedSeconds=0;
        showStudy();
    }

    private void startSmartMix() { startStudy(null,"due"); }

    private void showStudy() {
        if(studyItems.size()==0||studyIndex>=studyItems.size()){showHome();return;}
        final StudyItem item=studyItems.get(studyIndex);
        page(t("study"),false,()->leaveStudy());
        body.addView(label((studyIndex+1)+" / "+studyItems.size(),14,true));
        ProgressBar progress=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);progress.setMax(studyItems.size());progress.setProgress(studyIndex);body.addView(progress,lp(-1,9));
        LinearLayout cardPanel=panel();cardPanel.setMinimumHeight(dp(290));
        cardPanel.setGravity(Gravity.CENTER);
        TextView front=label(item.card.optString("front",""),23,true);front.setGravity(Gravity.CENTER);
        cardPanel.addView(front,lp(-1,-2));
        addImagePreview(cardPanel,item.card.opt("frontImage"),170);
        if(answerRevealed) {
            TextView line=label("────────",12,false);line.setGravity(Gravity.CENTER);cardPanel.addView(line);
            TextView back=label(item.card.optString("back",""),21,false);back.setGravity(Gravity.CENTER);cardPanel.addView(back,lp(-1,-2));
            addImagePreview(cardPanel,item.card.opt("backImage"),170);
        }
        addPanel(body,cardPanel);
        if(!answerRevealed) {
            addButton(body,t("show_answer"),()->{answerRevealed=true;showStudy();});
        } else {
            addSecondaryButton(body,t("again"),()->rateCard(0));
            addSecondaryButton(body,t("hard"),()->rateCard(1));
            addButton(body,t("good"),()->rateCard(2));
            addSecondaryButton(body,t("easy"),()->rateCard(3));
        }
        if(showTimer) {
            studyTimerView=label(t("timer")+" • "+formatDuration((System.currentTimeMillis()-studyStartedAt)/1000),13,false);
            body.addView(studyTimerView);
            handler.removeCallbacks(studyTick);
            handler.postDelayed(studyTick,1000);
        } else {
            studyTimerView=null;
            handler.removeCallbacks(studyTick);
        }
        addSecondaryButton(body,t("confirm_exit"),()->leaveStudy());
    }

    private void addImagePreview(LinearLayout into,Object raw,int height) {
        String data=nullableString(raw);if(data==null)return;
        try {
            byte[] bytes=Base64.decode(data,Base64.DEFAULT);Bitmap bmp=BitmapFactory.decodeByteArray(bytes,0,bytes.length);
            if(bmp!=null){ImageView image=new ImageView(this);image.setImageBitmap(bmp);image.setAdjustViewBounds(true);image.setScaleType(ImageView.ScaleType.FIT_CENTER);into.addView(image,lp(-1,height));}
        } catch(Exception ignored) {}
    }

    private void rateCard(int rating) {
        if(!answerRevealed||studyFinished||studyIndex>=studyItems.size())return;
        StudyItem item=studyItems.get(studyIndex);JSONObject card=item.card;
        int lastBox=Math.max(0,(item.deck.optJSONArray("boxes")==null?1:item.deck.optJSONArray("boxes").length())-1);
        long now=System.currentTimeMillis();int box=Math.max(0,Math.min(lastBox,card.optInt("box",0)));
        putJson(card,"reviews",card.optInt("reviews",0)+1);
        if(rating==0){putJson(card,"lapses",card.optInt("lapses",0)+1);putJson(card,"box",0);putJson(card,"due",iso(new Date(now+10*60*1000L)));}
        else if(rating==1){putJson(card,"box",box);putJson(card,"due",iso(new Date(now+24*60*60*1000L)));}
        else if(rating==2){box=Math.min(lastBox,box+1);int[] days={1,2,4,7,14,30};putJson(card,"box",box);putJson(card,"due",iso(new Date(now+days[Math.min(box,5)]*86400000L)));}
        else {box=Math.min(lastBox,box+2);int[] days={2,4,7,14,30,60};putJson(card,"box",box);putJson(card,"due",iso(new Date(now+days[Math.min(box,5)]*86400000L)));}
        saveData();recordReview();vibrate();
        if(studyIndex==studyItems.size()-1){studyFinished=true;showStudyComplete();return;}
        studyIndex++;answerRevealed=false;showStudy();
        if(autoReveal){handler.postDelayed(()->{if(!studyFinished){answerRevealed=true;showStudy();}},320);}
    }

    private void recordReview() {
        String today=dayKey(new Date()), yesterday=dayKey(new Date(System.currentTimeMillis()-86400000L));
        xp+=12;
        if(today.equals(lastStudyDay)) { /* same-day review does not extend streak */ }
        else if(yesterday.equals(lastStudyDay)) streak+=1; else streak=1;
        lastStudyDay=today;reviewDays.add(today);
        while(reviewDays.size()>300)reviewDays.remove(0);
        putInt("xp",xp);putInt("streak",streak);putString("last_study_day",lastStudyDay);
        HashSet<String> days=new HashSet<String>(reviewDays);prefs.edit().putStringSet("flutter.review_days",days).apply();
    }
    private String dayKey(Date date) { return new SimpleDateFormat("yyyy-MM-dd",Locale.US).format(date); }
    private String formatDuration(long seconds) { return String.format(Locale.US,"%02d:%02d",seconds/60,seconds%60); }
    private void showStudyComplete() {
        handler.removeCallbacks(studyTick); studyTimerView=null;
        long seconds=(System.currentTimeMillis()-studyStartedAt)/1000;
        new AlertDialog.Builder(this).setTitle(t("done")).setMessage(studyItems.size()+" "+t("cards_count")+"\n"+formatDuration(seconds))
          .setPositiveButton(t("great"),(d,w)->{studyFinished=true;showHome();}).setOnCancelListener(d->{studyFinished=true;showHome();}).show();
    }
    private void leaveStudy() {
        if(!confirmExit||studyFinished){studyFinished=true;handler.removeCallbacks(studyTick);studyTimerView=null;showHome();return;}
        new AlertDialog.Builder(this).setTitle(t("confirm_exit")).setMessage(t("confirm_exit_sub"))
          .setNegativeButton(t("cancel"),null).setPositiveButton(t("close"),(d,w)->{studyFinished=true;handler.removeCallbacks(studyTick);studyTimerView=null;showHome();}).show();
    }
    private void vibrate() {
        if(!haptics)return;
        try { Vibrator v=(Vibrator)getSystemService(VIBRATOR_SERVICE);if(v!=null&&v.hasVibrator())v.vibrate(25); } catch(Exception ignored) {}
    }

    private void showSettings() {
        page(t("settings"),false,()->showHome());
        addButton(body,t("language")+" • "+languageCode,()->chooseLanguage());
        addButton(body,t("theme")+" • "+(themeIndex+1)+"/"+Math.max(1,themes.length()),()->chooseTheme());
        addButton(body,t("appearance")+" • "+appearanceMode,()->chooseAppearance());
        addCheck(body,"glass","glass",glass);
        addCheck(body,"animations","animations",animations);
        addCheck(body,"haptics","haptics",haptics);
        addCheck(body,"auto_reveal","auto_reveal",autoReveal);
        addCheck(body,"show_progress","progress",showProgress);
        addCheck(body,"show_timer","timer",showTimer);
        addCheck(body,"show_xp","show_xp",showXp);
        addCheck(body,"confirm_exit","confirm_exit",confirmExit);
        addCheck(body,"compact_settings","compact_settings",compactSettings);
        addCheck(body,"music_enabled","music_study",musicEnabled);
        body.addView(label(t("glass_opacity")+" • "+Math.round(glassOpacity*100)+"%",14,true));
        SeekBar opacity=new SeekBar(this);opacity.setMax(60);opacity.setProgress((int)((glassOpacity-.30)*100));body.addView(opacity,lp(-1,44));
        opacity.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){
            public void onProgressChanged(SeekBar s,int p,boolean user){if(user){glassOpacity=Math.max(.30,Math.min(.90,.30+p/100.0));putDouble("glass_opacity",glassOpacity);}}
            public void onStartTrackingTouch(SeekBar s){} public void onStopTrackingTouch(SeekBar s){}
        });
        body.addView(label(t("daily_goal")+" • "+dailyGoal,14,true));
        SeekBar goal=new SeekBar(this);goal.setMax(95);goal.setProgress(dailyGoal-5);body.addView(goal,lp(-1,44));
        goal.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){public void onProgressChanged(SeekBar s,int p,boolean user){dailyGoal=p+5;if(user)putInt("daily_goal",dailyGoal);}public void onStartTrackingTouch(SeekBar s){}public void onStopTrackingTouch(SeekBar s){}});
        body.addView(label(t("music")+" • "+musicTrack,14,true));
        addSecondaryButton(body,"Lo-fi Night",()->selectTrack("lofi_night"));
        addSecondaryButton(body,"Rainy Focus",()->selectTrack("rainy_focus"));
        addSecondaryButton(body,"Deep Focus",()->selectTrack("deep_focus"));
        body.addView(label(t("music_volume")+" • "+Math.round(musicVolume*100)+"%",14,true));
        SeekBar volume=new SeekBar(this);volume.setMax(100);volume.setProgress((int)(musicVolume*100));body.addView(volume,lp(-1,44));
        volume.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){public void onProgressChanged(SeekBar s,int p,boolean user){if(user){musicVolume=p/100.0;putDouble("music_volume",musicVolume);if(player!=null)player.setVolume((float)musicVolume,(float)musicVolume);}}public void onStartTrackingTouch(SeekBar s){}public void onStopTrackingTouch(SeekBar s){}});
        addButton(body,t("backup")+" • "+t("export"),()->exportBackup());
        addSecondaryButton(body,t("import"),()->chooseImport());
        addSecondaryButton(body,t("achievement_center"),()->showAchievements());
        addSecondaryButton(body,t("about"),()->showAbout());
    }

    private void addCheck(LinearLayout into, final String key, String titleKey, boolean value) {
        CheckBox c=new CheckBox(this); c.setText(t(titleKey));c.setTextColor(textColor());c.setTextSize(15);c.setChecked(value);int pad=compactSettings?1:5;c.setPadding(dp(5),dp(pad),dp(5),dp(pad));
        c.setOnCheckedChangeListener((button,checked)->{
            if("glass".equals(key))glass=checked;
            else if("animations".equals(key))animations=checked;
            else if("haptics".equals(key))haptics=checked;
            else if("auto_reveal".equals(key))autoReveal=checked;
            else if("show_progress".equals(key))showProgress=checked;
            else if("show_timer".equals(key))showTimer=checked;
            else if("show_xp".equals(key))showXp=checked;
            else if("confirm_exit".equals(key))confirmExit=checked;
            else if("compact_settings".equals(key))compactSettings=checked;
            else if("music_enabled".equals(key))musicEnabled=checked;
            putBool(key,checked);
            if("music_enabled".equals(key)&&!checked)stopMusic();
            if("music_enabled".equals(key)&&checked)playMusic();
        });
        into.addView(c,lp(-1,-2));
    }

    private void chooseLanguage() {
        final String[] codes={"fa","en","de","de-CH","de-AT","nl","es","pt","fr","da","no","fi","sv","is","el","ar","he","ja","ko","it","tr"};
        final String[] nativeNames={"فارسی","English","Deutsch","Deutsch (Schweiz)","Deutsch (Österreich)","Nederlands","Español","Português","Français","Dansk","Norsk","Suomi","Svenska","Íslenska","Ελληνικά","العربية","עברית","日本語","한국어","Italiano","Türkçe"};
        new AlertDialog.Builder(this).setTitle(t("choose_language")).setItems(nativeNames,(d,which)->{
            languageCode=codes[which];putString("language_code",languageCode);showSettings();
        }).setNegativeButton(t("cancel"),null).show();
    }
    private void chooseTheme() {
        String[] names=new String[Math.max(1,themes.length())];
        for(int i=0;i<themes.length();i++)names[i]=themes.optJSONObject(i).optString("name","Theme "+(i+1));
        new AlertDialog.Builder(this).setTitle(t("theme")).setSingleChoiceItems(names,themeIndex,(d,which)->{
            themeIndex=which;putInt("theme_index",which);updateTheme();d.dismiss();showSettings();
        }).setNegativeButton(t("cancel"),null).show();
    }
    private void chooseAppearance() {
        final String[] modes={"light","dark","aero","amoled"};
        new AlertDialog.Builder(this).setTitle(t("appearance")).setSingleChoiceItems(modes,Arrays.asList(modes).indexOf(appearanceMode),(d,w)->{
            appearanceMode=modes[w];putString("appearance_mode",appearanceMode);d.dismiss();updateTheme();showSettings();
        }).setNegativeButton(t("cancel"),null).show();
    }
    private void selectTrack(String track) {
        musicTrack=track;putString("music_track",track);stopMusic();playMusic();showSettings();
    }

    private void showFocus() {
        page(t("focus_mode"),false,()->{focusRunning=false;if(focusTick!=null)handler.removeCallbacks(focusTick);stopMusic();showHome();});
        body.addView(label(t("focus_sub"),15,false));
        final TextView timer=label(formatDuration(focusRemainingSeconds),42,true);focusTimerView=timer;timer.setGravity(Gravity.CENTER);body.addView(timer,lp(-1,110));
        LinearLayout row=horizontal();
        for(final int minutes:new int[]{5,15,25,45,60}) {
            Button b=secondaryButton(String.valueOf(minutes),()->{focusRemainingSeconds=minutes*60;focusRunning=false;timer.setText(formatDuration(focusRemainingSeconds));});
            LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(0,dp(45),1);p.setMargins(dp(2),dp(4),dp(2),dp(4));row.addView(b,p);
        }
        body.addView(row,lp(-1,-2));
        addButton(body,focusRunning?t("pause"):t("start"),()->{
            focusRunning=!focusRunning;
            if(focusTick!=null)handler.removeCallbacks(focusTick);
            showFocus();
            if(focusRunning){startFocusTimer(focusTimerView);if(musicEnabled)playMusic();}
        });
        addSecondaryButton(body,t("reset"),()->{if(focusTick!=null)handler.removeCallbacks(focusTick);focusRunning=false;focusRemainingSeconds=25*60;stopMusic();showFocus();});
        addSecondaryButton(body,t("music_study")+" • "+musicTrack,()->{musicEnabled=!musicEnabled;putBool("music_enabled",musicEnabled);if(musicEnabled)playMusic();else stopMusic();showFocus();});
        addSecondaryButton(body,t("settings"),()->showSettings());
    }

    private void startFocusTimer(final TextView timer) {
        if(focusTick!=null)handler.removeCallbacks(focusTick);
        focusTick=new Runnable(){public void run(){
            if(!focusRunning)return;
            focusRemainingSeconds=Math.max(0,focusRemainingSeconds-1);
            if(focusTimerView!=null)focusTimerView.setText(formatDuration(focusRemainingSeconds));
            if(focusRemainingSeconds==0){focusRunning=false;stopMusic();new AlertDialog.Builder(MainActivity.this).setTitle(t("done")).setMessage(t("focus_mode")).setPositiveButton(t("great"),null).show();return;}
            handler.postDelayed(this,1000);
        }};
        handler.postDelayed(focusTick,1000);
    }

    private void playMusic() {
        if(!musicEnabled)return;
        try{
            if(player!=null){player.release();player=null;}
            int id=getResources().getIdentifier(musicTrack,"raw",getPackageName());
            if(id==0){toast(t("music")+" unavailable");return;}
            player=MediaPlayer.create(this,id);
            if(player!=null){player.setLooping(true);player.setVolume((float)musicVolume,(float)musicVolume);player.start();}
        }catch(Exception e){stopMusic();}
    }
    private void stopMusic(){try{if(player!=null){player.stop();player.release();player=null;}}catch(Exception ignored){player=null;}}

    private void showPowerCenter() {
        page("Power Center",false,()->showHome());
        addPanel(body,label(t("experience")+" • "+xp+" XP • Level "+(1+xp/250),18,true));
        addPanel(body,label(t("streak")+" • "+streak,16,true));
        addPanel(body,label(t("daily_goal")+" • "+Math.min(dailyGoal,dueCountAll())+"/"+dailyGoal,15,false));
        addButton(body,t("smart_mix"),()->startSmartMix());
        addButton(body,t("claim_reward"),()->claimReward());
        addSecondaryButton(body,t("achievement_center"),()->showAchievements());
        addSecondaryButton(body,t("study"),()->startStudy(null,"due"));
    }

    private int dueCountAll(){int n=0;for(int i=0;i<decks.length();i++)n+=dueCount(decks.optJSONObject(i));return n;}
    private void claimReward() {
        String today=dayKey(new Date());
        if(today.equals(lastRewardDay)){toast(t("reward_claimed"));return;}
        lastRewardDay=today;xp+=50+Math.min(streak*5,100);putString("last_reward_day",today);putInt("xp",xp);
        toast("+"+(50+Math.min(streak*5,100))+" XP");showPowerCenter();
    }

    private void showAchievements() {
        page(t("achievement_center"),false,()->showHome());
        int total=totalCards(),reviews=0,favs=0,due=dueCountAll(),maxLapses=0;
        for(int i=0;i<decks.length();i++){JSONArray a=decks.optJSONObject(i).optJSONArray("cards");if(a==null)continue;for(int j=0;j<a.length();j++){JSONObject c=a.optJSONObject(j);if(c!=null){reviews+=c.optInt("reviews",0);if(c.optBoolean("favorite",false))favs++;maxLapses+=c.optInt("lapses",0);}}}
        addPanel(body,label(t("experience")+" • "+xp+" XP",19,true));
        addPanel(body,label(t("level")+" "+(1+xp/250)+" • "+(xp%250)+"/250 XP",16,false));
        addPanel(body,label(t("streak")+" • "+streak,16,true));
        addAchievement(body,"New learner",total>=1,"Create your first flashcard");
        addAchievement(body,"Getting started",reviews>=10,"Review 10 cards");
        addAchievement(body,"Consistent learner",reviews>=100,"Review 100 cards");
        addAchievement(body,"Dedicated learner",reviews>=500,"Review 500 cards");
        addAchievement(body,"Streak starter",streak>=3,"Study three days in a row");
        addAchievement(body,"Weekly habit",streak>=7,"Study seven days in a row");
        addAchievement(body,"Collector",favs>=10,"Favorite 10 cards");
        addAchievement(body,"Due zero",due==0&&total>0,"Clear all cards due today");
        addAchievement(body,"Deck builder",decks.length()>=5,"Create five decks");
        addAchievement(body,"Level 5",xp>=1000,"Reach level 5");
        addButton(body,t("smart_mix"),()->startSmartMix());
    }
    private void addAchievement(LinearLayout into,String title,boolean earned,String detail) {
        LinearLayout p=panel();p.addView(label((earned?"✓  ":"○  ")+title,16,true));p.addView(label(detail,13,false));addPanel(into,p);
    }

    private void showAbout() {
        page(t("about"),false,()->showHome());
        addPanel(body,label("Parin Litner",25,true));
        addPanel(body,label("این برنامه توسط پوریا مشعلچیان (Pourya Mashalchian) ساخته شده است.",16,false));
        addPanel(body,label("Android 4 legacy native edition • API 14+",13,false));
        addButton(body,t("repository"),()->{
            try{startActivity(new Intent(Intent.ACTION_VIEW,Uri.parse("https://github.com/Parin-M/parin-litner")));}catch(Exception e){toast("URL unavailable");}
        });
    }

    private void chooseImport() {
        try {
            Intent i=new Intent(Intent.ACTION_GET_CONTENT);i.setType("*/*");
            startActivityForResult(Intent.createChooser(i,t("import")),REQ_IMPORT);
        } catch(Exception e){toast(t("backup_invalid"));}
    }
    private void exportBackup() {
        if(Build.VERSION.SDK_INT>=23 && checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)!=PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE},REQ_STORAGE);return;
        }
        try {
            File dir=Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
            if(!dir.exists()&&!dir.mkdirs())throw new Exception("Cannot create Downloads directory");
            File file=new File(dir,"parin_litner_backup.plbackup");
            byte[] data=buildBackup();
            FileOutputStream out=new FileOutputStream(file);out.write(data);out.flush();out.close();
            new AlertDialog.Builder(this).setTitle(t("backup")).setMessage(t("backup_saved")+"\n"+file.getAbsolutePath()).setPositiveButton(t("great"),null).show();
        } catch(Exception e){toast(t("backup_error")+": "+e.getMessage());}
    }
    @Override public void onRequestPermissionsResult(int requestCode,String[] permissions,int[] results) {
        super.onRequestPermissionsResult(requestCode,permissions,results);
        if(requestCode==REQ_STORAGE && results.length>0 && results[0]==PackageManager.PERMISSION_GRANTED)exportBackup();
        else if(requestCode==REQ_STORAGE)toast(t("backup_error"));
    }

    private byte[] buildBackup() throws Exception {
        Map<String,byte[]> assets=new HashMap<String,byte[]>();int next=0;
        JSONArray backupDecks=new JSONArray();
        for(int i=0;i<decks.length();i++) {
            JSONObject rawDeck=decks.optJSONObject(i);if(rawDeck==null)continue;
            JSONObject deck=new JSONObject(rawDeck.toString());
            JSONArray cards=deck.optJSONArray("cards"), updated=new JSONArray();
            if(cards!=null)for(int j=0;j<cards.length();j++){
                JSONObject rawCard=cards.optJSONObject(j);if(rawCard==null)continue;
                JSONObject card=new JSONObject(rawCard.toString());
                String id=card.optString("id","unknown");
                String fi=nullableString(card.opt("frontImage")),bi=nullableString(card.opt("backImage"));
                card.remove("frontImage");card.remove("backImage");
                card.put("frontImageAsset",addAsset(assets,fi,++next,"front",id));
                card.put("backImageAsset",addAsset(assets,bi,++next,"back",id));
                updated.put(card);
            }
            deck.put("cards",updated);backupDecks.put(deck);
        }
        JSONObject manifest=new JSONObject();manifest.put("app","Parin Litner");manifest.put("format",1);
        manifest.put("exportedAt",new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'",Locale.US).format(new Date()));
        manifest.put("imageCount",assets.size());manifest.put("decks",backupDecks);
        byte[] json=manifest.toString().getBytes(UTF8);
        if(json.length>64*1024*1024)throw new Exception("Backup metadata too large");
        ByteArrayOutputStream bout=new ByteArrayOutputStream();DataOutputStream out=new DataOutputStream(bout);
        out.write(BACKUP_MAGIC);out.writeInt(json.length);out.write(json);
        for(Map.Entry<String,byte[]> entry:assets.entrySet()) {
            byte[] name=entry.getKey().getBytes(UTF8);byte[] image=entry.getValue();
            if(name.length==0||name.length>65535)throw new Exception("Invalid image asset name");
            out.writeShort(name.length);out.write(name);out.writeInt(image.length);out.write(image);
        }
        out.flush();return bout.toByteArray();
    }
    private String addAsset(Map<String,byte[]> assets,String encoded,int num,String side,String id) throws Exception {
        if(encoded==null||encoded.length()==0)return null;
        byte[] bytes;
        try{bytes=Base64.decode(encoded,Base64.DEFAULT);}catch(Exception e){throw new Exception("Invalid image data for card "+id+" "+side);}
        String name="image_"+String.format(Locale.US,"%06d",assets.size()+1)+".bin";assets.put(name,bytes);return name;
    }

    private void importBytes(byte[] bytes) throws Exception {
        if(bytes.length>=8 && Arrays.equals(Arrays.copyOf(bytes,8),BACKUP_MAGIC)) {
            if(bytes.length<12)throw new Exception("Backup incomplete");
            DataInputStream in=new DataInputStream(new ByteArrayInputStream(bytes));byte[] magic=new byte[8];in.readFully(magic);
            int length=in.readInt();if(length<0||length>64*1024*1024||length>in.available())throw new Exception("Invalid backup manifest length");
            byte[] j=new byte[length];in.readFully(j);JSONObject manifest=new JSONObject(new String(j,UTF8));
            if(!"Parin Litner".equals(manifest.optString("app"))||manifest.optInt("format")!=1)throw new Exception("Unsupported backup format");
            int count=manifest.optInt("imageCount",-1);if(count<0||count>50000)throw new Exception("Invalid image count");
            Map<String,byte[]> assets=new HashMap<String,byte[]>();
            for(int i=0;i<count;i++){int nl=in.readUnsignedShort();if(nl==0||nl>in.available())throw new Exception("Invalid image name");byte[] nb=new byte[nl];in.readFully(nb);int len=in.readInt();if(len<0||len>in.available())throw new Exception("Invalid image entry");byte[] img=new byte[len];in.readFully(img);String name=new String(nb,UTF8);if(assets.containsKey(name))throw new Exception("Duplicate image");assets.put(name,img);}
            if(in.available()!=0)throw new Exception("Unexpected trailing data");
            JSONArray incoming=manifest.optJSONArray("decks");if(incoming==null)throw new Exception("Missing deck list");
            for(int i=0;i<incoming.length();i++){
                JSONObject deck=incoming.optJSONObject(i);if(deck==null)throw new Exception("Invalid deck");
                JSONArray cards=deck.optJSONArray("cards");if(cards==null)throw new Exception("Invalid cards");
                for(int k=0;k<cards.length();k++){
                    JSONObject card=cards.optJSONObject(k);if(card==null)throw new Exception("Invalid card");
                    for(String side:new String[]{"front","back"}){String ref=card.optString(side+"ImageAsset",null);card.remove(side+"ImageAsset");if(ref!=null&&!"null".equals(ref)){byte[] b=assets.get(ref);if(b==null)throw new Exception("Missing image "+ref);card.put(side+"Image",Base64.encodeToString(b,Base64.NO_WRAP));}else card.put(side+"Image",JSONObject.NULL);}
                }
            }
            importDeckList(incoming);
        } else {
            String raw=new String(bytes,UTF8);JSONArray incoming;
            Object parsed=new org.json.JSONTokener(raw).nextValue();
            if(parsed instanceof JSONArray)incoming=(JSONArray)parsed;
            else if(parsed instanceof JSONObject)incoming=((JSONObject)parsed).optJSONArray("decks");
            else incoming=null;
            if(incoming==null)throw new Exception("This is not a Parin Litner backup");
            importDeckList(incoming);
        }
    }

    private void importDeckList(final JSONArray incoming) {
        new AlertDialog.Builder(this).setTitle(t("import")).setMessage(incoming.length()+" "+t("decks"))
          .setNegativeButton(t("merge"),(d,w)->{
              for(int i=0;i<incoming.length();i++){JSONObject old=incoming.optJSONObject(i);if(old==null)continue;try{
                  JSONObject copy=new JSONObject(old.toString());copy.put("id",uid());decks.put(copy);
              }catch(Exception ignored){}}
              saveData();showHome();
          }).setPositiveButton(t("replace"),(d,w)->{try{decks=new JSONArray(incoming.toString());saveData();showHome();}catch(Exception e){toast(t("backup_invalid"));}}).show();
    }

    private void toast(String message) { Toast.makeText(this,message,Toast.LENGTH_LONG).show(); }

    @Override public void onBackPressed() {
        if(focusTick!=null && focusRunning) { focusRunning=false;handler.removeCallbacks(focusTick); }
        if(studyItems.size()>0&&!studyFinished&&root!=null&&confirmExit) {leaveStudy();return;}
        if(backAction!=null)backAction.run();else showHome();
    }

    @Override protected void onDestroy() {
        super.onDestroy();
        if(focusTick!=null)handler.removeCallbacks(focusTick);
        handler.removeCallbacks(studyTick);
        stopMusic();
    }
}
