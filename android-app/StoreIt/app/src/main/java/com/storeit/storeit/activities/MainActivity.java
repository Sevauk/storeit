package com.storeit.storeit.activities;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.IBinder;
import android.provider.MediaStore;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.Fragment;
import android.support.v4.widget.DrawerLayout;
import android.support.v7.app.ActionBar;
import android.support.v7.app.ActionBarDrawerToggle;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.widget.EditText;

import com.google.gson.Gson;
import com.nononsenseapps.filepicker.FilePickerActivity;
import com.storeit.storeit.R;
import com.storeit.storeit.adapters.MainAdapter;
import com.storeit.storeit.fragments.FileViewerFragment;
import com.storeit.storeit.fragments.HomeFragment;
import com.storeit.storeit.ipfs.UploadAsync;
import com.storeit.storeit.protocol.FileCommandHandler;
import com.storeit.storeit.protocol.StoreitFile;
import com.storeit.storeit.protocol.command.FileCommand;
import com.storeit.storeit.protocol.command.FileDeleteCommand;
import com.storeit.storeit.protocol.command.FileMoveCommand;
import com.storeit.storeit.protocol.command.FileStoreCommand;
import com.storeit.storeit.services.IpfsService;
import com.storeit.storeit.services.SocketService;
import com.storeit.storeit.utils.FilesManager;

import java.io.File;

/**
 * Main acyivity
 * Contains all the fragments of the apps
 */
public class MainActivity extends AppCompatActivity {

    String TITLES[] = {"Home", "My files", "Settings"};
    int ICONS[] = {R.drawable.ic_cloud_black_24dp, R.drawable.ic_folder_black_24dp, R.drawable.ic_settings_applications_black_24dp};

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

    private boolean destroyIpfs = true;
    private boolean destroySocket = true;

    public FloatingActionButton getFloatingButton() {
        return fbtn;
    }

    private FilesManager filesManager;

    // Socket and ipfs service are already existing
    private boolean mSocketServiceBound = false;
    private boolean mIpfsServiceBound = false;

    private SocketService mSocketService = null;
    private IpfsService mIpfsService = null;

    private boolean willRestart = false;

