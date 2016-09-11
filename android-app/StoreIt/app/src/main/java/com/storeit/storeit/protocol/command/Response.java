package com.storeit.storeit.protocol.command;

/**
 * Created by louis on 18/07/16.
 */
public class Response {
    int code;
    String text;
    int commandUid;
    String command;

    public Response(int code, String text, int commandUid, String command) {
        this.code = code;
        this.text = text;
        this.commandUid = commandUid;
        this.command = command;
    }

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
}
