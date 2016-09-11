package com.storeit.storeit.protocol.command;

/**
 * Created by louis on 16. 8. 5.
 */
public class FileStoreCommand {
    private int uid;
    private String command;
    private Parameters parameters;

    public String getHash() {
        return parameters.hash;
    }

    public boolean shouldKeep() {
        return parameters.keep;
    }

    class Parameters {
        String hash;
        boolean keep;
    }
}
