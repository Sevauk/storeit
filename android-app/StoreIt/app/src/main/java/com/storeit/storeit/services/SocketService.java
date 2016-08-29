package com.storeit.storeit.services;

import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Binder;
import android.os.IBinder;
import android.os.SystemClock;
import android.preference.PreferenceManager;
import android.util.Log;
import android.widget.Toast;

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

/*
* This service handle the websocket connection
* It communicate with the ui of the app
*/
public class SocketService extends Service {

    private final IBinder myBinder = new LocalBinder();

    public String server = "ws://192.168.0.102:7641";
    private static final int TIMEOUT = 5000;
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

            // Loop on connection
            mConnected = false;

            while (!mConnected) {
                try {
                    webSocket = new WebSocketFactory()
                            .setConnectionTimeout(TIMEOUT)
                            .createSocket(server)
                            .addListener(new WebSocketAdapter() {

                                public void onDisconnected(WebSocket websocket,
                                                           WebSocketFrame serverCloseFrame, WebSocketFrame clientCloseFrame,
                                                           boolean closedByServer) throws IOException, WebSocketException {
                                    mConnected = false;
                                    if (mLoginHandler != null){
                                        //mLoginHandler.handleDisconnection();
                                    }
                                    webSocket = websocket.recreate().connect();
                                }

                                public void onTextMessage(WebSocket websocket, String message) {
                                    Log.v(LOGTAG, "received : " + message);
                                    int cmdType = CommandManager.getCommandType(message);
                                    Log.v(LOGTAG, "Command : " +  cmdType);
                                    switch (cmdType) {
                                        case CommandManager.RESP:
                                            if (lastCmd.equals("JOIN")) {
                                                Gson gson = new Gson();
                                                JoinResponse joinResponse = gson.fromJson(message, JoinResponse.class);
                                                if (mLoginHandler != null) {
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
                            .connect();
                    mConnected = true;
                } catch (WebSocketException | IOException e) {
                    e.printStackTrace();
                    mConnected = false;
                    Log.e(LOGTAG, "Cannot connect to server... Retrying in 5 seconds");
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
    }

    public void setFileCommandandler(FileCommandHandler handler) {
        mFileCommandHandler = handler;
    }

    @Override
    public IBinder onBind(Intent intent) {
        Log.v(LOGTAG, "OnBind :)");
        return myBinder;
    }

    public class LocalBinder extends Binder {
        public SocketService getService() {
            return SocketService.this;
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();


        SharedPreferences SP = PreferenceManager.getDefaultSharedPreferences(this);
        server = SP.getString("pref_key_server_url", "ws://192.168.1.3:7641");

        server = "ws://121.181.166.188:7641";

        Thread t = new Thread(new SocketManager());
        t.start();
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

    public boolean isConnected() {
        return mConnected;
    }
}
