package com.storeit.storeit.activities;

import android.content.DialogInterface;
import android.os.AsyncTask;
import android.os.Bundle;
import android.preference.ListPreference;
import android.preference.Preference;
import android.preference.PreferenceActivity;
import android.preference.PreferenceFragment;
import android.support.v7.app.AlertDialog;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.storeit.storeit.R;
import com.storeit.storeit.ipfs.DownloadAsync;
import com.storeit.storeit.ipfs.IpfsClearTask;
import com.storeit.storeit.ipfs.IpfsStatTask;

import org.apache.commons.io.IOUtils;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;

/**
 * Created by loulo on 16/06/2016.
 */
public class StoreItPreferences extends PreferenceActivity {

    static File[] mSavePath;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        mSavePath = getExternalFilesDirs(null);
        getFragmentManager().beginTransaction().replace(android.R.id.content, new MyPreferenceFragment()).commit();
    }

    public static class MyPreferenceFragment extends PreferenceFragment {
        @Override
        public void onCreate(final Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            addPreferencesFromResource(R.xml.preferences);

            final Preference clearCacheButton = findPreference("pref_key_erase_cache");

            ListPreference lp = (ListPreference) findPreference("pref_key_storage_location");
            ArrayList<CharSequence> entryValues = new ArrayList<>();

            if (mSavePath != null){
                for (File f : mSavePath) {
                    if (f != null)
                        entryValues.add(f.getPath());
                }
                lp.setEntries(entryValues.toArray(new CharSequence[entryValues.size()]));
                lp.setEntryValues(entryValues.toArray(new CharSequence[entryValues.size()]));
            }


            Log.v("StoreitPreference", "Fragment loaded");

            new IpfsStatTask(clearCacheButton).execute();


            clearCacheButton.setOnPreferenceClickListener(new Preference.OnPreferenceClickListener() {
                @Override
                public boolean onPreferenceClick(Preference preference) {

                    DialogInterface.OnClickListener dialogClickListener = new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            switch (which) {
                                case DialogInterface.BUTTON_POSITIVE:
                                    new IpfsClearTask(clearCacheButton).execute();
                                    break;

                                case DialogInterface.BUTTON_NEGATIVE:
                                    break;
                            }
                        }
                    };

                    AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
                    builder.setMessage("Are you sure?").setPositiveButton("Yes", dialogClickListener)
                            .setNegativeButton("No", dialogClickListener).show();

                    return true;
                }
            });

        }
    }
}

/*
  SharedPreferences SP = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
  String strUserName = SP.getString("username", "NA");
  boolean bAppUpdates = SP.getBoolean("applicationUpdates",false);
  String downloadType = SP.getString("downloadType","1");
*/