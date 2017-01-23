package com.storeit.storeit.protocol.command;

import com.google.gson.annotations.SerializedName;
import com.storeit.storeit.protocol.StoreitFile;

/**
 * Created by loulo on 22/01/2017.
 */

public class FileRefreshResponse {

    int code;
    String text;
    int commandUid;
    String command;

    @SerializedName("parameters")
    Parameters parameters;

    public int getCode() {
        return code;
    }

    public String getText() {
        return text;
    }

    public int getCommandUid() {
        return commandUid;
    }

    public String getCommand() {
        return command;
    }

    public Parameters getParameters() {
        return parameters;
    }

    public class Parameters{
        StoreitFile home;

        public StoreitFile getHome() {
            return home;
        }
    }
}
