package com.storeit.storeit.protocol.command;

import com.storeit.storeit.protocol.StoreitFile;

/**
 * Created by loulo on 21/06/2016.
 */
public class JoinResponse {
    int code;
    String text;
    int commandUid;
    String command;
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
