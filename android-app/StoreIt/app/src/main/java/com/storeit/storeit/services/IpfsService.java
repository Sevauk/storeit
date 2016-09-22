package com.storeit.storeit.services;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * Created by louis on 16. 8. 5.
 */
public class IpfsService extends Service {

    static final String LOGTAG = "IpfsService";
    static final String IPFS_BINARY = "/data/data/com.storeit.storeit/ipfs";


    private final IBinder myBinder = new LocalBinder();

    public class LocalBinder extends Binder {
        public IpfsService getService() {
            return IpfsService.this;
        }
    }

    @Override
    public void onCreate(){
        super.onCreate();

        Log.v(LOGTAG, "onCreate!");

        copyIpfs();

        new Thread(new Runnable() {
            @Override
            public void run() {
                launchCommand(Arrays.asList(IPFS_BINARY, "daemon"));
            }
        }).start();
    }

    @Override
    public IBinder onBind(Intent intent) {
        Log.v(LOGTAG, "OnBind :)");
        return myBinder;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        super.onStartCommand(intent, flags, startId);
        return START_STICKY;
    }


    @Override
    public void onDestroy() {
        super.onDestroy();

        Log.v(LOGTAG, "On destroy :o");
    }

    void copyIpfs() {
        File file = new File(IPFS_BINARY); // Check if ipfs is already copied
        if (file.exists()) {
            return;
        }

        try {
            InputStream is = getAssets().open("ipfs"); // Copy file
            OutputStream os = new FileOutputStream(file);

            int len = 0;
            byte[] buffer = new byte[1024];
            while ((len = is.read(buffer)) > 0) {
                os.write(buffer, 0, len);
            }
            os.close();

            launchCommand(Arrays.asList("/system/bin/chmod",
                    "751",
                    IPFS_BINARY));
            launchCommand(Arrays.asList(IPFS_BINARY, "init"));

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    void launchCommand(List<String> args) {
        ProcessBuilder pb = new ProcessBuilder(args);
        Map<String, String> env = pb.environment();
        env.put("IPFS_PATH", "/data/data/com.storeit.storeit/");

        try {
            Process process = pb.start();



            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()));
            int read;
            char[] buffer = new char[4096];
//            StringBuffer output = new StringBuffer();
            while ((read = reader.read(buffer)) > 0) {
//                output.append(buffer, 0, read);
                Log.v("BINARY", String.valueOf(buffer, 0, read));
            }
            reader.close();
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }

    public void addFile(final String hash) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                Log.v(LOGTAG, "Downloading : " + hash);
                launchCommand(Arrays.asList(IPFS_BINARY, "get", hash));
                Log.v(LOGTAG, "Downloaded : " + hash);
                Log.v(LOGTAG, "Adding : " + hash);
                launchCommand(Arrays.asList(IPFS_BINARY, "add", hash));
                Log.v(LOGTAG, "Added : " + hash);
            }
        }).run();

    }

    public void removeFile(final String hash) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                launchCommand(Arrays.asList(IPFS_BINARY, "pin", "rm", hash));
            }
        }).run();
    }
}
