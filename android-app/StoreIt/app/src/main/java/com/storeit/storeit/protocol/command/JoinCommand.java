package com.storeit.storeit.protocol.command;

/**
 * Created by loulo on 21/06/2016.
 */
public class JoinCommand {
    int uid;
    String command;
    Parameters parameters;


    public JoinCommand(int uid, String type, String accessToken){
        this.uid = uid;
        this.command = "JOIN";
        this.parameters = new Parameters(type, accessToken);
    }

    class Parameters{
        Auth auth;
        String[] hosting;

        public Parameters(String type, String accessToken){
            this.hosting = new String[0];
            auth = new Auth(type, accessToken);
        }
    }

    class Auth{
        String type;
        String accessToken;

        public  Auth(String type, String accessToken){
            this.type = type;
            this.accessToken = accessToken;
        }
    }
}
