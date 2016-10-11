package com.storeit.storeit.ipfs;

import android.os.AsyncTask;
import android.preference.Preference;
import android.util.Log;

import org.apache.commons.io.IOUtils;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Created by loulo on 11/10/2016.
 */

public class IpfsClearTask extends AsyncTask<Void, Void, Void> {

    Preference mClearButton;

    public IpfsClearTask(Preference clearButton) {
        mClearButton = clearButton;
    }

    protected void onPreExecute(){
        super.onPreExecute();
    }

    @Override
    protected Void doInBackground(Void... voids) {
        String nodeUrl = "http://127.0.0.1";

        URL url = null;
        HttpURLConnection urlConnection = null;
        long size = -1;

        try {
            url = new URL(nodeUrl + ":5001/api/v0/repo/gc");
            urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.setConnectTimeout(20000);
            InputStream in = new BufferedInputStream(urlConnection.getInputStream());

            String result = IOUtils.toString(in);

            Log.v("StoreitPreferences", "la" + result);

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
        return  null;
    }

    @Override
    protected void onPostExecute(Void v) {
        new IpfsStatTask(mClearButton).execute();
    }
}