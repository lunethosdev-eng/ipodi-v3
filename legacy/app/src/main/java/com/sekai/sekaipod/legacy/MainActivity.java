package com.sekai.sekaipod.legacy;

import android.app.Activity;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.os.StrictMode;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.*;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;

public class MainActivity extends Activity {
    private static final String CATALOG = "https://sekai-music-server.onrender.com/api/v1/catalog";
    private final ArrayList<Song> songs = new ArrayList<Song>();
    private LinearLayout list;
    private TextView status;
    private MediaPlayer player;

    static class Song { String title="Unknown"; String artist="Unknown"; String audio=""; }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        StrictMode.setThreadPolicy(new StrictMode.ThreadPolicy.Builder().permitAll().build());
        buildUi();
        loadCatalog();
    }

    private void buildUi() {
        LinearLayout root = new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setBackgroundColor(Color.WHITE);
        TextView title = new TextView(this); title.setText("SEKAIPOD"); title.setTextSize(24); title.setTypeface(Typeface.DEFAULT, Typeface.BOLD); title.setTextColor(Color.BLACK); title.setGravity(Gravity.CENTER_VERTICAL); title.setPadding(24,18,24,10);
        root.addView(title, new LinearLayout.LayoutParams(-1,70));
        status = new TextView(this); status.setText("Loading Sekai Music…"); status.setTextColor(Color.DKGRAY); status.setPadding(24,0,24,12); root.addView(status,new LinearLayout.LayoutParams(-1,50));
        ScrollView scroll = new ScrollView(this); list = new LinearLayout(this); list.setOrientation(LinearLayout.VERTICAL); scroll.addView(list); root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        setContentView(root);
    }

    private void loadCatalog() {
        try {
            HttpURLConnection c=(HttpURLConnection)new URL(CATALOG).openConnection(); c.setConnectTimeout(15000); c.setReadTimeout(20000); c.setRequestMethod("GET");
            BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream(),"UTF-8")); StringBuilder b=new StringBuilder(); String line; while((line=r.readLine())!=null)b.append(line); r.close();
            JSONObject data=new JSONObject(b.toString()); JSONArray a=data.optJSONArray("catalog");
            if(a==null){ status.setText("No catalog array returned"); return; }
            for(int i=0;i<a.length();i++){ JSONObject o=a.optJSONObject(i); if(o==null)continue; Song s=new Song(); s.title=first(o,"title","name","track","song"); s.artist=first(o,"artist","artist_name","author","creator"); s.audio=first(o,"audioUrl","audio_url","streamUrl","stream_url","url","soundcloud","youtube"); songs.add(s); }
            status.setText(songs.size()+" songs loaded"); render();
        } catch(Exception e){ status.setText("Catalog unavailable: "+e.getClass().getSimpleName()); }
    }

    private String first(JSONObject o,String... keys){ for(String k:keys){String v=o.optString(k,""); if(v.length()>0 && !v.equals("null"))return v;} return ""; }

    private void render(){
        list.removeAllViews();
        for(final Song s:songs){
            Button b=new Button(this); b.setAllCaps(false); b.setText(s.title+"\n"+s.artist); b.setGravity(Gravity.LEFT|Gravity.CENTER_VERTICAL); b.setPadding(24,8,24,8); b.setOnClickListener(new View.OnClickListener(){public void onClick(View v){play(s);}}); list.addView(b,new LinearLayout.LayoutParams(-1,72));
        }
    }
    private void play(Song s){
        if(s.audio.length()==0){Toast.makeText(this,"No direct audio URL in catalog entry",Toast.LENGTH_SHORT).show();return;}
        try{ if(player!=null){player.release();player=null;} player=new MediaPlayer(); player.setAudioStreamType(AudioManager.STREAM_MUSIC); player.setDataSource(s.audio); player.setOnPreparedListener(new MediaPlayer.OnPreparedListener(){public void onPrepared(MediaPlayer mp){mp.start();}}); player.prepareAsync(); status.setText("Playing: "+s.title); }
        catch(Exception e){Toast.makeText(this,"Playback failed",Toast.LENGTH_SHORT).show();}
    }
    @Override protected void onDestroy(){if(player!=null){player.release();player=null;} super.onDestroy();}
}
