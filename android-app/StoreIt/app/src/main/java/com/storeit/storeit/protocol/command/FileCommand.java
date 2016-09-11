package com.storeit.storeit.protocol.command;

import com.storeit.storeit.protocol.StoreitFile;


/**
 * This class will be used for FDEL, FADD, FUPT command
 * Can be send or received
 */
public class FileCommand {
    private int uid;
    private String command;
    private Parameters parameters;

    public FileCommand(int uid, String command, StoreitFile files) {
        this.uid = uid;
        this.command = command;
        this.parameters = new Parameters(files);
    }

    public StoreitFile getFiles() {
        return parameters.getFiles();
    }


    class Parameters {
        StoreitFile[] files;

        public  Parameters(StoreitFile files){
            this.files = new StoreitFile[]{files};
        }

        public StoreitFile getFiles() {
            return files[0];
        }
    }
}
