package com.storeit.storeit.protocol.command;

import java.util.ArrayList;

/**
 * Created by loulo on 21/06/2016.
 */
public class JoinCommand {
    int uid;
    String command;
    Parameters parameters;


    public JoinCommand(int uid, String type, String accessToken, ArrayList<String> hosting) {
        this.uid = uid;
        this.command = "JOIN";
        this.parameters = new Parameters(type, accessToken, hosting);
    }

    class Parameters {
        Auth auth;
        ArrayList<String> hosting;

        public Parameters(String type, String accessToken, ArrayList<String> hosting) {
            auth = new Auth(type, accessToken);
            this.hosting = hosting;
        }
    }

    class Auth {
        String type;
        String accessToken;

        public Auth(String type, String accessToken) {
            this.type = type;
            this.accessToken = accessToken;
        }
    }
}
