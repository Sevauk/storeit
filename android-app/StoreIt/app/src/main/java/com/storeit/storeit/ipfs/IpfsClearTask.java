package com.storeit.storeit.ipfs;
import android.os.AsyncTask;
import android.preference.Preference;
import android.util.Log;
import com.google.gson.Gson;
import org.apache.commons.io.IOUtils;
import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by loulo on 11/10/2016.
 */

public class IpfsClearTask extends AsyncTask<Void, Void, Void> {

    private String nodeUrl = "http://127.0.0.1";
    private Preference mClearButton;

    private class IpfsPinLs {

        class Key {
            public String Type;
        }

        public HashMap<String, Key> Keys;
    }

    public IpfsClearTask(Preference clearButton) {
        mClearButton = clearButton;
    }

    protected void onPreExecute() {
        super.onPreExecute();
    }

    private List<String> listFiles() {
        nodeUrl = "http://127.0.0.1";

        ArrayList<String> hashes = new ArrayList<>();

        URL url;
        HttpURLConnection urlConnection = null;

        try {
            url = new URL(nodeUrl + ":5001/api/v0/pin/ls");
            urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.setConnectTimeout(20000);
            InputStream in = new BufferedInputStream(urlConnection.getInputStream());
            String result = IOUtils.toString(in);
            Gson gson = new Gson();
            IpfsPinLs res = gson.fromJson(result, IpfsPinLs.class);

            if (res == null)
                return hashes;

            for (Map.Entry<String, IpfsPinLs.Key> entry : res.Keys.entrySet()) {
                IpfsPinLs.Key value = entry.getValue();
                String hash = entry.getKey();

                if (value.Type.equals("recursive")) {
                    hashes.add(hash);
                }
            }
            Log.v("StoreitPreferences", res.toString());

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
        return hashes;
    }

    private void unpinHashes(List<String> hashes) {

        for (String hash : hashes) {
            URL url;
            HttpURLConnection urlConnection = null;
            try {
                url = new URL(nodeUrl + ":5001/api/v0/pin/rm?arg=" + hash);
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
        }
    }

    private void callGc() {
        URL url;
        HttpURLConnection urlConnection = null;
        try {
            url = new URL(nodeUrl + ":5001/api/v0/repo/gc");
            urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.setConnectTimeout(20000);
            InputStream in = new BufferedInputStream(urlConnection.getInputStream());

            String result = IOUtils.toString(in);
            Log.v("StoreitPreferences", "call gc" + result);

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
    }

    @Override
    protected Void doInBackground(Void... voids) {

        List<String> hashes = listFiles();
        unpinHashes(hashes);
        callGc();

        return null;
    }

    @Override
    protected void onPostExecute(Void v) {
        new IpfsStatTask(mClearButton).execute();
    }
}