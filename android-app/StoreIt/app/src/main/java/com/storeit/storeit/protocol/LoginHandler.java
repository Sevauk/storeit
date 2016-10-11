package com.storeit.storeit.protocol;

import com.storeit.storeit.protocol.command.JoinResponse;

/**
 * Created by loulo on 02/05/2016.
 */
public interface LoginHandler {
    public void handleJoin(JoinResponse joinResponse);
    public void handleConnection(boolean success);
    public void handleDisconnection();
}
