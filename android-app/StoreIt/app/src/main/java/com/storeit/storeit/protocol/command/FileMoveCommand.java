package com.storeit.storeit.protocol.command;

/**
 * Created by louis on 06/07/16.
 */
public class FileMoveCommand {
    private int uid;
    private String command;
    private Parameters parameters;

    public FileMoveCommand(int uid, String command, String src, String dst) {
        this.uid = uid;
        this.command = command;
        this.parameters = new Parameters(src, dst);
    }

    public String getSrc() {
        return parameters.getSrc();
    }

    public String getDst() {
        return parameters.getDst();
    }


    class Parameters {
        String src;
        String dst;

        public  Parameters(String src, String dst){
            this.src = src;
            this.dst = dst;
        }

        public String getSrc() {
            return src;
        }

        public String getDst() {
            return dst;
        }
    }
}
