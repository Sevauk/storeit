package com.storeit.storeit.services;

import android.os.Message;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.neovisionaries.ws.client.WebSocket;
import com.neovisionaries.ws.client.WebSocketAdapter;
import com.neovisionaries.ws.client.WebSocketException;
import com.neovisionaries.ws.client.WebSocketExtension;
import com.neovisionaries.ws.client.WebSocketFactory;
import com.neovisionaries.ws.client.WebSocketFrame;
import com.storeit.storeit.protocol.StoreitFile;
import com.storeit.storeit.protocol.command.CommandManager;
import com.storeit.storeit.protocol.command.ConnectionInfo;
import com.storeit.storeit.protocol.command.FileCommand;
import com.storeit.storeit.protocol.command.FileDeleteCommand;
import com.storeit.storeit.protocol.command.FileMoveCommand;
import com.storeit.storeit.protocol.command.FileRefreshResponse;
import com.storeit.storeit.protocol.command.FileStoreCommand;
import com.storeit.storeit.protocol.command.FmovInfo;
import com.storeit.storeit.protocol.command.JoinCommand;
import com.storeit.storeit.protocol.command.JoinResponse;
import com.storeit.storeit.protocol.command.RefreshCommand;
import com.storeit.storeit.protocol.command.Response;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/*
* This service handle the websocket connection
* It communicate with the ui of the app
*/
public class SocketService extends AbstractService {

    public static final String LOGTAG = "SocketService";

    // Messages
    public static final int SOCKET_CONNECTED = 1;
    public static final int SOCKET_DISCONNECTED = 2;
    public static final int RECONNECT_SOCKET_JOIN = 16;
    public static final int SOCKET_CONNECTION_ERROR = 17;
    public static final int JOIN_FAILED = 18;
    public static final int SEND_JOIN = 3;
    public static final int SEND_FADD = 4;
    public static final int SEND_FDEL = 5;
    public static final int SEND_FUPT = 6;
    public static final int SEND_FMOV = 7;
    public static final int SEND_RFSH = 16;
    public static final int SEND_RESPONSE = 8;
    public static final int JOIN_RESPONSE = 9;
    public static final int HANDLE_FADD = 10;
    public static final int HANDLE_FDEL = 11;
    public static final int HANDLE_FUPT = 12;
    public static final int HANDLE_FMOV = 13;
    public static final int HANDLE_FSTR = 14;
    public static final int HANDLE_RFSH = 15;



    // Websockets
    private static final int TIMEOUT = 10000;
//    private static final String SERVER = "ws://louismondesir.me:7641";
    //private static final String SERVER = "ws://iglu.mobi:7641";
    private static final String SERVER = "ws://192.168.0.17:7641";

    private WebSocket mWebSocket = null;
    private Thread mSocketThread = null;
    private boolean mConnected = false;

    // Protocol needed
    private int mUID = 0;
    private String mLastCmd;


    private class WebsocketManager implements Runnable {
        @Override
        public void run() {
            try {
                mWebSocket = new WebSocketFactory()
                        .setConnectionTimeout(TIMEOUT)
                        .createSocket(SERVER)
                        .addListener(new WebSocketAdapter() {
                            public void onConnected(WebSocket websocket, Map<String, List<String>> headers) {
                                mConnected = true;
                                Log.i(LOGTAG, "Socket connected to server");
                                send(Message.obtain(null, SOCKET_CONNECTED));
                            }

                            public void onDisconnected(WebSocket websocket,
                                                       WebSocketFrame serverCloseFrame, WebSocketFrame clientCloseFrame,
                                                       boolean closedByServer) {
                                mConnected = false;
                                Log.i(LOGTAG, "Socket diconnected from server");

                                send(Message.obtain(null, SOCKET_DISCONNECTED));
                            }

                            public void onTextMessage(WebSocket websocket, String message) {
                                Log.i(LOGTAG, "received : " + message);

                                Gson gson = new Gson();

                                int cmdType = CommandManager.getCommandType(message);
                                switch (cmdType) {
                                    case CommandManager.FADD:
                                        try {
                                            FileCommand addCMD = gson.fromJson(message, FileCommand.class);
                                            send(Message.obtain(null, HANDLE_FADD, addCMD));
                                            mLastCmd = "FADD";
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                        }
                                        break;
                                    case CommandManager.FDEL:
                                        try {
                                            FileDeleteCommand delCMD = gson.fromJson(message, FileDeleteCommand.class);
                                            send(Message.obtain(null, HANDLE_FDEL, delCMD));
                                            mLastCmd = "FDEL";
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                        }
                                        break;
                                    case CommandManager.FMOVE:
                                        try {
                                            FileMoveCommand movCMD = gson.fromJson(message, FileMoveCommand.class);
                                            send(Message.obtain(null, HANDLE_FMOV, movCMD));
                                            mLastCmd = "FMOV";
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                        }
                                        break;
                                    case CommandManager.FSTR:
                                        try {
                                            FileStoreCommand strCMD = gson.fromJson(message, FileStoreCommand.class);
                                            send(Message.obtain(null, HANDLE_FSTR, strCMD));
                                            mLastCmd = "FSTR";
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                        }
                                        break;
                                    case CommandManager.FUPT:
                                        try {
                                            FileCommand uptCMD = gson.fromJson(message, FileCommand.class);
                                            send(Message.obtain(null, HANDLE_FUPT, uptCMD));
                                            mLastCmd = "FUPT";
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                        }
                                        break;
                                    case CommandManager.RESP:
                                        if (mLastCmd.equals("JOIN")) {
                                            try {
                                                JoinResponse joinResponse = gson.fromJson(message, JoinResponse.class);
                                                send(Message.obtain(null, JOIN_RESPONSE, joinResponse));
                                            } catch (Exception e) {
                                                e.printStackTrace();
                                                send(Message.obtain(null, JOIN_FAILED));
                                            }
                                        } else if (mLastCmd.equals("RFSH")) {
                                            try {
                                                FileRefreshResponse rshResponse = gson.fromJson(message, FileRefreshResponse.class);
                                                send(Message.obtain(null, HANDLE_RFSH, rshResponse));
                                            } catch (Exception e) {
                                                e.printStackTrace();
                                            }
                                        }
                                        mLastCmd = "RESP";
                                        break;
                                    default:
                                        Log.i(LOGTAG, "Invalid command received");
                                        break;
                                }
                            }
                        })
                        .addExtension(WebSocketExtension.PERMESSAGE_DEFLATE)
                        .setMaxPayloadSize(25600000)
                        .connect();
            } catch (WebSocketException | IOException e) {
                e.printStackTrace();
                if (mWebSocket != null)
                    mWebSocket.disconnect();
                mConnected = false;
            }
        }
    }

