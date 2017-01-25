package com.storeit.storeit.services;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.BitmapFactory;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.os.Message;
import android.util.Log;

import com.storeit.storeit.R;
import com.storeit.storeit.activities.MainActivity;
import com.storeit.storeit.protocol.StoreitFile;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.InterruptedIOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

/**
 * Created by louis on 16. 8. 5.
 */
public class IpfsService extends AbstractService {

    private static final String LOGTAG = "IpfsService";
    private static final String IPFS_BINARY = "/data/data/com.storeit.storeit/ipfs_x86";
    private static final int NOTIFICATION = 123;

    public static final int HANDLE_ADD = 1;
    public static final int HANDLE_DEL = 2;

    private NotificationManager mNotificationManager;
    private Thread mDaemonThread;
    private Thread mIpfsOperationsThread;
    private Process mDaemonProcess;

    private BlockingQueue<IpfsOperation> ipfsOperations = new ArrayBlockingQueue<>(256);
    private volatile  boolean running = true;

    @Override
    public void onStartService() {
        mNotificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        makeNotification(getApplicationContext());

        copyIpfs();
        if (mDaemonThread == null) {
            mDaemonThread = new Thread(new Runnable() {
                @Override
                public void run() {
                    Log.v(LOGTAG, "Launching ipfs daemon");

                    List<String> args = new ArrayList<>();
                    args.add(IPFS_BINARY);
                    args.add("daemon");

                    ProcessBuilder pb = new ProcessBuilder(args);
                    Map<String, String> env = pb.environment();
                    env.put("IPFS_PATH", "/data/data/com.storeit.storeit/");
                    try {
                        mDaemonProcess = pb.start();
                        BufferedReader reader = new BufferedReader(
                                new InputStreamReader(mDaemonProcess.getInputStream()));
                        int read;
                        char[] buffer = new char[4096];
                        while ((read = reader.read(buffer)) > 0) {
                            Log.v("BINARY", String.valueOf(buffer, 0, read));
                        }
                        reader.close();
                        mDaemonProcess.waitFor();
                    } catch (IOException | InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            });
            mDaemonThread.start();
        }
        if (mIpfsOperationsThread == null){
            mIpfsOperationsThread = new Thread(new StoreThread());
            mIpfsOperationsThread.start();
        }

    }

    @Override
    public void onStopService() {
        mNotificationManager.cancel(NOTIFICATION);
        if (mDaemonProcess != null) {
            mDaemonProcess.destroy();
            mDaemonThread.interrupt();
            running = false;
            if (mIpfsOperationsThread != null)
                mIpfsOperationsThread.interrupt();
        }
    }

    @Override
    public void onReceiveMessage(Message msg) {
        String hash;

        switch (msg.what) {

            case HANDLE_ADD:
                hash = (String)msg.obj;
                ipfsOperations.add(new IpfsOperation(hash, true));
                break;
            case HANDLE_DEL:
                hash = (String)msg.obj;
                ipfsOperations.add(new IpfsOperation(hash, false));
                break;
            default:
                break;
        }
    }

    private void copyIpfs() {
        File file = new File(IPFS_BINARY); // Check if ipfs is already copied
        if (file.exists()) {
            return;
        }

        try {
            InputStream is = getAssets().open("ipfs_x86"); // Copy file
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

    private void launchCommand(List<String> args) {
        ProcessBuilder pb = new ProcessBuilder(args);
        Map<String, String> env = pb.environment();
        env.put("IPFS_PATH", "/data/data/com.storeit.storeit/");
        try {
            Process process = pb.start();

            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()));
            int read;
            char[] buffer = new char[4096];
            while ((read = reader.read(buffer)) > 0) {
                Log.v("BINARY", String.valueOf(buffer, 0, read));
            }
            reader.close();
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }


    private void makeNotification(Context context) {
        Intent intent = new Intent(context, MainActivity.class);

        Notification.Builder builder = new Notification.Builder(context)
                .setContentTitle("StoreIt")
                .setContentText("You are an active ipfs node :)")
                .setSmallIcon(R.drawable.ipfs_logo)
                .setAutoCancel(true);

        Notification n;
        n = builder.build();
        n.flags |= Notification.FLAG_NO_CLEAR | Notification.FLAG_ONGOING_EVENT;
        mNotificationManager.notify(NOTIFICATION, n);
    }



    class StoreThread implements Runnable {

        @Override
        public void run() {
            Log.v(LOGTAG, "Starting store thread...");
            while (running){
                try {
                    IpfsOperation operation = ipfsOperations.take();
                        executeCmd(operation.getHash(), operation.isAdd());
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    break;
                }
            }
            Log.v(LOGTAG, "Exciting store thread...");
        }

        private void executeCmd(String hash, boolean add){

            ProcessBuilder pb;

            if (add)
                pb = new ProcessBuilder(IPFS_BINARY, "get", hash);
            else
                pb = new ProcessBuilder(IPFS_BINARY, "pin rm", hash);
            Map<String, String> env = pb.environment();
            env.put("IPFS_PATH", "/data/data/com.storeit.storeit/");
            try {
                Process process = pb.start();

                BufferedReader reader = new BufferedReader(
                        new InputStreamReader(process.getInputStream()));
                int read;
                char[] buffer = new char[4096];
                while ((read = reader.read(buffer)) > 0) {
                    Log.v("BINARY", String.valueOf(buffer, 0, read));
                }
                reader.close();
                process.waitFor();
            } catch (IOException | InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    class IpfsOperation {

        private String hash;
        private boolean add;

        public IpfsOperation(String hash, boolean add) {
            this.hash = hash;
            this.add = add;
        }

        public String getHash() {
            return hash;
        }

        public void setHash(String hash) {
            this.hash = hash;
        }

        public boolean isAdd() {
            return add;
        }

        public void setAdd(boolean add) {
            this.add = add;
        }
    }
}
