package com.sekai.sekaipod.legacy;

import android.app.Activity;
import android.os.AsyncTask;
import android.os.Bundle;
import android.graphics.Color;
import android.graphics.Typeface;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;

/**
 * Small legacy client for Android 4.1-6.
 *
 * The legacy APK deliberately avoids modern Android APIs. It loads the same
 * one-request Sekai Music catalog as the Flutter app and uses MediaPlayer for
 * direct audio URLs.
 */
public class MainActivity extends Activity {
    private static final String CATALOG = "https://sekai-music-server.onrender.com/api/v1/catalog";
    private final ArrayList<Song> songs = new ArrayList<Song>();
    private LinearLayout list;
    private TextView status;
    private Button retryButton;
    private MediaPlayer player;
    private CatalogTask catalogTask;

    static class Song {
        String title = "Unknown Song";
        String artist = "Unknown Artist";
        String audio = "";
    }

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        buildUi();
        loadCatalog();
    }

    private void buildUi() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.WHITE);

        TextView title = new TextView(this);
        title.setText("SEKAIPOD");
        title.setTextSize(24);
        title.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        title.setTextColor(Color.BLACK);
        title.setGravity(Gravity.CENTER_VERTICAL);
        title.setPadding(24, 18, 24, 10);
        root.addView(title, new LinearLayout.LayoutParams(-1, 70));

        status = new TextView(this);
        status.setText("Connecting to Sekai Music…");
        status.setTextColor(Color.DKGRAY);
        status.setPadding(24, 0, 24, 8);
        root.addView(status, new LinearLayout.LayoutParams(-1, 52));

        retryButton = new Button(this);
        retryButton.setText("Retry");
        retryButton.setAllCaps(false);
        retryButton.setVisibility(View.GONE);
        retryButton.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { loadCatalog(); }
        });
        root.addView(retryButton, new LinearLayout.LayoutParams(-1, 52));

        ScrollView scroll = new ScrollView(this);
        list = new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        scroll.addView(list);
        root.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));

        setContentView(root);
    }

    private void loadCatalog() {
        if (catalogTask != null) {
            catalogTask.cancel(true);
        }
        songs.clear();
        list.removeAllViews();
        retryButton.setVisibility(View.GONE);
        status.setText("Connecting to Sekai Music…");
        catalogTask = new CatalogTask();
        catalogTask.execute();
    }

    private class CatalogTask extends AsyncTask<Void, Void, String> {
        private Exception error;

        @Override protected String doInBackground(Void... ignored) {
            for (int attempt = 1; attempt <= 3; attempt++) {
                if (isCancelled()) return null;
                HttpURLConnection connection = null;
                BufferedReader reader = null;
                try {
                    URL url = new URL(CATALOG);
                    connection = (HttpURLConnection) url.openConnection();
                    connection.setConnectTimeout(90000);
                    connection.setReadTimeout(90000);
                    connection.setRequestMethod("GET");
                    connection.setRequestProperty("Accept", "application/json");
                    connection.setRequestProperty("User-Agent", "SekaiPod-Legacy/1.0 Android");
                    if (connection instanceof HttpsURLConnection) {
                        HttpsURLConnection https = (HttpsURLConnection) connection;
                        https.setSSLSocketFactory(new Tls12SocketFactory((SSLSocketFactory) SSLSocketFactory.getDefault()));
                    }

                    int code = connection.getResponseCode();
                    if (code < 200 || code >= 300) {
                        throw new Exception("HTTP " + code);
                    }

                    reader = new BufferedReader(new InputStreamReader(connection.getInputStream(), "UTF-8"));
                    StringBuilder body = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) body.append(line);
                    return body.toString();
                } catch (Exception e) {
                    error = e;
                    if (attempt < 3) {
                        try { Thread.sleep(3000L * attempt); } catch (InterruptedException ignoredSleep) { return null; }
                    }
                } finally {
                    try { if (reader != null) reader.close(); } catch (Exception ignoredClose) { }
                    if (connection != null) connection.disconnect();
                }
            }
            return null;
        }

        @Override protected void onPostExecute(String body) {
            if (isFinishing()) return;
            if (body == null) {
                String detail = error == null ? "Unknown error" : error.getClass().getSimpleName();
                status.setText("Catalog unavailable: " + detail);
                retryButton.setVisibility(View.VISIBLE);
                return;
            }
            try {
                JSONObject data = new JSONObject(body);
                JSONArray catalog = data.optJSONArray("catalog");
                if (catalog == null) throw new Exception("No catalog array returned");

                for (int i = 0; i < catalog.length(); i++) {
                    JSONObject item = catalog.optJSONObject(i);
                    if (item == null) continue;
                    JSONObject metadata = item.optJSONObject("metadata");
                    if (metadata == null) metadata = item;

                    Song song = new Song();
                    song.title = first(metadata, item, "trackName", "title", "name", "track", "song", "songName");
                    song.artist = first(metadata, item, "trackArtistNames", "artist", "artist_name", "artistName", "author", "creator");
                    song.audio = first(item, metadata, "audioUrl", "audio_url", "streamUrl", "stream_url", "playUrl", "url", "soundcloudUrl", "soundcloud", "youtubeAudioUrl", "youtube");
                    if (song.title.length() > 0) songs.add(song);
                }

                status.setText(songs.size() + " songs available");
                retryButton.setVisibility(View.GONE);
                render();
            } catch (Exception e) {
                status.setText("Catalog unavailable: " + e.getClass().getSimpleName());
                retryButton.setVisibility(View.VISIBLE);
            }
        }
    }

    private String first(JSONObject primary, JSONObject fallback, String... keys) {
        for (String key : keys) {
            String value = primary.optString(key, "");
            if (value.length() > 0 && !value.equals("null")) return value;
            value = fallback.optString(key, "");
            if (value.length() > 0 && !value.equals("null")) return value;
        }
        return "";
    }

    private void render() {
        list.removeAllViews();
        for (final Song song : songs) {
            Button button = new Button(this);
            button.setAllCaps(false);
            button.setText(song.title + "\n" + song.artist);
            button.setGravity(Gravity.LEFT | Gravity.CENTER_VERTICAL);
            button.setPadding(24, 8, 24, 8);
            button.setOnClickListener(new View.OnClickListener() {
                @Override public void onClick(View v) { play(song); }
            });
            list.addView(button, new LinearLayout.LayoutParams(-1, 72));
        }
    }

    private void play(Song song) {
        if (song.audio.length() == 0 || song.audio.startsWith("https://www.youtube.com") || song.audio.startsWith("https://youtu.be")) {
            Toast.makeText(this, "This song does not have a direct audio stream.", Toast.LENGTH_SHORT).show();
            return;
        }
        try {
            if (player != null) { player.release(); player = null; }
            player = new MediaPlayer();
            player.setAudioStreamType(AudioManager.STREAM_MUSIC);
            player.setDataSource(song.audio);
            player.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                @Override public void onPrepared(MediaPlayer mp) { mp.start(); }
            });
            player.setOnErrorListener(new MediaPlayer.OnErrorListener() {
                @Override public boolean onError(MediaPlayer mp, int what, int extra) {
                    Toast.makeText(MainActivity.this, "Playback failed for this stream.", Toast.LENGTH_SHORT).show();
                    return true;
                }
            });
            player.prepareAsync();
            status.setText("Loading: " + song.title);
        } catch (Exception e) {
            Toast.makeText(this, "Playback failed", Toast.LENGTH_SHORT).show();
        }
    }

    @Override protected void onDestroy() {
        if (catalogTask != null) catalogTask.cancel(true);
        if (player != null) { player.release(); player = null; }
        super.onDestroy();
    }

    /** Enables TLS 1.2 on older Android releases where it is not enabled by default. */
    private static class Tls12SocketFactory extends SSLSocketFactory {
        private final SSLSocketFactory delegate;

        Tls12SocketFactory(SSLSocketFactory delegate) { this.delegate = delegate; }

        private java.net.Socket enable(java.net.Socket socket) {
            if (socket instanceof SSLSocket) {
                SSLSocket ssl = (SSLSocket) socket;
                try { ssl.setEnabledProtocols(new String[] { "TLSv1.2" }); } catch (Exception ignored) { }
            }
            return socket;
        }

        @Override public java.net.Socket createSocket(java.net.Socket s, String host, int port, boolean autoClose) throws java.io.IOException {
            return enable(delegate.createSocket(s, host, port, autoClose));
        }
        @Override public java.net.Socket createSocket(String host, int port) throws java.io.IOException { return enable(delegate.createSocket(host, port)); }
        @Override public java.net.Socket createSocket(String host, int port, java.net.InetAddress localHost, int localPort) throws java.io.IOException { return enable(delegate.createSocket(host, port, localHost, localPort)); }
        @Override public java.net.Socket createSocket(java.net.InetAddress host, int port) throws java.io.IOException { return enable(delegate.createSocket(host, port)); }
        @Override public java.net.Socket createSocket(java.net.InetAddress address, int port, java.net.InetAddress localAddress, int localPort) throws java.io.IOException { return enable(delegate.createSocket(address, port, localAddress, localPort)); }
        @Override public String[] getDefaultCipherSuites() { return delegate.getDefaultCipherSuites(); }
        @Override public String[] getSupportedCipherSuites() { return delegate.getSupportedCipherSuites(); }
    }
}
