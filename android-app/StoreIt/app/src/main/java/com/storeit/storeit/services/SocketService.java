package com.storeit.storeit.services;

import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.os.SystemClock;
import android.preference.PreferenceManager;
import android.util.Log;

import com.google.gson.Gson;
import com.neovisionaries.ws.client.WebSocket;
import com.neovisionaries.ws.client.WebSocketAdapter;
import com.neovisionaries.ws.client.WebSocketException;
import com.neovisionaries.ws.client.WebSocketExtension;
import com.neovisionaries.ws.client.WebSocketFactory;
import com.neovisionaries.ws.client.WebSocketFrame;
import com.storeit.storeit.protocol.FileCommandHandler;
import com.storeit.storeit.protocol.LoginHandler;
import com.storeit.storeit.protocol.StoreitFile;
import com.storeit.storeit.protocol.command.CommandManager;
import com.storeit.storeit.protocol.command.FileCommand;
import com.storeit.storeit.protocol.command.FileDeleteCommand;
import com.storeit.storeit.protocol.command.FileMoveCommand;
import com.storeit.storeit.protocol.command.FileStoreCommand;
import com.storeit.storeit.protocol.command.JoinCommand;
import com.storeit.storeit.protocol.command.JoinResponse;
import com.storeit.storeit.protocol.command.Response;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/*
* This service handle the websocket connection
* It communicate with the ui of the app
*/
public class SocketService extends Service {


    boolean connectedtoserver = false;

    private final IBinder myBinder = new LocalBinder();

    public String server;
    private static final int TIMEOUT = 10000;
    public static final String LOGTAG = "SocketService";

    private boolean mConnected = false;
    private WebSocket webSocket = null;

    // Handlers for callback
    private LoginHandler mLoginHandler;
    private FileCommandHandler mFileCommandHandler;
    private int uid = 0;
    private String lastCmd;


    private class SocketManager implements Runnable {
        @Override
        public void run() {

            Log.v(LOGTAG, "Starting socket on thread : " + Thread.currentThread().getId());

            // Loop on connection
            mConnected = false;

            while (!mConnected) {
                try {
                    webSocket = new WebSocketFactory()
                            .setConnectionTimeout(TIMEOUT)
                            .createSocket(server)
                            .addListener(new WebSocketAdapter() {

                                public void onConnected(WebSocket websocket, Map<String, List<String>> headers)
                                {

                                }

                                public void onDisconnected(WebSocket websocket,
                                                           WebSocketFrame serverCloseFrame, WebSocketFrame clientCloseFrame,
                                                           boolean closedByServer) throws IOException, WebSocketException {
                                    mConnected = false;
                                    if (mLoginHandler != null) {
                                        //mLoginHandler.handleDisconnection();
                                    }
                                    webSocket = websocket.recreate().connect();
                                }

                                public void onTextMessage(WebSocket websocket, String message) {
                                    Log.v(LOGTAG, "received : " + message);
                                    int cmdType = CommandManager.getCommandType(message);
                                    switch (cmdType) {
                                        case CommandManager.RESP:
                                            Log.v(LOGTAG, "Response!");
                                            if (lastCmd.equals("JOIN")) {
                                                Gson gson = new Gson();
                                                JoinResponse joinResponse = gson.fromJson(message, JoinResponse.class);
                                                if (mLoginHandler != null) {
                                                    Log.v(LOGTAG, "connect");
                                                    mLoginHandler.handleJoin(joinResponse);
                                                }
                                            }
                                            break;
                                        case CommandManager.FDEL:
                                            if (mFileCommandHandler != null) {
                                                Gson gson = new Gson();
                                                FileDeleteCommand fileCommand = gson.fromJson(message, FileDeleteCommand.class);
                                                mFileCommandHandler.handleFDEL(fileCommand);
                                            }
                                            break;
                                        case CommandManager.FADD:
                                            if (mFileCommandHandler != null) {
                                                Gson gson = new Gson();
                                                FileCommand fileCommand = gson.fromJson(message, FileCommand.class);
                                                mFileCommandHandler.handleFADD(fileCommand);
                                            }
                                            break;
                                        case CommandManager.FUPT:
                                            if (mFileCommandHandler != null) {
                                                Gson gson = new Gson();
                                                FileCommand fileCommand = gson.fromJson(message, FileCommand.class);
                                                mFileCommandHandler.handleFUPT(fileCommand);
                                            }
                                            break;
                                        case CommandManager.FMOVE:
                                            if (mFileCommandHandler != null) {
                                                Gson gson = new Gson();
                                                FileMoveCommand fileMoveCommand = gson.fromJson(message, FileMoveCommand.class);
                                                mFileCommandHandler.handleFMOV(fileMoveCommand);
                                            }
                                            break;
                                        case CommandManager.FSTR:
                                            if (mFileCommandHandler != null) {
                                                Gson gson = new Gson();
                                                FileStoreCommand fileStoreCommand = gson.fromJson(message, FileStoreCommand.class);
                                                mFileCommandHandler.handleFSTR(fileStoreCommand);
                                            }
                                            break;
                                        default:
                                            Log.v(LOGTAG, "Invalid command received :/");
                                            break;
                                    }
                                }
                            })
                            .addExtension(WebSocketExtension.PERMESSAGE_DEFLATE)
                            .setMaxPayloadSize(128000)
                            .connect();

                    mConnected = true;
                    Log.v(LOGTAG, "mConnected : " + mConnected);
                    Log.v(LOGTAG, "mLoginHandler : " + (mLoginHandler != null));

                    if (mLoginHandler != null)
                    {
                        Log.v(LOGTAG, "call handleConnection()");
                        mLoginHandler.handleConnection(true);
                    }

                } catch (WebSocketException | IOException e) {
                    e.printStackTrace();
                    mConnected = false;
                    Log.e(LOGTAG, "Cannot connect to server... Retrying in 5 seconds");
                    mLoginHandler.handleConnection(false);
                    SystemClock.sleep(5000);
                }
            }
        }
    }

