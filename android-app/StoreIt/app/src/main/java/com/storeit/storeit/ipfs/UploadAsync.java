package com.storeit.storeit.ipfs;

import android.app.Notification;
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

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Date;

import static java.lang.System.currentTimeMillis;

public class UploadAsync extends AsyncTask<String, Integer, String> {

    private static final String CRLF = "\r\n";
    private static final String CHARSET = "UTF-8";
    private static final int CONNECT_TIMEOUT = 15000;
    private static final int READ_TIMEOUT = 10000;

    private NotificationManager mNotifyManager;
    private android.support.v4.app.NotificationCompat.Builder mBuilder;
    private int id = 1;
    private MainActivity mContext;
    private SocketService mService;

    public UploadAsync(MainActivity context, SocketService service) {
        mContext = context;
        mService = service;
    }

    protected void onPreExecute() {
        super.onPreExecute();

        mNotifyManager = (NotificationManager) mContext.getSystemService(Context.NOTIFICATION_SERVICE);
        mBuilder = new NotificationCompat.Builder(mContext)
                .setContentTitle("StoreIt")
                .setContentText("Upload in progress")
                .setSmallIcon(R.drawable.ic_insert_drive_file_black_24dp);
        mBuilder.setProgress(100, 0, false);


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

                FileViewerFragment fragment = (FileViewerFragment) currentFragment;

                // Create new storeit file and add it
                StoreitFile newFile;

                if (fragment.getCurrentFile().getPath().equals("/")) {
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
    protected void onProgressUpdate(Integer... progress) {
        mBuilder.setProgress(100, progress[0], false);
        mNotifyManager.notify(id, mBuilder.build());
    }

    @Override
    protected String doInBackground(String... params) {

        File uploadFile = new File(params[0]);

        HttpURLConnection connection;
        OutputStream outputStream;
        PrintWriter writer;
        String boundary;
        URL url;

        String m_nodeUrl = "http://192.168.1.24";

        try {
            url = new URL(m_nodeUrl + ":5001/api/v0/add?stream-cannels=true");

            // Create request
            boundary = "---------------------------" + currentTimeMillis();
            connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(CONNECT_TIMEOUT);
            connection.setReadTimeout(READ_TIMEOUT);
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Accept-Charset", CHARSET);
            connection.setRequestProperty("Content-Type", "multipart/form-data; boundary=" + boundary);
            connection.setUseCaches(false);
            connection.setDoInput(true);
            connection.setDoOutput(true);

            outputStream = connection.getOutputStream();
            writer = new PrintWriter(new OutputStreamWriter(outputStream, CHARSET),
                    true);

            // Content of the request
            writer.append("--").append(boundary).append(CRLF)
                    .append("Content-Type: application/octet-stream")
                    .append(CRLF)
                    .append("Content-Disposition : file; name=\"file\"; filename=\"")
                    .append(uploadFile.getName())
                    .append("\"")
                    .append(CRLF)
                    .append("Content-Transfer-Encoding: binary")
                    .append(CRLF)
                    .append(CRLF);

            writer.flush();
            outputStream.flush();

            long fileSize = uploadFile.length();
            long total = 0;
            Integer count;

            long startTime = System.currentTimeMillis();
            long elapsedTime = 0L;
            // Read file and write binary
            try (final FileInputStream inputStream = new FileInputStream(uploadFile)) {
                final byte[] buffer = new byte[4096]; // read up to 4096 bytes each time
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                    total += bytesRead;
                    count = (int) (total * 100 / fileSize);

                    elapsedTime = System.currentTimeMillis() - startTime;

                    if (elapsedTime > 500) {
                        publishProgress(count);
                        startTime = System.currentTimeMillis();
                    }
                }
                outputStream.flush();
            }
            writer.append(CRLF);
            writer.append(CRLF).append("--").append(boundary).append("--")
                    .append(CRLF);
            writer.close();

            int status = connection.getResponseCode();
            if (status != HttpURLConnection.HTTP_OK) {
                Log.v("IPFS", "IPFS http error");
                return "";
            }

            // Read request response
            InputStream is = connection.getInputStream();
            ByteArrayOutputStream response = new ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
            int bytesRead;


            while ((bytesRead = is.read(buffer)) != -1) {
                response.write(buffer, 0, bytesRead);

            }
            return response.toString(CHARSET);

        } catch (IOException e) {
            e.printStackTrace();
        }
        return "";
    }
}