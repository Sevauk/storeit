package com.storeit.storeit.activities;

import android.Manifest;
import android.accounts.AccountManager;
import android.app.Activity;
import android.app.Dialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookException;
import com.facebook.FacebookSdk;
import com.facebook.login.LoginResult;
import com.facebook.login.widget.LoginButton;
import com.google.android.gms.auth.GoogleAuthUtil;
import com.google.android.gms.auth.GooglePlayServicesAvailabilityException;
import com.google.android.gms.auth.UserRecoverableAuthException;
import com.google.android.gms.common.AccountPicker;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.common.SignInButton;
import com.google.gson.Gson;
import com.storeit.storeit.R;
import com.storeit.storeit.oauth.GetUsernameTask;
import com.storeit.storeit.protocol.LoginHandler;
import com.storeit.storeit.protocol.command.JoinResponse;
import com.storeit.storeit.services.SocketService;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/*
* Login Activity
* Create tcp service if it's not launched
*/
public class LoginActivity extends Activity {

    static final int REQUEST_CODE_PICK_ACCOUNT = 1000;
    static final int REQUEST_CODE_RECOVER_FROM_PLAY_SERVICES_ERROR = 1001;

    private boolean mIsBound = false;
    private boolean destroyService = true;
    private SocketService mBoundService = null;
    private String mEmail;
    String SCOPE = "oauth2:https://www.googleapis.com/auth/userinfo.email";

