package com.storeit.storeit.ipfs;

import android.os.AsyncTask;
import android.preference.Preference;
import android.util.Log;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.apache.commons.io.IOUtils;
import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class IpfsStatTask extends AsyncTask<Void, Void, Long> {

    private Preference mClearCacheButton;

    public IpfsStatTask(Preference clearCacheButton) {
        mClearCacheButton = clearCacheButton;
    }

    @Override
    protected Long doInBackground(Void... voids) {

        String nodeUrl = "http://127.0.0.1";

        URL url = null;
        HttpURLConnection urlConnection = null;
        long size = -1;

        try {
            url = new URL(nodeUrl + ":5001/api/v0/repo/stat");
            urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.setConnectTimeout(20000);
            InputStream in = new BufferedInputStream(urlConnection.getInputStream());

            String result = IOUtils.toString(in);

            JsonParser parser = new JsonParser();
            JsonObject obj = parser.parse(result).getAsJsonObject();
            size = obj.get("RepoSize").getAsLong();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
        Log.v("StoreitPreferences", "File size : " + size);
        return size;
    }

    @Override
    protected void onPostExecute(Long size) {
        mClearCacheButton.setSummary("Ipfs currently use : " + (float) (size / 1048576) + " mo");
    }
}