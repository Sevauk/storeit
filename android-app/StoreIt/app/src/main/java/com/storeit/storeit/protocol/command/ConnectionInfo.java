package com.storeit.storeit.protocol.command;

import java.util.ArrayList;

/**
 * Created by loulo on 13/11/2016.
 */

public class ConnectionInfo {
    private String mMethod;
    private String mToken;
    private ArrayList<String> hosting;

    public ConnectionInfo(String method, String token, ArrayList<String> hosting) {
        mMethod = method;
        mToken = token;
        this.hosting = hosting;
    }

    public String getMethod() {
        return mMethod;
    }

    public String getToken() {
        return mToken;
    }

    public  ArrayList<String> getHosting() {return hosting;}
}
