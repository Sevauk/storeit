package com.storeit.storeit.protocol.command;

/**
 * Created by loulo on 13/11/2016.
 */

public class ConnectionInfo {
    private String mMethod;
    private String mToken;

    public ConnectionInfo(String method, String token) {
        mMethod = method;
        mToken = token;
    }

    public String getMethod() {
        return mMethod;
    }

    public String getToken() {
        return mToken;
    }
}
