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
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.os.ResultReceiver;
import android.provider.MediaStore;
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
import com.google.android.gms.appindexing.Action;
import com.google.android.gms.appindexing.AppIndex;
import com.google.android.gms.appindexing.Thing;
import com.google.android.gms.auth.GoogleAuthUtil;
import com.google.android.gms.auth.GooglePlayServicesAvailabilityException;
import com.google.android.gms.auth.UserRecoverableAuthException;
import com.google.android.gms.common.AccountPicker;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.common.SignInButton;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.gson.Gson;
import com.storeit.storeit.R;
import com.storeit.storeit.oauth.GetUsernameTask;
import com.storeit.storeit.protocol.LoginHandler;
import com.storeit.storeit.protocol.command.ConnectionInfo;
import com.storeit.storeit.protocol.command.JoinResponse;
import com.storeit.storeit.services.IpfsService;
import com.storeit.storeit.services.ServiceManager;
import com.storeit.storeit.services.SocketService;

import java.util.Arrays;

/*
* Login Activity
* Create tcp service if it's not launched
*/
public class LoginActivity extends Activity {

    static final String LOGTAG = "LoginActivity";

    static final int REQUEST_CODE_PICK_ACCOUNT = 1000;
    static final int REQUEST_CODE_RECOVER_FROM_PLAY_SERVICES_ERROR = 1001;

    private String mEmail;

    private static final String SCOPE = "oauth2:https://www.googleapis.com/auth/userinfo.email";

    private boolean mAutoLogin = false;
    private ProgressDialog progessDialog = null;

    private String m_token = "";
    private String m_method = "";

    private LoginButton fbButton;
    private CallbackManager callbackManager;

    private static final int PERMISSIONS_REQUEST_WRITE_EXTERNAL = 1;

    private boolean sharingIntentReceived = false;
    private Uri sharingIntentUri = null;

    private ServiceManager mSocketService;

    private boolean mSocketConnected = true;
    private boolean mStopSocketService = true;

    private GoogleApiClient client;

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

                try {
                    mSocketService.send(Message.obtain(null, SocketService.SEND_JOIN, new ConnectionInfo("gg", token)));
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
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
        client.connect();
        AppIndex.AppIndexApi.start(client, getIndexApiAction());

        mSocketService.start();
    }

    @Override
    protected void onStop() {
        super.onStop();

        Log.v("LoginActivity", "onStop()");

        AppIndex.AppIndexApi.end(client, getIndexApiAction());
        client.disconnect();
    }

    @Override
    protected void onDestroy(){
        super.onDestroy();
        try{
            if (mStopSocketService){
                mSocketService.stop();
            } else {
                mSocketService.unbind();
            }

        } catch (Throwable t){
            t.printStackTrace();
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FacebookSdk.sdkInitialize(getApplicationContext());
        setContentView(R.layout.activity_login);

        Intent intent = getIntent();

        String action = intent.getAction();
        String type = intent.getType();

        if (Intent.ACTION_SEND.equals(action) && type != null) {
            sharingIntentReceived = true;
            sharingIntentUri = intent.getParcelableExtra(Intent.EXTRA_STREAM);
        }

        SharedPreferences sharedPrefs = getSharedPreferences(
                getString(R.string.prefrence_file_key), Context.MODE_PRIVATE);

        m_token = sharedPrefs.getString("oauth_token", "");
        m_method = sharedPrefs.getString("oauth_method", "");

        if (!m_token.isEmpty() && !m_method.isEmpty()) {
            mAutoLogin = true;

            progessDialog = new ProgressDialog(LoginActivity.this);
            progessDialog.setMessage("Connecting...");
            progessDialog.setIndeterminate(true);
            progessDialog.setCancelable(false);
            progessDialog.show();
        }


        final SharedPreferences.Editor editor = sharedPrefs.edit();

        SignInButton button = (SignInButton) findViewById(R.id.google_login);
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!mSocketConnected) {
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
                if (!mSocketConnected) {
                    Toast.makeText(LoginActivity.this, "Not connected", Toast.LENGTH_SHORT).show();
                    return;
                }
                editor.putString("oauth_token", "developer");
                editor.putString("oauth_method", "gg");
                editor.apply();

                try {
                    mSocketService.send(Message.obtain(null, SocketService.SEND_JOIN, new ConnectionInfo("gg", "developer")));
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
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

                try {
                    mSocketService.send(Message.obtain(null, SocketService.SEND_JOIN, new ConnectionInfo("fb", loginResult.getAccessToken().getToken())));
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
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

        client = new GoogleApiClient.Builder(this).addApi(AppIndex.API).build();

        mSocketService = new ServiceManager(this, SocketService.class, new Handler(){
            @Override
            public void handleMessage(Message msg){
                switch (msg.what){
                    case SocketService.SOCKET_CONNECTED:
                        mSocketConnected = true;
                        Log.i(LOGTAG, "Socket connected!");
                        if (mAutoLogin){
                            try {
                                Log.i(LOGTAG, "Sending join!");
                                mSocketService.send(Message.obtain(null, SocketService.SEND_JOIN, new ConnectionInfo(m_method, m_token)));
                            } catch (RemoteException e) {
                                e.printStackTrace();
                            }
                        }
                        break;
                    case SocketService.SOCKET_DISCONNECTED:
                        mSocketConnected = false;
                        break;
                    case SocketService.JOIN_RESPONSE:
                        openFileExplorer((JoinResponse)msg.obj);

                        break;
                    default:
                        break;
                }
            }
        });
        mSocketService.start();
    }

    public void openFileExplorer(JoinResponse response){
        if (response.getCode() == 0) { // Success!

            Intent intent = new Intent(LoginActivity.this, MainActivity.class);
            SharedPreferences sp = getSharedPreferences(getString(R.string.prefrence_file_key), Context.MODE_PRIVATE);
            SharedPreferences.Editor editor = sp.edit();
            editor.putString("profile_url", response.getParameters().getUserPicture());
            editor.apply();

            // Stringify fileobject in order to pass it to other activity. It will be save on disk
            // So passing as string is fine
            Gson gson = new Gson();
            String homeJson = gson.toJson(response.getParameters().getHome());

            intent.putExtra("home", homeJson);
            intent.putExtra("profile_url", response.getParameters().getUserPicture());

            if (sharingIntentReceived) {
                intent.putExtra("newFile", getRealPathFromURI(sharingIntentUri));
            } else {
                intent.putExtra("newFile", "");
            }

            if (progessDialog != null) {
                progessDialog.dismiss();
            }
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
            mStopSocketService = false;
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

    public String getRealPathFromURI(Uri contentUri) {
        String[] proj = {MediaStore.Images.Media.DATA};
        Cursor cursor = getContentResolver().query(contentUri, proj, null, null, null);
        int column_index = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
        cursor.moveToFirst();
        return cursor.getString(column_index);
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

    /**
     * ATTENTION: This was auto-generated to implement the App Indexing API.
     * See https://g.co/AppIndexing/AndroidStudio for more information.
     */
    public Action getIndexApiAction() {
        Thing object = new Thing.Builder()
                .setName("Login Page") // TODO: Define a title for the content shown.
                // TODO: Make sure this auto-generated URL is correct.
                .setUrl(Uri.parse("http://[ENTER-YOUR-URL-HERE]"))
                .build();
        return new Action.Builder(Action.TYPE_VIEW)
                .setObject(object)
                .setActionStatus(Action.STATUS_TYPE_COMPLETED)
                .build();
    }
}