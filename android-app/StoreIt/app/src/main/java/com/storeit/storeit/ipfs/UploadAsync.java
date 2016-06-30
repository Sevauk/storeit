package com.storeit.storeit.ipfs;

import android.app.NotificationManager;
import android.content.Context;
import android.os.AsyncTask;
import android.support.v4.app.Fragment;
import android.support.v7.app.NotificationCompat;
import android.util.Log;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.storeit.storeit.R;
import com.storeit.storeit.activities.MainActivity;
import com.storeit.storeit.fragments.FileViewerFragment;
import com.storeit.storeit.protocol.StoreitFile;
import com.storeit.storeit.services.SocketService;
import com.storeit.storeit.utils.FilesManager;

import java.io.File;

public class UploadAsync extends AsyncTask<String, Void, String> {

    private NotificationManager mNotifyManager;
    private android.support.v4.app.NotificationCompat.Builder mBuilder;
    private int id = 1;
    private MainActivity mContext;
    private SocketService mService;

    public UploadAsync(MainActivity context, SocketService service){
        mContext = context;
        mService = service;
    }

    protected void onPreExecute() {
        super.onPreExecute();

        mNotifyManager = (NotificationManager)mContext.getSystemService(Context.NOTIFICATION_SERVICE);
        mBuilder = new NotificationCompat.Builder(mContext)
                .setContentTitle("StoreIt")
                .setContentText("Upload in progress")
                .setSmallIcon(R.drawable.ic_insert_drive_file_black_24dp);
        mBuilder.setProgress(0, 0, true);

        mNotifyManager.notify(id, mBuilder.build());
    }

    @Override
    protected void onPostExecute(String response) {


        if (response.equals("")) {
            mBuilder.setContentText("Upload failed...")
                    .setProgress(0, 0, false);
        } else {
            mBuilder.setContentText(response)
                    .setProgress(0, 0, false);
            Log.v("IPFS", response);

            FilesManager manager = mContext.getFilesManager();

            // Get the ipfs hash from response
            JsonParser parser = new JsonParser();
            JsonObject obj = parser.parse(response).getAsJsonObject();

            String hash = obj.get("Hash").getAsString();
            String name = obj.get("Name").getAsString();

            mContext.openFragment(new FileViewerFragment());

            // Get the current folder
            Fragment currentFragment = mContext.getSupportFragmentManager().findFragmentById(R.id.fragment_container); // Get the file explorer fragment
            if (currentFragment instanceof FileViewerFragment) {

                FileViewerFragment fragment = (FileViewerFragment)currentFragment;

                // Create new storeit file and add it
                StoreitFile newFile;

                if (fragment.getCurrentFile().getPath().equals("/")){
                    newFile = new StoreitFile(fragment.getCurrentFile().getPath() + name, hash, false);
                } else {
                    newFile = new StoreitFile(fragment.getCurrentFile().getPath() + File.separator + name, hash, false);
                }
                manager.addFile(newFile, fragment.getCurrentFile());
                mContext.refreshFileExplorer();
                mService.sendFADD(newFile);
            }
        }

        mNotifyManager.notify(id, mBuilder.build());
    }

    @Override
    protected String doInBackground(String... params) {

        String fileName = params[0];
        IPFS ipfs = new IPFS("toto");
        return ipfs.sendFile(new File(fileName));
    }
}