package com.storeit.storeit.activities;

import android.app.Activity;
import android.content.ClipData;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.ServiceConnection;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.IBinder;
import android.provider.MediaStore;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentTransaction;
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
import android.view.ViewGroup;
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

    ActionBarDrawerToggle mDrawerToggle;
    FloatingActionButton fbtn;

    private FilesManager filesManager;

    // Socket service is already existing
    private boolean mIsBound = false;
    private SocketService mBoundService = null;

    // Should be the same class as LoginActivity ServiceConnection
    private ServiceConnection mConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            mBoundService = ((SocketService.LocalBinder) service).getService();
            mBoundService.setFileCommandandler(mFileCommandHandler);
            mIsBound = true;
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            mBoundService = null;
            mIsBound = false;
        }
    };

    @Override
    protected void onStart() {
        super.onStart();

        Intent socketService = new Intent(this, SocketService.class);
        bindService(socketService, mConnection, Context.BIND_AUTO_CREATE);
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

        mAdapter = new MainAdapter(TITLES, ICONS, NAME, EMAIL, PROFILE, this);
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
        if (bar != null)
            bar.setTitle("Home");

        Intent intent = getIntent();
        String homeJson = intent.getStringExtra("home");

        Gson gson = new Gson();
        StoreitFile rootFile = gson.fromJson(homeJson, StoreitFile.class);

        filesManager = new FilesManager(this, rootFile);
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
        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (intent.resolveActivity(getPackageManager()) != null) {
            File file = new File(Environment.getExternalStorageDirectory() + File.separator + "image.jpg");
            intent.putExtra(MediaStore.EXTRA_OUTPUT, Uri.fromFile(file));
            startActivityForResult(intent, CAPTURE_IMAGE_FULLSIZE_ACTIVITY_REQUEST_CODE);
        }



    }

    @Override
    protected void onStop() {
        super.onStop();

        if (mIsBound) {
            unbindService(mConnection);
            mIsBound = false;
        }

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
                openFragment(new FileViewerFragment());
                if (actionBar != null)
                    actionBar.setTitle("My Files");
                break;
            case SETTINGS_FRAGMENT:
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

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();
        return id == R.id.action_settings || super.onOptionsItemSelected(item);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == FILE_CODE_RESULT && resultCode == Activity.RESULT_OK) { // File picker
            Uri uri = data.getData();
            Log.v("MainActivity", "icici " + uri.toString());
            fbtn.setVisibility(View.VISIBLE);
            new UploadAsync(this, mBoundService).execute(uri.getPath());
        } else if (requestCode == PICK_IMAGE_GALLERY_REQUEST_CODE && resultCode == RESULT_OK && data != null && data.getData() != null) { // Gallery
            fbtn.setVisibility(View.VISIBLE);

            Uri uri = data.getData();
            new UploadAsync(this, mBoundService).execute(getRealPathFromURI(uri));
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
                    new UploadAsync(MainActivity.this, mBoundService).execute(fileRenamed.getAbsolutePath());

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
            String[] proj = { MediaStore.Images.Media.DATA };
            cursor = getContentResolver().query(contentUri,  proj, null, null, null);
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

            FragmentTransaction fragTransaction = getSupportFragmentManager().beginTransaction();
            fragTransaction.detach(currentFragment);
            fragTransaction.attach(currentFragment);
            fragTransaction.commit();
        }
    }

    public SocketService getSocketService() {
        return mBoundService;
    }

    private FileCommandHandler mFileCommandHandler = new FileCommandHandler() {
        @Override
        public void handleFDEL(FileCommand command) {
            Log.v("MainActivity", "FDEL");
            filesManager.removeFile(command.getFiles());
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
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    refreshFileExplorer();
                }
            });
        }
    };
}
