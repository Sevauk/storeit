package com.storeit.storeit.ipfs;

import android.app.NotificationManager;
import android.content.Context;
import android.os.AsyncTask;
import android.support.v7.app.NotificationCompat;
import android.util.Log;

import com.storeit.storeit.R;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

public class DownloadAsync extends AsyncTask<String, Void, Boolean> {
    private NotificationManager mNotifyManager;
    private android.support.v4.app.NotificationCompat.Builder mBuilder;
    private int id = 1;
    private Context mContext;

    public DownloadAsync(Context context) {
        mContext = context;
    }

    protected void onPreExecute() {
        super.onPreExecute();

        mNotifyManager = (NotificationManager) mContext.getSystemService(Context.NOTIFICATION_SERVICE);
        mBuilder = new NotificationCompat.Builder(mContext)
                .setContentTitle("StoreIt")
                .setContentText("Download in progress")
                .setSmallIcon(R.drawable.ic_insert_drive_file_black_24dp);
        mBuilder.setProgress(0, 0, true);

        mNotifyManager.notify(id, mBuilder.build());
    }

    @Override
    protected void onPostExecute(Boolean response) {
        if (!response) {
            mBuilder.setContentText("Error while downloading...")
                    .setProgress(0, 0, false);
        } else {
            mBuilder.setContentText("Download finished")
                    .setProgress(0, 0, false);
        }
        mNotifyManager.notify(id, mBuilder.build());
    }

    @Override
    protected Boolean doInBackground(String... params) {

        String path = params[0];
        String hash = params[1];

        IPFS ipfs = new IPFS("toto");

        File filePath = new File(path);
        File file = new File(filePath, hash);

        FileOutputStream outputStream = null;

        try {
            if (!file.exists()) {
                if (!file.createNewFile()){
                    Log.e("DownloadAsync", "Error while creating " + file);
                }
            }

            outputStream = new FileOutputStream(file);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            if (!file.delete()) {
                Log.v("DownloadAsync", "Error while deleting file");
            }
            return false;
        } catch (IOException e) {
            e.printStackTrace();
            if (!file.delete()) {
                Log.v("DownloadAsync", "Error while deleting file");
            }
        }
        if (outputStream == null){
            if (!file.delete()) {
                Log.v("DownloadAsync", "Error while deleting file");
            }
            return  false;
        }
        return ipfs.downloadFile(outputStream, hash);
    }
}