    private LoginHandler mLoginHandler = new LoginHandler() {
        @Override
        public void handleJoin(final JoinResponse joinResponse) {

            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (joinResponse.getCode() == 0) {

                        // The service will be handled by MainActivity;
                        destroyService = false;

                        Intent intent = new Intent(LoginActivity.this, MainActivity.class);

                        // Stringify fileobject in order to pass it to other activity. It will be save on disk
                        // So passing as string is fine
                        Gson gson = new Gson();
                        String homeJson = gson.toJson(joinResponse.getParameters().getHome());

                        intent.putExtra("home", homeJson);
                        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                        startActivity(intent);
                    } else {
                        Toast.makeText(LoginActivity.this, joinResponse.getText(), Toast.LENGTH_LONG).show();
                    }
                }
            });
        }
    };

    private void pickUserAccount() {
        String[] accountTypes = new String[]{GoogleAuthUtil.GOOGLE_ACCOUNT_TYPE};
        Intent intent = AccountPicker.newChooseAccountIntent(null, null,
                accountTypes, true, "Please choose account", null, null, null);
        startActivityForResult(intent, REQUEST_CODE_PICK_ACCOUNT);
    }

    private void getUsername() {
        if (mEmail == null) {
            pickUserAccount();
        } else {
            new GetUsernameTask(LoginActivity.this, mEmail, SCOPE).execute();
        }
    }

    // Google+ token received, sending join cmd
    public void tokenReceived(final String token) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mBoundService.sendJOIN("gg", token);
            }
        });
    }

    public void handleException(final Exception e) {

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (e instanceof GooglePlayServicesAvailabilityException) {
                    int statusCode = ((GooglePlayServicesAvailabilityException) e)
                            .getConnectionStatusCode();
                    Dialog dialog = GooglePlayServicesUtil.getErrorDialog(statusCode,
                            LoginActivity.this,
                            REQUEST_CODE_RECOVER_FROM_PLAY_SERVICES_ERROR);
                    dialog.show();
                } else if (e instanceof UserRecoverableAuthException) {
                    Intent intent = ((UserRecoverableAuthException) e).getIntent();
                    startActivityForResult(intent,
                            REQUEST_CODE_RECOVER_FROM_PLAY_SERVICES_ERROR);
                }
            }
        });
    }

    private ServiceConnection mConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            mBoundService = ((SocketService.LocalBinder) service).getService();
            mBoundService.setmLoginHandler(mLoginHandler);
            mIsBound = true;
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            mBoundService = null;
            mIsBound = false;
        }
    };

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_CODE_PICK_ACCOUNT) {
            if (resultCode == RESULT_OK) {
                mEmail = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME);
                getUsername();
            } else if (resultCode == RESULT_CANCELED) {
                Toast.makeText(this, "Error while obtaining account", Toast.LENGTH_SHORT).show();
            }
        } else if ((
                requestCode == REQUEST_CODE_RECOVER_FROM_PLAY_SERVICES_ERROR)
                && resultCode == RESULT_OK) {
            getUsername();
        }
        callbackManager.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onStart() {
        super.onStart();

        Intent socketService = new Intent(this, SocketService.class);
        bindService(socketService, mConnection, Context.BIND_AUTO_CREATE);
    }

    @Override
    protected void onStop() {
        super.onStop();

        if (mIsBound && destroyService) {
            unbindService(mConnection);
            mIsBound = false;
        }
    }

    LoginButton fbButton;
    private CallbackManager callbackManager;

    private static final int PERMISSIONS_REQUEST_WRITE_EXTERNAL = 1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FacebookSdk.sdkInitialize(getApplicationContext());
        setContentView(R.layout.activity_login);

        SignInButton button = (SignInButton) findViewById(R.id.google_login);
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                pickUserAccount();
            }
        });

        Button developerButton = (Button)findViewById(R.id.developer_login);
        developerButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mBoundService.sendJOIN("gg", "developer");
            }
        });

        callbackManager = CallbackManager.Factory.create();
        fbButton = (LoginButton) findViewById(R.id.facebook_login);

        fbButton.registerCallback(callbackManager, new FacebookCallback<LoginResult>() {
            @Override
            public void onSuccess(LoginResult loginResult) {
                Log.d("LoginActivity", loginResult.getAccessToken().getToken());
                mBoundService.sendJOIN("fb", loginResult.getAccessToken().getToken());
            }

            @Override
            public void onCancel() {

            }

            @Override
            public void onError(FacebookException error) {

            }
        });

        if (ContextCompat.checkSelfPermission(this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            if (ActivityCompat.shouldShowRequestPermissionRationale(this,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE)) {

            } else {
                ActivityCompat.requestPermissions(this,
                        new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE},
                        PERMISSIONS_REQUEST_WRITE_EXTERNAL
                );
            }
        }

        copyIpfs();

        new Thread(new Runnable() {
            @Override
            public void run() {
                launchCommand(Arrays.asList("/data/data/com.storeit.storeit/ipfs", "daemon"));
            }
        }).start();

    }

    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           String Permissions[], int[] grantResults) {
        switch (requestCode) {
            case PERMISSIONS_REQUEST_WRITE_EXTERNAL:
                if (grantResults.length > 0
                        && grantResults[0] != PackageManager.PERMISSION_GRANTED) {
                    Toast.makeText(this, "We need to access sdcard", Toast.LENGTH_SHORT).show();
                }
                break;
        }
    }

    void copyIpfs() {
        File file = new File("/data/data/com.storeit.storeit/ipfs"); // Check if ipfs is already copied
        if (file.exists()) {
            return;
        }

        try {
            InputStream is = getAssets().open("ipfs"); // Copy file
            OutputStream os = new FileOutputStream(file);

            int len = 0;
            byte[] buffer = new byte[1024];
            while ((len = is.read(buffer)) > 0) {
                os.write(buffer, 0, len);
            }
            os.close();

            launchCommand(Arrays.asList("/system/bin/chmod",
                    "751",
                    "/data/data/com.storeit.storeit/ipfs"));
            launchCommand(Arrays.asList("/data/data/com.storeit.storeit/ipfs", "init"));

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    void launchCommand(List<String> args) {
        ProcessBuilder pb = new ProcessBuilder(args);
        Map<String, String> env = pb.environment();
        env.put("IPFS_PATH", "/data/data/com.storeit.storeit/");

        try {
            Process process = pb.start();

            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream()));
            int read;
            char[] buffer = new char[4096];
//            StringBuffer output = new StringBuffer();
            while ((read = reader.read(buffer)) > 0) {
//                output.append(buffer, 0, read);
                Log.v("BINARY", String.valueOf(buffer, 0, read));
            }
            reader.close();
            process.waitFor();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}