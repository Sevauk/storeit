package com.storeit.storeit.protocol.command;

import com.storeit.storeit.protocol.StoreitFile;

/**
 * Created by loulo on 13/11/2016.
 */

public class FmovInfo {
    private String mSrc;
    private String mDst;

    public FmovInfo(String src, String dst){
        this.mSrc = src;
        this.mDst = dst;
    }

    public String getSrc(){
        return mSrc;
    }

    public String getDst(){
        return mDst;
    }
}
