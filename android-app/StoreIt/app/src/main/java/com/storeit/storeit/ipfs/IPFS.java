package com.storeit.storeit.ipfs;

import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.HttpURLConnection;
import java.net.URL;

import static java.lang.System.currentTimeMillis;

/**
 * IPFS gateway wrapper
 * allows to upload files via http post request
 * and download files via http get request
 */
public class IPFS {

    private String m_nodeUrl;
    private static final String CRLF = "\r\n";
    private static final String CHARSET = "UTF-8";
    private static final int CONNECT_TIMEOUT = 15000;
    private static final int READ_TIMEOUT = 10000;

    /**
     * @param url The url of the ipfs gateway
     */
    public IPFS(String url){
        m_nodeUrl = url;
    }

    /**
     * @param uploadFile the file to be uploaded
     * @return the response of the ipfs gateway or empty string if error
     */
    public String sendFile(File uploadFile){
        HttpURLConnection connection;
        OutputStream outputStream;
        PrintWriter writer;
        String boundary;
        URL url;

        m_nodeUrl = "http://192.168.1.24";

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

            // Read file and write binary
            try (final FileInputStream inputStream = new FileInputStream(uploadFile)) {
                final byte[] buffer = new byte[4096]; // read up to 4096 bytes each time
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
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
    public boolean downloadFile(FileOutputStream downloadFile, String hash){

        HttpURLConnection connection;
        URL url;

        m_nodeUrl = "https://ipfs.io/ipfs/";
        try {
            url = new URL(m_nodeUrl + hash);
            connection = (HttpURLConnection)url.openConnection();

            connection.setRequestMethod("GET"); // Create the get request

            int responseCode = connection.getResponseCode();
            if (responseCode != HttpURLConnection.HTTP_OK)
                return  false;

            // Get connection stream
            InputStream is = connection.getInputStream();
            // Byte wich will contain the response byte
            byte[] buffer = new byte[4096];

            int bytesRead;
            while ((bytesRead = is.read(buffer)) != -1) {
                downloadFile.write(buffer, 0, bytesRead);
            }
            downloadFile.close();

        } catch (IOException e) {
            e.printStackTrace();
        }
        return true;
    }
}