    @Override
    public void onStartService() {
    }

    @Override
    public void onStopService() {
        Log.i(LOGTAG, "Disconnecting websocket...");
        if (mWebSocket != null)
            mWebSocket.disconnect();
    }

    @Override
    public void onReceiveMessage(Message msg) {
        switch (msg.what) {
            case MSG_REGISTER_CLIENT:
                Log.i(LOGTAG, "Starting network!");
                if (mSocketThread == null) {
                    mSocketThread = new Thread(new WebsocketManager());
                    mSocketThread.start();
                }
                break;
            case SocketService.SEND_FADD:
                sendFADD((StoreitFile) msg.obj);
                break;
            case SocketService.SEND_FDEL:
                sendFDEL((StoreitFile) msg.obj);
                break;
            case SocketService.SEND_FMOV:
                FmovInfo movInfo = (FmovInfo) msg.obj;
                sendFMOV(movInfo.getSrc(), movInfo.getDst());
                break;
            case SocketService.SEND_FUPT:
                sendFUPT((StoreitFile) msg.obj);
                break;
            case SocketService.SEND_JOIN:
                sendJOIN((ConnectionInfo) msg.obj);
                break;
            case SocketService.SEND_RESPONSE:
                sendRESP(msg.arg1);
                break;
            case SocketService.SEND_RFSH:
                sendRFSH();
                break;
            default:
                break;
        }
    }

    private boolean sendRFSH() {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        RefreshCommand cmd = new RefreshCommand(mUID);
        mWebSocket.sendText(gson.toJson(cmd));
        mUID++;
        mLastCmd = "RFSH";

        return true;
    }

    private boolean sendJOIN(ConnectionInfo info) {
        if (!mConnected)
            return false;

        Log.i(LOGTAG, "Sending join command " + info.getMethod() + " " + info.getToken());

        Gson gson = new Gson();
        JoinCommand cmd = new JoinCommand(mUID, info.getMethod(), info.getToken(), info.getHosting());
        mWebSocket.sendText(gson.toJson(cmd));
        mUID++;
        mLastCmd = "JOIN";

        return true;
    }

    private boolean sendFADD(StoreitFile newFile) {
        if (!mConnected)
            return false;

        Log.v(LOGTAG, "Adding : " + newFile.getFileName());

        Gson gson = new Gson();
        FileCommand cmd = new FileCommand(mUID, "FADD", newFile);
        mWebSocket.sendText(gson.toJson(cmd));
        mUID++;
        mLastCmd = "FADD";

        return true;
    }

    private boolean sendFDEL(StoreitFile newFile) {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        FileDeleteCommand cmd = new FileDeleteCommand(mUID, "FDEL", newFile);
        mWebSocket.sendText(gson.toJson(cmd));
        mUID++;
        mLastCmd = "FDEL";

        return true;
    }

    private boolean sendFUPT(StoreitFile newFile) {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        FileCommand cmd = new FileCommand(mUID, "FUPT", newFile);
        mWebSocket.sendText(gson.toJson(cmd));
        mUID++;
        mLastCmd = "FUPT";

        return true;
    }

    private boolean sendFMOV(String src, String dst) {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        FileMoveCommand cmd = new FileMoveCommand(mUID, "FMOV", src, dst);
        mWebSocket.sendText(gson.toJson(cmd));
        Log.v("FMOV", gson.toJson(cmd));
        mUID++;
        mLastCmd = "FMOV";
        return true;
    }

    private boolean sendRESP(int success) {
        if (!mConnected)
            return false;

        Gson gson = new Gson();
        Response response;

        if (success == 0) {
            response = new Response(0, "OK", mUID, "RESP");
        } else {
            response = new Response(1, "ERROR", mUID, "RESP");
        }

        mWebSocket.sendText(gson.toJson(response));

        return true;
    }
}
