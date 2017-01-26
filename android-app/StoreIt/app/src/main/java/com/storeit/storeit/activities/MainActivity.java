package com.storeit.storeit.activities;

import android.app.Activity;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.os.RemoteException;
import android.preference.PreferenceManager;
import android.provider.MediaStore;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.Fragment;
import android.support.v4.widget.DrawerLayout;
import android.support.v7.app.ActionBar;
import android.support.v7.app.ActionBarDrawerToggle;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Toast;

import com.bumptech.glide.Glide;
import com.google.api.client.json.Json;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.mikepenz.iconics.IconicsDrawable;
import com.mikepenz.materialdrawer.AccountHeader;
import com.mikepenz.materialdrawer.AccountHeaderBuilder;
import com.mikepenz.materialdrawer.Drawer;
import com.mikepenz.materialdrawer.DrawerBuilder;
import com.mikepenz.materialdrawer.interfaces.OnCheckedChangeListener;
import com.mikepenz.materialdrawer.model.DividerDrawerItem;
import com.mikepenz.materialdrawer.model.PrimaryDrawerItem;
import com.mikepenz.materialdrawer.model.ProfileDrawerItem;
import com.mikepenz.materialdrawer.model.SwitchDrawerItem;
import com.mikepenz.materialdrawer.model.interfaces.IDrawerItem;
import com.mikepenz.materialdrawer.model.interfaces.IProfile;
import com.mikepenz.materialdrawer.util.AbstractDrawerImageLoader;
import com.mikepenz.materialdrawer.util.DrawerImageLoader;
import com.mikepenz.materialdrawer.util.DrawerUIUtils;
import com.nononsenseapps.filepicker.FilePickerActivity;
import com.storeit.storeit.R;
import com.storeit.storeit.fragments.FileViewerFragment;
import com.storeit.storeit.ipfs.UploadAsync;
import com.storeit.storeit.protocol.StoreitFile;
import com.storeit.storeit.protocol.command.FileCommand;
import com.storeit.storeit.protocol.command.FileDeleteCommand;
import com.storeit.storeit.protocol.command.FileMoveCommand;
import com.storeit.storeit.protocol.command.FileRefreshResponse;
import com.storeit.storeit.protocol.command.FileStoreCommand;
import com.storeit.storeit.services.IpfsService;
import com.storeit.storeit.services.ServiceManager;
import com.storeit.storeit.services.SocketService;
import com.storeit.storeit.utils.FilesManager;
import com.storeit.storeit.utils.PathUtil;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.URISyntaxException;
import java.util.ArrayList;

/**
 * Main acyivity
 * Contains all the fragments of the apps
 */
public class MainActivity extends AppCompatActivity {

    private static final String LOGTAG = "MainActivity";

    String TITLES[] = {"Home", "My files", "Settings"};
    int ICONS[] = {R.drawable.ic_cloud_grey600_36dp, R.drawable.ic_folder_grey600_36dp, R.drawable.ic_settings_grey600_36dp};

    String NAME = "Louis Mondesir";
    String EMAIL = "louis.mondesir@gmail.com";
    int PROFILE = R.drawable.header_profile_picture;

    static int FILE_CODE_RESULT = 1005;

    static final int HOME_FRAGMENT = 1, FILES_FRAGMENT = 2, SETTINGS_FRAGMENT = 3;

    static final int CAPTURE_IMAGE_FULLSIZE_ACTIVITY_REQUEST_CODE = 1002;
    static final int PICK_IMAGE_GALLERY_REQUEST_CODE = 1003;

    RecyclerView mRecyclerView;
    RecyclerView.Adapter mAdapter;
    RecyclerView.LayoutManager mLayoutManager;
    DrawerLayout Drawer;

    ActionBar mActionBar;
    ActionBarDrawerToggle mDrawerToggle;
    FloatingActionButton fbtn;

    public FloatingActionButton getFloatingButton() {
        return fbtn;
    }

    private FilesManager filesManager;