    public boolean sendJOIN(String authType, String token) {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        JoinCommand cmd = new JoinCommand(uid, authType, token);
        webSocket.sendText(gson.toJson(cmd));
        uid++;
        lastCmd = "JOIN";

        return true;
    }

    public boolean sendFADD(StoreitFile newFile) {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        FileCommand cmd = new FileCommand(uid, "FADD", newFile);
        webSocket.sendText(gson.toJson(cmd));
        uid++;
        lastCmd = "FADD";

        return true;
    }

    public boolean sendFDEL(StoreitFile newFile) {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        FileDeleteCommand cmd = new FileDeleteCommand(uid, "FDEL", newFile);
        webSocket.sendText(gson.toJson(cmd));
        uid++;
        lastCmd = "FDEL";

        return true;
    }

    public boolean sendFUPT(StoreitFile newFile) {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        FileCommand cmd = new FileCommand(uid, "FUPT", newFile);
        webSocket.sendText(gson.toJson(cmd));
        uid++;
        lastCmd = "FUPT";

        return true;
    }

    public boolean sendFMOV(String src, String dst) {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        FileMoveCommand cmd = new FileMoveCommand(uid, "FMOV", src, dst);
        webSocket.sendText(gson.toJson(cmd));

        Log.v("FMOV", gson.toJson(cmd));

        uid++;
        lastCmd = "FMOV";

        return true;
    }

    public boolean sendRSPONSE() {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        Response response = new Response(0, "OK", uid, "RESP");

        return true;
    }

    public void setmLoginHandler(LoginHandler handler) {
        mLoginHandler = handler;
        if (mConnected)
        {
            Log.v(LOGTAG, "call handleConnection()");
            mLoginHandler.handleConnection(true);
        }

    }

    public void setFileCommandandler(FileCommandHandler handler) {
        mFileCommandHandler = handler;
    }

    @Override
    public IBinder onBind(Intent intent) {
        Log.v(LOGTAG, "Socket service binded.....");
        return myBinder;
    }

    public class LocalBinder extends Binder {
        public SocketService getService() {
            return SocketService.this;
        }
    }

    private Thread socketThread;

    public void stopSocketThread(){
        if (socketThread != null){
            webSocket.disconnect();
            socketThread.interrupt();
            socketThread = null;
            Log.v(LOGTAG, "stopSocketThread");
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();


        SharedPreferences SP = PreferenceManager.getDefaultSharedPreferences(this);
//        server = SP.getString("pref_key_server_url", "ws://192.168.1.24:7641");

        server = "ws://137.74.161.134:7641";

        socketThread = new Thread(new SocketManager());
        socketThread.start();

    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        super.onStartCommand(intent, flags, startId);
        return START_NOT_STICKY;
    }


    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.v(LOGTAG, "On destroy :o");
    }

    @Override
    public void onRebind(Intent intent){
        Log.v(LOGTAG, "putain");

        super.onRebind(intent);

    }

    @Override
    public boolean onUnbind(Intent intent){
        Log.v(LOGTAG, "Socket unbinded!");
        return true;
    }

    public boolean isConnected() {
        return mConnected;
    }


}
