package com.storeit.storeit.protocol.command;

/**
 * Created by loulo on 22/01/2017.
 */

public class RefreshCommand {
    private int uid;
    private String command;

    public RefreshCommand(int uid) {
        this.uid = uid;
        command = "RFSH";
    }
}