    private ServiceManager mIpfsService;
    private ServiceManager mSocketService;
    private boolean mSocketConnected = true;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);

        launchSocketService();
        launchIpfsService();

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        final ActionBar bar = getSupportActionBar();
        if (bar != null) {
            bar.setTitle("Home");
        }

        SharedPreferences sp = getSharedPreferences(getString(R.string.prefrence_file_key), Context.MODE_PRIVATE);
        String profileUrl = sp.getString("profile_url", "");

        DrawerImageLoader.init(new AbstractDrawerImageLoader() {
            @Override
            public void set(ImageView imageView, Uri uri, Drawable placeholder) {
                Glide.with(imageView.getContext()).load(uri).placeholder(placeholder).into(imageView);
            }

            @Override
            public void cancel(ImageView imageView) {
                Glide.clear(imageView);
            }

            @Override
            public Drawable placeholder(Context ctx, String tag) {
                if (DrawerImageLoader.Tags.PROFILE.name().equals(tag)) {
                    return DrawerUIUtils.getPlaceHolder(ctx);
                } else if (DrawerImageLoader.Tags.ACCOUNT_HEADER.name().equals(tag)) {
                    return new IconicsDrawable(ctx).iconText(" ").backgroundColorRes(com.mikepenz.materialdrawer.R.color.primary).sizeDp(56);
                } else if ("customUrlItem".equals(tag)) {
                    return new IconicsDrawable(ctx).iconText(" ").backgroundColorRes(R.color.md_red_500).sizeDp(56);
                }


                return super.placeholder(ctx, tag);
            }
        });


        final IProfile profile = new ProfileDrawerItem()
                .withName("Louis Mondesir")
                .withEmail("louis.mondesir@gmail.com")
                .withIcon(profileUrl)
                .withIdentifier(100);

        AccountHeader headerResult = new AccountHeaderBuilder()
                .withActivity(this)
                .withHeaderBackground(R.drawable.header_background)
                .addProfiles(profile)
                .withOnAccountHeaderListener(new AccountHeader.OnAccountHeaderListener() {
                    @Override
                    public boolean onProfileChanged(View view, IProfile profile, boolean currentProfile) {
                        return false;
                    }
                })
                .build();

        PrimaryDrawerItem explorerItem = new PrimaryDrawerItem()
                .withIdentifier(1)
                .withName(R.string.drawer_item_explorer)
                .withIcon(R.drawable.ic_file_white_36dp)
                .withIconTintingEnabled(true);

        PrimaryDrawerItem recentItem = new PrimaryDrawerItem()
                .withIdentifier(2)
                .withName("Recent")
                .withIcon(R.drawable.ic_clock_white_36dp)
                .withIconTintingEnabled(true);

        PrimaryDrawerItem offlineItem = new PrimaryDrawerItem()
                .withIdentifier(3)
                .withName("Offline files")
                .withIcon(R.drawable.close_network)
                .withIconTintingEnabled(true);

        PrimaryDrawerItem trashItem = new PrimaryDrawerItem()
                .withIdentifier(4)
                .withName("Trash")
                .withIcon(R.drawable.ic_delete_white_36dp)
                .withIconTintingEnabled(true);

        PrimaryDrawerItem storageItem = new PrimaryDrawerItem()
                .withIdentifier(5)
                .withName("Upgrade storage")
                .withDescription("1.3 GB of 5 GB used")
                .withIcon(R.drawable.server_network)
                .withIconTintingEnabled(true);

        PrimaryDrawerItem settingsItem = new PrimaryDrawerItem()
                .withIdentifier(6)
                .withName(R.string.drawer_item_Settings)
                .withIcon(R.drawable.ic_settings_white_36dp)
                .withIconTintingEnabled(true);

        PrimaryDrawerItem HelpItems = new PrimaryDrawerItem()
                .withIdentifier(7)
                .withName("Help")
                .withIcon(R.drawable.ic_help_circle_black_36dp)
                .withIconTintingEnabled(true);

        Drawer result = new DrawerBuilder()
                .withActivity(this)
                .withToolbar(toolbar)
                .withAccountHeader(headerResult)
                .addDrawerItems(
                        explorerItem,
                        recentItem,
                        offlineItem,
                        trashItem,
                        new DividerDrawerItem(),
                        storageItem,
                        settingsItem,
                        HelpItems,
                        new DividerDrawerItem(),
                        new SwitchDrawerItem().withDescription("Ipfs node").withChecked(true).withOnCheckedChangeListener(new OnCheckedChangeListener() {
                            @Override
                            public void onCheckedChanged(IDrawerItem drawerItem, CompoundButton buttonView, boolean isChecked) {
                                Toast.makeText(MainActivity.this, "Node activated : " + isChecked, Toast.LENGTH_SHORT).show();
                            }
                        }),
                        new SwitchDrawerItem().withDescription("Offline mode").withChecked(false).withOnCheckedChangeListener(new OnCheckedChangeListener() {
                            @Override
                            public void onCheckedChanged(IDrawerItem drawerItem, CompoundButton buttonView, boolean isChecked) {
                                Toast.makeText(MainActivity.this, "Offline : " + isChecked, Toast.LENGTH_SHORT).show();
                            }
                        })
                )
                .withOnDrawerItemClickListener(new Drawer.OnDrawerItemClickListener() {
                    @Override
                    public boolean onItemClick(View view, int position, IDrawerItem drawerItem) {

                        if (drawerItem == null)
                            return false;

                        switch ((int) drawerItem.getIdentifier()) {
                            case 1:
                                fbtn.setVisibility(View.VISIBLE);
                                openFragment(FileViewerFragment.newInstance(""));
                                if (bar != null)
                                    bar.setTitle("My Files");
                                break;
                            case 6:
                                Intent i = new Intent(MainActivity.this, StoreItPreferences.class);
                                startActivity(i);
                                break;
                            default:
                                break;
                        }

                        return false;
                    }
                })
                .build();

        openFragment(new FileViewerFragment());

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(false);
            result.getActionBarDrawerToggle().setDrawerIndicatorEnabled(true);
        }

        fbtn = (FloatingActionButton) findViewById(R.id.add_file_button);

        fbtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                AlertDialog.Builder builder = new AlertDialog.Builder(MainActivity.this);
                builder.setTitle("Upload new file")
                        .setItems(R.array.file_upload_option, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialogInterface, int i) {
                                switch (i) {
                                    case 0:
                                        startCameraIntent();
                                    case 1:
                                        startGalleryPicker();
                                        break;
                                    case 2:
                                        startFilePickerIntent();
                                        break;
                                    case 3:
                                        createFolder();
                                    default:
                                        break;
                                }
                            }
                        });
                AlertDialog dialog = builder.create();
                dialog.show();
            }
        });

        Intent intent = getIntent();
        String homeJson = intent.getStringExtra("home");

        if (homeJson == null) { // App resumed

            String savedJson = "";
            if (savedInstanceState != null) {
                savedJson = savedInstanceState.getString("home_json", "");
            }
            if (!savedJson.equals("")) {
                homeJson = savedJson;
            } else {
                Intent i = new Intent(MainActivity.this, LoginActivity.class);
                i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                startActivity(i);
                return;
            }
        }

        Gson gson = new Gson();
        StoreitFile rootFile = gson.fromJson(homeJson, StoreitFile.class);

        filesManager = new FilesManager(this, rootFile);

        String newFile = intent.getStringExtra("newFile");
        if (newFile == null) {
            Log.e(LOGTAG, "Error newFile is null");
        } else if (!newFile.equals("")) {
            openFragment(FileViewerFragment.newInstance(newFile));
        }
    }

    @Override
    public void onSaveInstanceState(Bundle savedInstanceState) {
        Gson gson = new Gson();
        savedInstanceState.putString("home_json", gson.toJson(filesManager.getRoot()));
    }

    private void launchSocketService() {
        mSocketService = new ServiceManager(this, SocketService.class, new Handler() {
            @Override
            public void handleMessage(Message msg) {
                switch (msg.what) {
                    case SocketService.SOCKET_CONNECTED:
                        mSocketConnected = true;
                        Log.i(LOGTAG, "Socket connected!");
                        break;
                    case SocketService.SOCKET_DISCONNECTED:
                        mSocketConnected = false;
                        break;
                    case SocketService.JOIN_RESPONSE:
                        break;
                    case SocketService.HANDLE_FADD:
                        handleFADD((FileCommand) msg.obj);
                        break;
                    case SocketService.HANDLE_FDEL:
                        handleFDEL((FileDeleteCommand) msg.obj);
                        break;
                    case SocketService.HANDLE_FMOV:
                        handleFMOV((FileMoveCommand) msg.obj);
                        break;
                    case SocketService.HANDLE_FUPT:
                        handleFUPT((FileCommand) msg.obj);
                        break;
                    case SocketService.HANDLE_FSTR:
                        handleFSTR((FileStoreCommand) msg.obj);
                        break;
                    case SocketService.HANDLE_RFSH:
                        handleRFSH((FileRefreshResponse) msg.obj);
                        break;
                    default:
                        break;
                }
            }
        });
        mSocketService.start();
    }

    private void launchIpfsService() {
        mIpfsService = new ServiceManager(this, IpfsService.class, new Handler() {
            @Override
            public void handleMessage(Message msg) {
                switch (msg.what) {
                    case IpfsService.IPFS_HASH_STORED:
                        saveHashes((IpfsService.IpfsOperation) msg.obj);
                        break;
                    default:
                        break;
                }
            }
        });
        mIpfsService.start();
    }

    private void saveHashes(IpfsService.IpfsOperation operation) {
        ArrayList<String> savedHash = getSavedHashes();

        if (!operation.isAdd()) {
            savedHash.remove(operation.getHash());
        } else {
            savedHash.add(operation.getHash());
        }
        saveHashesToFile(savedHash);
    }

    class HashArray {
        public ArrayList<String> hashes;
    }

    private void saveHashesToFile(ArrayList<String> savedHash) {
        SharedPreferences sp = PreferenceManager.getDefaultSharedPreferences(this);
        String storageLocation = sp.getString("pref_key_storage_location", getExternalFilesDirs(null)[0].getPath());

        ArrayList objList;

        File jsonHashFile = new File(storageLocation + File.separator + ".save_hash.json");


        HashArray hashArray = new HashArray();
        hashArray.hashes = savedHash;

        Gson gson = new Gson();
        String json = gson.toJson(hashArray);

        try {
            if (jsonHashFile.exists()) {
                jsonHashFile.delete();

            }
            jsonHashFile.createNewFile();


            FileOutputStream fOut = new FileOutputStream(jsonHashFile);
            OutputStreamWriter myOutWriter = new OutputStreamWriter(fOut);
            myOutWriter.append(json);
            myOutWriter.close();
            fOut.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    private void createFolder() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        LayoutInflater inflater = getLayoutInflater();

        builder.setTitle("Create Folder");
        View dialogView = inflater.inflate(R.layout.dialog_name_file, null);
        builder.setView(dialogView);

        final EditText input = (EditText) dialogView.findViewById(R.id.dialog_file_name_input);

        builder.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {

                String fileName = input.getText().toString();
                fbtn.setVisibility(View.VISIBLE);


                Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container); // Get the current fragment
                if (currentFragment instanceof FileViewerFragment) {
                    FileViewerFragment fragment = (FileViewerFragment) currentFragment;

                    // Create new folder
                    StoreitFile folder;

                    if (fragment.getCurrentFile().equals("/")) {
                        folder = new StoreitFile(fragment.getCurrentFile() + fileName, null, true);
                    } else {
                        folder = new StoreitFile(fragment.getCurrentFile() + File.separator + fileName, null, true);
                    }
                    filesManager.addFile(folder, filesManager.getFileByPath(fragment.getCurrentFile()));
                    refreshFileExplorer();

                    try {
                        mSocketService.send(Message.obtain(null, SocketService.SEND_FADD, folder));
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }

                }

            }
        }).setNegativeButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                dialogInterface.cancel();
            }
        }).show();
    }

    private void startGalleryPicker() {
        Intent intent = new Intent();
        intent.setType("image/*");
        intent.setAction(Intent.ACTION_GET_CONTENT);
        startActivityForResult(Intent.createChooser(intent, "Select Picture"), PICK_IMAGE_GALLERY_REQUEST_CODE);
    }

    private void startFilePickerIntent() {
        Intent intent = new Intent(MainActivity.this, FilePickerActivity.class);
        intent.putExtra(FilePickerActivity.EXTRA_ALLOW_MULTIPLE, false);
        intent.putExtra(FilePickerActivity.EXTRA_ALLOW_CREATE_DIR, false);
        intent.putExtra(FilePickerActivity.EXTRA_MODE, FilePickerActivity.MODE_FILE);

        intent.putExtra(FilePickerActivity.EXTRA_START_PATH, Environment.getExternalStorageDirectory().getPath());
        startActivityForResult(intent, FILE_CODE_RESULT);
    }

    private void startCameraIntent() {
        Intent intent = new Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE);
        if (intent.resolveActivity(getPackageManager()) != null) {
            File file = new File(Environment.getExternalStorageDirectory() + File.separator + "image.jpg");
            intent.putExtra(MediaStore.EXTRA_OUTPUT, Uri.fromFile(file));
            startActivityForResult(intent, CAPTURE_IMAGE_FULLSIZE_ACTIVITY_REQUEST_CODE);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mSocketService.stop();
        mIpfsService.stop();
    }

    @Override
    protected void onStop() {
        super.onStop();
    }


    public void openFragment(final Fragment fragment) {
        android.support.v4.app.FragmentManager fm = getSupportFragmentManager();
        android.support.v4.app.FragmentTransaction ft = fm.beginTransaction();
        ft.addToBackStack(null);
        ft.replace(R.id.fragment_container, fragment);
        ft.commit();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    private void logout() {
        SharedPreferences sharedPrefs = getSharedPreferences(
                getString(R.string.prefrence_file_key), Context.MODE_PRIVATE);

        SharedPreferences.Editor editor = sharedPrefs.edit();
        editor.putString("oauth_token", "");
        editor.putString("oauth_method", "");
        editor.apply();

        Intent i = new Intent(MainActivity.this, LoginActivity.class);
        startActivity(i);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();
        switch (id) {
            case R.id.action_logout:
                logout();
                break;
            case android.R.id.home:
                break;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.v("MainActivity", "Activity result : " + requestCode);

        if (requestCode == FILE_CODE_RESULT && resultCode == Activity.RESULT_OK) { // File picker
            Uri uri = data.getData();
            fbtn.setVisibility(View.VISIBLE);

            new UploadAsync(this, mSocketService).execute(uri.getPath());
        } else if (requestCode == PICK_IMAGE_GALLERY_REQUEST_CODE && resultCode == RESULT_OK && data != null && data.getData() != null) { // Gallery
            fbtn.setVisibility(View.INVISIBLE);

            Uri uri = data.getData();
            Log.v(LOGTAG, "uri : " + uri.toString());
            try {
                new UploadAsync(this, mSocketService).execute(PathUtil.getPath(this, uri));
            } catch (URISyntaxException e) {
                e.printStackTrace();
            }

        } else if (requestCode == CAPTURE_IMAGE_FULLSIZE_ACTIVITY_REQUEST_CODE && resultCode == RESULT_OK) {
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            LayoutInflater inflater = getLayoutInflater();

            builder.setTitle("Save picture");
            View dialogView = inflater.inflate(R.layout.dialog_name_file, null);
            builder.setView(dialogView);

            final EditText input = (EditText) dialogView.findViewById(R.id.dialog_file_name_input);
            input.setText("image");

            builder.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialogInterface, int i) {

                    File file = new File(Environment.getExternalStorageDirectory() + File.separator + "image.jpg");
                    String fileName = input.getText().toString() + ".jpg";


                    File fileRenamed = new File(Environment.getExternalStorageDirectory() + File.separator + fileName);
                    Log.v("RENAME", "result : " + file.renameTo(fileRenamed));

                    fbtn.setVisibility(View.VISIBLE);
                    new UploadAsync(MainActivity.this, mSocketService).execute(fileRenamed.getAbsolutePath());

                }
            }).setNegativeButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialogInterface, int i) {
                    dialogInterface.cancel();
                }
            }).show();
        }
    }

    @Override
    public void onBackPressed() {
        Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container); // Get the current fragment
        if (currentFragment instanceof FileViewerFragment) {
            FileViewerFragment fileViewerFragment = (FileViewerFragment) currentFragment;
            fileViewerFragment.backPressed();
            return;
        }

        super.onBackPressed();
    }

    public FilesManager getFilesManager() {
        return filesManager;
    }

    public void refreshFileExplorer() {
        Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.fragment_container); // Get the current fragment
        if (currentFragment instanceof FileViewerFragment) {

            FileViewerFragment f = (FileViewerFragment) currentFragment;
            f.getAdapter().reloadFiles();
        }
    }

    public ServiceManager getSocketService() {
        return mSocketService;
    }

    public void handleFDEL(FileDeleteCommand command) {
        Log.v("MainActivity", "FDEL");
        filesManager.removeFile(command.getFiles());

        try {
            mSocketService.send(Message.obtain(null, SocketService.SEND_RESPONSE, 0));
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        refreshFileExplorer();
    }


    public void handleFADD(FileCommand command) {
        Log.v("MainActivity", "FADD");
        filesManager.addFile(command.getFiles());

        try {
            mSocketService.send(Message.obtain(null, SocketService.SEND_RESPONSE, 0));
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        refreshFileExplorer();
    }

    public void handleFUPT(FileCommand command) {
        Log.v("MainActivity", "FUPT");
        filesManager.updateFile(command.getFiles());

        try {
            mSocketService.send(Message.obtain(null, SocketService.SEND_RESPONSE, 0));
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        refreshFileExplorer();
    }

    public void handleFMOV(FileMoveCommand command) {
        Log.v("MainActivity", "FMOV");
        filesManager.moveFile(command.getSrc(), command.getDst());
        try {
            mSocketService.send(Message.obtain(null, SocketService.SEND_RESPONSE, 0));
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        refreshFileExplorer();
    }

    public void handleFSTR(final FileStoreCommand command) {
        boolean shouldKeep = command.shouldKeep();
        final String hash = command.getHash();

        //     mIpfsService.removeFile(hash);
        //  mIpfsService.addFile(hash);

        try {
            if (!hash.isEmpty()) {
                if (shouldKeep) {
                    mIpfsService.send(Message.obtain(null, IpfsService.HANDLE_ADD, hash));
                } else {
                    mIpfsService.send(Message.obtain(null, IpfsService.HANDLE_DEL, hash));
                }
            }

            mSocketService.send(Message.obtain(null, SocketService.SEND_RESPONSE, 0));
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    public void handleRFSH(final FileRefreshResponse response) {

        filesManager.recreate(response.getParameters().getHome());
        refreshFileExplorer();
        try {
            mSocketService.send(Message.obtain(null, SocketService.SEND_RESPONSE, 0));
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    public ArrayList<String> getSavedHashes() {
        SharedPreferences sp = PreferenceManager.getDefaultSharedPreferences(this);
        String storageLocation = sp.getString("pref_key_storage_location", getExternalFilesDirs(null)[0].getPath());

        ArrayList objList;
        ArrayList<String> storedHashes = new ArrayList<>();

        File jsonHashFile = new File(storageLocation + File.separator + ".save_hash.json");
        if (!jsonHashFile.exists()) {

            String json = "{\"hashes\": [] }";

            try {
                jsonHashFile.createNewFile();
                FileOutputStream fOut = new FileOutputStream(jsonHashFile);
                OutputStreamWriter myOutWriter = new OutputStreamWriter(fOut);
                myOutWriter.append(json);
                myOutWriter.close();
                fOut.close();
            } catch (IOException e) {
                e.printStackTrace();
            }

            storedHashes = new ArrayList<String>();
        } else {
            try {
                FileInputStream fIn = new FileInputStream(jsonHashFile);
                BufferedReader reader = new BufferedReader(new InputStreamReader(fIn));

                String json = "";
                String line;
                while ((line = reader.readLine()) != null) {
                    json += line;
                }

                reader.close();

                JsonParser jsonParser = new JsonParser();
                JsonObject jo = (JsonObject) jsonParser.parse(json);
                JsonArray array = jo.getAsJsonArray("hashes");

                Gson gson = new Gson();
                objList = gson.fromJson(array, ArrayList.class);

                for (Object hash : objList) {
                    storedHashes.add((String) hash);
                    Log.v(LOGTAG, "hosted : " + (String) hash);
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return storedHashes;
    }
}