    // Should be the same class as LoginActivity ServiceConnection
    private ServiceConnection mSocketServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            mSocketService = ((SocketService.LocalBinder) service).getService();
            mSocketService.setFileCommandandler(mFileCommandHandler);
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
        public void onServiceConnected(ComponentName name, IBinder service) {
            mIpfsService = ((IpfsService.LocalBinder) service).getService();
            mIpfsServiceBound = true;
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            mIpfsService = null;
            mIpfsServiceBound = false;
        }
    };


    @Override
    protected void onStart() {
        super.onStart();

        Intent socketService = new Intent(this, SocketService.class);
        getApplicationContext().bindService(socketService, mSocketServiceConnection, Context.BIND_AUTO_CREATE);

        Intent ipfsService = new Intent(this, IpfsService.class);
        getApplicationContext().bindService(ipfsService, mIpfsServiceConnection, Context.BIND_AUTO_CREATE);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);



        setContentView(R.layout.activity_main);

        Toolbar toolbar = (Toolbar) findViewById(R.id.tool_bar);
        setSupportActionBar(toolbar);

        mRecyclerView = (RecyclerView) findViewById(R.id.RecyclerView);

        assert mRecyclerView != null;

        final GestureDetector mGestureDetector = new GestureDetector(MainActivity.this, new GestureDetector.SimpleOnGestureListener() {

            @Override
            public boolean onSingleTapUp(MotionEvent e) {
                return true;
            }

        });

        mRecyclerView.setHasFixedSize(true);

        SharedPreferences sp = getSharedPreferences(getString(R.string.prefrence_file_key), Context.MODE_PRIVATE);
        String profileUrl = sp.getString("profile_url", "");

        mAdapter = new MainAdapter(TITLES, ICONS, NAME, EMAIL, profileUrl, this);
        mRecyclerView.setAdapter(mAdapter);


        mRecyclerView.addOnItemTouchListener(new RecyclerView.OnItemTouchListener() {
            @Override
            public boolean onInterceptTouchEvent(RecyclerView recyclerView, MotionEvent motionEvent) {
                View child = recyclerView.findChildViewUnder(motionEvent.getX(), motionEvent.getY());


                if (child != null && mGestureDetector.onTouchEvent(motionEvent)) {
                    Drawer.closeDrawers();
                    onTouchDrawer(recyclerView.getChildLayoutPosition(child));
                    return true;
                }

                return false;
            }

            @Override
            public void onTouchEvent(RecyclerView recyclerView, MotionEvent motionEvent) {

            }

            @Override
            public void onRequestDisallowInterceptTouchEvent(boolean disallowIntercept) {

            }
        });

        mLayoutManager = new LinearLayoutManager(this);
        mRecyclerView.setLayoutManager(mLayoutManager);

        Drawer = (DrawerLayout) findViewById(R.id.DrawerLayout);
        mDrawerToggle = new ActionBarDrawerToggle(this, Drawer, toolbar, R.string.drawer_open, R.string.drawer_close) {
            @Override
            public void onDrawerOpened(View drawerView) {
                super.onDrawerOpened(drawerView);
            }

            @Override
            public void onDrawerClosed(View drawerView) {
                super.onDrawerClosed(drawerView);
            }


        }; // Drawer Toggle Object Made
        Drawer.addDrawerListener(mDrawerToggle); // Drawer Listener set to the Drawer toggle

        mDrawerToggle.syncState();               // Finally we set the drawer toggle sync State

        fbtn = (FloatingActionButton) findViewById(R.id.add_file_button);
        assert fbtn != null;
        fbtn.setVisibility(View.INVISIBLE);

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

        openFragment(new HomeFragment());
        ActionBar bar = getSupportActionBar();
        if (bar != null) {
            bar.setTitle("Home");
        }

        Intent intent = getIntent();
        String homeJson = intent.getStringExtra("home");


        if (homeJson == null) { // App resumed relogin
            Intent i = new Intent(MainActivity.this, LoginActivity.class);
            i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            startActivity(i);

            willRestart = true;
            return;
        }

        Gson gson = new Gson();
        StoreitFile rootFile = gson.fromJson(homeJson, StoreitFile.class);

        filesManager = new FilesManager(this, rootFile);

        String newFile = intent.getStringExtra("newFile");
        Log.v("MainActivity", "received " + newFile);
        if (!newFile.equals("")) {
            openFragment(FileViewerFragment.newInstance(newFile));
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
                    mSocketService.sendFADD(folder);
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
        destroySocket = destroyIpfs = false;
        Intent intent = new Intent();
        intent.setType("image/*");
        intent.setAction(Intent.ACTION_GET_CONTENT);
        startActivityForResult(Intent.createChooser(intent, "Select Picture"), PICK_IMAGE_GALLERY_REQUEST_CODE);
    }

    private void startFilePickerIntent() {
        destroySocket = destroyIpfs = false;
        Intent intent = new Intent(MainActivity.this, FilePickerActivity.class);
        intent.putExtra(FilePickerActivity.EXTRA_ALLOW_MULTIPLE, false);
        intent.putExtra(FilePickerActivity.EXTRA_ALLOW_CREATE_DIR, false);
        intent.putExtra(FilePickerActivity.EXTRA_MODE, FilePickerActivity.MODE_FILE);

        intent.putExtra(FilePickerActivity.EXTRA_START_PATH, Environment.getExternalStorageDirectory().getPath());
        startActivityForResult(intent, FILE_CODE_RESULT);
    }

    private void startCameraIntent() {
        destroySocket = destroyIpfs = false;
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
        Log.v("MainActivity", "onResume!!");
        destroySocket = destroyIpfs = true;
    }

    @Override
    protected void onDestroy(){

        Log.v("MaiActivity", "unbind service!");

        if (mIpfsServiceBound)
            getApplicationContext().stopService(new Intent(MainActivity.this, IpfsService.class));
        if (mSocketServiceBound)
            getApplicationContext().stopService(new Intent(MainActivity.this, SocketService.class));

        super.onDestroy();
    }

    @Override
    protected void onStop() {
        super.onStop();



         /*   if (!willRestart) {
                Log.v("MaiActivity", "unbind service!");
                getApplicationContext().stopService(new Intent(MainActivity.this, IpfsService.class));
                getApplicationContext().stopService(new Intent(MainActivity.this, SocketService.class));
            }*/
    }

    public void onTouchDrawer(final int position) {

        ActionBar actionBar = getSupportActionBar();

        switch (position) {
            case HOME_FRAGMENT:
                fbtn.setVisibility(View.INVISIBLE);
                openFragment(new HomeFragment());
                if (actionBar != null)
                    actionBar.setTitle("Home");
                break;
            case FILES_FRAGMENT:
                fbtn.setVisibility(View.VISIBLE);
                openFragment(FileViewerFragment.newInstance(""));
                if (actionBar != null)
                    actionBar.setTitle("My Files");
                break;
            case SETTINGS_FRAGMENT:
                destroySocket = destroyIpfs = false;
                Intent i = new Intent(this, StoreItPreferences.class);
                startActivity(i);
                break;
            default:
                break;
        }
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

        // Add restart first activity
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

        destroySocket = destroyIpfs = true;

        Log.v("MainActivity", "Activity result : " + requestCode);

        if (requestCode == FILE_CODE_RESULT && resultCode == Activity.RESULT_OK) { // File picker
            Uri uri = data.getData();
            fbtn.setVisibility(View.VISIBLE);
            new UploadAsync(this, mSocketService).execute(uri.getPath());
        } else if (requestCode == PICK_IMAGE_GALLERY_REQUEST_CODE && resultCode == RESULT_OK && data != null && data.getData() != null) { // Gallery
            fbtn.setVisibility(View.VISIBLE);

            Uri uri = data.getData();
            new UploadAsync(this, mSocketService).execute(getRealPathFromURI(uri));
        } else if (requestCode == CAPTURE_IMAGE_FULLSIZE_ACTIVITY_REQUEST_CODE && resultCode == RESULT_OK) {
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            LayoutInflater inflater = getLayoutInflater();

            builder.setTitle("Save picture");
            View dialogView = inflater.inflate(R.layout.dialog_name_file, null);
            builder.setView(dialogView);

            final EditText input = (EditText) dialogView.findViewById(R.id.dialog_file_name_input);

            builder.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialogInterface, int i) {

                    File file = new File(Environment.getExternalStorageDirectory() + File.separator + "image.jpg");
                    String fileName = input.getText().toString();

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

    public String getRealPathFromURI(Uri contentUri) {
        Cursor cursor = null;
        try {
            String[] proj = {MediaStore.Images.Media.DATA};
            cursor = getContentResolver().query(contentUri, proj, null, null, null);
            int column_index = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
            cursor.moveToFirst();
            return cursor.getString(column_index);
        } finally {
            if (cursor != null) {
                cursor.close();
            }
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

            /*
            FragmentTransaction fragTransaction = getSupportFragmentManager().beginTransaction();
            fragTransaction.detach(currentFragment);
            fragTransaction.attach(currentFragment);
            fragTransaction.commit();
            Log.v("MainActivity", "tu fois quoi??");
            */
        }
    }

    public SocketService getSocketService() {
        return mSocketService;
    }

    private FileCommandHandler mFileCommandHandler = new FileCommandHandler() {
        @Override
        public void handleFDEL(FileDeleteCommand command) {
            Log.v("MainActivity", "FDEL");
            filesManager.removeFile(command.getFiles());
            mSocketService.sendRSPONSE();
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    refreshFileExplorer();
                }
            });

        }

        @Override
        public void handleFADD(FileCommand command) {
            Log.v("MainActivity", "FADD");
            filesManager.addFile(command.getFiles());
            mSocketService.sendRSPONSE();
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    refreshFileExplorer();
                }
            });
        }

        @Override
        public void handleFUPT(FileCommand command) {
            Log.v("MainActivity", "FUPT");
            filesManager.updateFile(command.getFiles());
            mSocketService.sendRSPONSE();
           /* runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    refreshFileExplorer();
                }
            });
            */
        }

        @Override
        public void handleFMOV(FileMoveCommand command) {
            Log.v("MainActivity", "FMOV");
            filesManager.moveFile(command.getSrc(), command.getDst());
            mSocketService.sendRSPONSE();
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    refreshFileExplorer();
                }
            });
        }

        @Override
        public void handleFSTR(final FileStoreCommand command) {
            boolean shouldKeep = command.shouldKeep();
            String hash = command.getHash();

            if (!shouldKeep) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        mIpfsService.removeFile(command.getHash());
                        mSocketService.sendRSPONSE();
                    }
                });
                return;
            }
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    mIpfsService.addFile(command.getHash());
                    mSocketService.sendRSPONSE();
                }
            });

        }
    };
}