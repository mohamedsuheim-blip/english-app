#!/bin/bash
set -e
mkdir -p .github/workflows app/src/main/java/com/learn/english app/src/main/assets app/src/main/res/drawable
cp index.html app/src/main/assets/index.html
cat > settings.gradle <<'EOF_FILE'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "EnglishApp"
include ':app'
EOF_FILE
cat > build.gradle <<'EOF_FILE'
plugins {
    id 'com.android.application' version '8.5.2' apply false
}
EOF_FILE
cat > gradle.properties <<'EOF_FILE'
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
android.nonTransitiveRClass=true
EOF_FILE
cat > app/build.gradle <<'EOF_FILE'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.learn.english'
    compileSdk 34

    defaultConfig {
        applicationId "com.learn.english"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}
EOF_FILE
cat > app/src/main/AndroidManifest.xml <<'EOF_FILE'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <queries>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
    </queries>

    <application
        android:allowBackup="true"
        android:icon="@drawable/ic_launcher"
        android:label="تعلّم الإنجليزي"
        android:supportsRtl="true"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:configChanges="orientation|screenSize|keyboardHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF_FILE
cat > app/src/main/res/drawable/ic_launcher.xml <<'EOF_FILE'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#2563EB"
        android:pathData="M0,0h108v108h-108z" />
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="9"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:pathData="M30,80 L54,28 L78,80 M39,64 L69,64" />
</vector>
EOF_FILE
cat > app/src/main/java/com/learn/english/MainActivity.java <<'EOF_FILE'
package com.learn.english;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.webkit.JavascriptInterface;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;

import java.util.Locale;

public class MainActivity extends Activity {

    private WebView web;
    private TextToSpeech tts;

    public class Bridge {
        @JavascriptInterface
        public void speak(String text) {
            if (tts != null) {
                tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "utt");
            }
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        tts = new TextToSpeech(this, status -> {
            if (status == TextToSpeech.SUCCESS) {
                tts.setLanguage(Locale.US);
                tts.setSpeechRate(0.8f);
            }
        });

        web = new WebView(this);
        WebSettings settings = web.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);

        web.addJavascriptInterface(new Bridge(), "Android");

        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onJsConfirm(WebView view, String url, String message, JsResult result) {
                new AlertDialog.Builder(MainActivity.this)
                        .setMessage(message)
                        .setPositiveButton("نعم", (d, w) -> result.confirm())
                        .setNegativeButton("لا", (d, w) -> result.cancel())
                        .setOnCancelListener(d -> result.cancel())
                        .show();
                return true;
            }
        });

        web.loadUrl("file:///android_asset/index.html");
        setContentView(web);
    }

    @Override
    protected void onDestroy() {
        if (tts != null) {
            tts.stop();
            tts.shutdown();
        }
        super.onDestroy();
    }
}
EOF_FILE
