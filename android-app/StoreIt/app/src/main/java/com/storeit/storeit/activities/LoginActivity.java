package com.storeit.storeit.activities;

import android.Manifest;
import android.accounts.AccountManager;
import android.app.Activity;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageButton;
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
import com.storeit.storeit.services.IpfsService;
import com.storeit.storeit.services.SocketService;

import java.util.Arrays;

/*
* Login Activity
* Create tcp service if it's not launched
*/
public class LoginActivity extends Activity {

    static final int REQUEST_CODE_PICK_ACCOUNT = 1000;
    static final int REQUEST_CODE_RECOVER_FROM_PLAY_SERVICES_ERROR = 1001;

    private boolean mSocketServiceBound = false;
    private boolean mIpfsServiceBound = false;

    private boolean destroySocketService = true;
    private boolean destroyIpfsService = true;

    private SocketService mSocketService = null;
    private IpfsService mIpfsService = null;
    private String mEmail;
    String SCOPE = "oauth2:https://www.googleapis.com/auth/userinfo.email";

    private boolean autologin = false;
    private ProgressDialog progessDialog = null;

    private String m_token = "";
    private String m_method = "";


    private LoginHandler mLoginHandler = new LoginHandler() {
        @Override
        public void handleJoin(final JoinResponse joinResponse) {

            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (joinResponse.getCode() == 0) {

                        Log.v("LoginActivity", "ici");

                        // The service will be handled by MainActivity;
                        destroySocketService = false;
                        destroyIpfsService = false;

                        Intent intent = new Intent(LoginActivity.this, MainActivity.class);

                        SharedPreferences sp = getSharedPreferences(getString(R.string.prefrence_file_key), Context.MODE_PRIVATE);
                        SharedPreferences.Editor editor = sp.edit();
                        editor.putString("profile_url", joinResponse.getParameters().getUserPicture());
                        editor.apply();

                        // Stringify fileobject in order to pass it to other activity. It will be save on disk
                        // So passing as string is fine
                        Gson gson = new Gson();
                        String homeJson = gson.toJson(joinResponse.getParameters().getHome());

                        intent.putExtra("home", homeJson);
                        intent.putExtra("profile_url", joinResponse.getParameters().getUserPicture());
                        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);

                        if (progessDialog != null)
                            progessDialog.dismiss();

                        startActivity(intent);
                    } else {
                        if (progessDialog != null)
                            progessDialog.dismiss();

                        SharedPreferences sharedPrefs = getSharedPreferences(
                                getString(R.string.prefrence_file_key), Context.MODE_PRIVATE);

                        SharedPreferences.Editor editor = sharedPrefs.edit();
                        editor.putString("oauth_token", "");
                        editor.putString("oauth_method", "");
                        editor.apply();

                        Toast.makeText(LoginActivity.this, "Please login", Toast.LENGTH_SHORT).show();
                    }
                }
            });
        }

        @Override
        public void handleConnection(final boolean success) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Log.v("MainActivity", "handleConnection");
                    if (success) {
                        if (autologin) {
                            if (!mSocketService.sendJOIN(m_method, m_token)) {
                                progessDialog.dismiss();
                                Toast.makeText(LoginActivity.this, "Please check your internet connection", Toast.LENGTH_SHORT).show();
                            }
                        }
                    } else if (autologin && progessDialog.isShowing()) {
                        progessDialog.dismiss();
                    }
                }
            });
        }

        @Override
        public void handleDisconnection() {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Toast.makeText(LoginActivity.this, "Connection lost...", Toast.LENGTH_LONG).show();
                    stopService(new Intent(LoginActivity.this, SocketService.class));
                    startService(new Intent(LoginActivity.this, SocketService.class));
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

                SharedPreferences sharedPrefs = getSharedPreferences(
                        getString(R.string.prefrence_file_key), Context.MODE_PRIVATE);

                SharedPreferences.Editor editor = sharedPrefs.edit();
                editor.putString("oauth_token", token);
                editor.putString("oauth_method", "gg");
                editor.apply();

                mSocketService.sendJOIN("gg", token);
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

    private ServiceConnection mSocketServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            mSocketService = ((SocketService.LocalBinder) service).getService();
            mSocketService.setmLoginHandler(mLoginHandler);
            mSocketServiceBound = true;
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            mSocketService = null;
            mSocketServiceBound = false;
        }
    };

    private ServiceConnection mIpfsServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName componentName, IBinder service) {
            mIpfsService = ((IpfsService.LocalBinder) service).getService();
            mIpfsServiceBound = true;
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {
            mIpfsService = null;
            mIpfsServiceBound = false;
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
        bindService(socketService, mSocketServiceConnection, Context.BIND_AUTO_CREATE);

        Intent ipfsService = new Intent(this, IpfsService.class);
        bindService(ipfsService, mIpfsServiceConnection, Context.BIND_AUTO_CREATE);
    }

    @Override
    protected void onStop() {
        super.onStop();

        if (mSocketServiceBound && destroySocketService) {
            unbindService(mSocketServiceConnection);
            mSocketServiceBound = false;
        }

        if (mIpfsServiceBound && destroyIpfsService) {
            unbindService(mIpfsServiceConnection);
            mIpfsServiceBound = false;
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

        SharedPreferences sharedPrefs = getSharedPreferences(
                getString(R.string.prefrence_file_key), Context.MODE_PRIVATE);

        final SharedPreferences.Editor editor = sharedPrefs.edit();

        SignInButton button = (SignInButton) findViewById(R.id.google_login);
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!mSocketService.isConnected()) {
                    Toast.makeText(LoginActivity.this, "Not connected", Toast.LENGTH_SHORT).show();
                    return;
                }

                pickUserAccount();
            }
        });

        Button developerButton = (Button) findViewById(R.id.developer_login);
        developerButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!mSocketService.isConnected()) {
                    Toast.makeText(LoginActivity.this, "Not connected", Toast.LENGTH_SHORT).show();
                    return;
                }
                editor.putString("oauth_token", "developer");
                editor.putString("oauth_method", "gg");
                editor.apply();

                mSocketService.sendJOIN("gg", "developer");
            }
        });

        callbackManager = CallbackManager.Factory.create();
        fbButton = (LoginButton) findViewById(R.id.facebook_login);

        fbButton.setReadPermissions(Arrays.asList(
                "public_profile", "email"));

        fbButton.registerCallback(callbackManager, new FacebookCallback<LoginResult>() {
            @Override
            public void onSuccess(LoginResult loginResult) {
                Log.d("LoginActivity", loginResult.getAccessToken().getToken());

                editor.putString("oauth_token", loginResult.getAccessToken().getToken());
                editor.putString("oauth_method", "fb");
                editor.apply();

                mSocketService.sendJOIN("fb", loginResult.getAccessToken().getToken());
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

        ImageButton settingsBtn = (ImageButton) findViewById(R.id.app_settings_btn);
        settingsBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent i = new Intent(LoginActivity.this, StoreItPreferences.class);
                startActivity(i);
            }
        });

        m_token = sharedPrefs.getString("oauth_token", "");
        m_method = sharedPrefs.getString("oauth_method", "");

        if (!m_token.isEmpty() && !m_method.isEmpty()) {
            autologin = true;

            progessDialog = new ProgressDialog(LoginActivity.this);
            progessDialog.setMessage("Connecting...");
            progessDialog.setIndeterminate(true);
            progessDialog.setCancelable(false);
            progessDialog.show();

        }

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

}