package com.storeit.storeit.protocol.command;

import com.storeit.storeit.protocol.StoreitFile;

/**
 * Created by loulo on 01/07/2016.
 */
public class FileDeleteCommand {
    private int uid;
    private String command;
    private Parameters parameters;

    public FileDeleteCommand(int uid, String command, StoreitFile files) {
        this.uid = uid;
        this.command = command;
        this.parameters = new Parameters(files.getPath());
    }

    public String getFiles() {
        return parameters.getFiles();
    }


    class Parameters {
        String[] files;

        public  Parameters(String files){
            this.files = new String[]{files};
        }

        public String getFiles() {
            return files[0];
        }
    }
}
