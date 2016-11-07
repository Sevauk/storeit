package com.storeit.storeit.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.util.Log;

import com.google.gson.Gson;
import com.storeit.storeit.protocol.StoreitFile;
import com.storeit.storeit.protocol.command.FileStoreCommand;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/**
 * Handle file creation and deletion
 */
public class FilesManager {
    private File mDataDir;
    private static final String LOGTAG = "FilesManager";
    private String storageLocation;

    private Map<String, StoreitFile> mFileMap = new HashMap<>();

    public FilesManager(Context ctx, StoreitFile rootFile) {

        SharedPreferences SP = PreferenceManager.getDefaultSharedPreferences(ctx);
        storageLocation = SP.getString("pref_key_storage_location", "");

        if (storageLocation.equals("")) {
            File path[] = ctx.getExternalFilesDirs(null);
            storageLocation = path[0].getAbsolutePath();
        }

        mDataDir = new File(storageLocation);
        createFilesMap(rootFile);
    }

    void createFilesMap(StoreitFile root) {
        if (!mFileMap.containsKey(root.getPath())) {
            mFileMap.put(root.getPath(), root);
        }

        for (Map.Entry<String, StoreitFile> entry : root.getFiles().entrySet()) {
            mFileMap.put(entry.getValue().getPath(), entry.getValue());
            if (entry.getValue().isDirectory()) {
                createFilesMap(entry.getValue());
            }
        }
    }

    // Delete a directory and its content
    public static boolean deleteContents(File dir) {
        File[] files = dir.listFiles();
        boolean success = true;
        if (files != null) {
            for (File file : files) {
                if (file.isDirectory()) {
                    success &= deleteContents(file);
                }
                if (!file.delete()) {
                    Log.e(LOGTAG, "Failed to delete " + file);
                    success = false;
                }
            }
        }
        return success;
    }

    // Recursively compare new tree with existing tree
    public void recursiveCmp(StoreitFile existingFile, StoreitFile newRoot) {
/*
        if (!existingFile.getPath().equals("/")) { // Don't delete root
            StoreitFile f = getFileByPath(existingFile.getPath(), newRoot); // Look for the actual file
            if (f == null) { // If the file doesn't exist anymore
                File fileToDelete = new File(mDataDir.getAbsolutePath() + File.separator + existingFile.getIPFSHash());
                if (fileToDelete.exists()) {
                    if (existingFile.isDirectory()) { // Delete directory
                        deleteContents(fileToDelete);
                    } else { // Delete file
                        if (!fileToDelete.delete()) {
                            Log.e(LOGTAG, "Error while deleting " + fileToDelete);
                        }
                    }
                }
            }
        }

        for (Map.Entry<String, StoreitFile> entry : existingFile.getFiles().entrySet()) {
            if (entry.getValue().isDirectory()) {
                recursiveCmp(entry.getValue(), newRoot);
            }
        }
        */
    }

    public boolean exist(StoreitFile file) {

        File requestedFile = new File(mDataDir.getAbsolutePath() + File.separator + file.getIPFSHash());
        return requestedFile.exists();
    }

    public StoreitFile getRoot() {
        return mFileMap.get("/");
    }

    public String getFolderPath() {
        return mDataDir.getPath();
    }

    public StoreitFile getFileByPath(String path) {
        return mFileMap.get(path);
    }

    private StoreitFile getParentFile(StoreitFile file) {

        if (file.getPath().equals("/"))
            return file;

        String parentPath = file.getPath().substring(0, file.getPath().lastIndexOf("/"));
        return getFileByPath(parentPath);
    }

    public void removeFile(String path) {
        Log.v(LOGTAG, "Deleting : " + path);

        List<String> toDelete = new ArrayList<>();

        for (Iterator<Map.Entry<String, StoreitFile>> it = mFileMap.entrySet().iterator(); it.hasNext(); ) {
            Map.Entry<String, StoreitFile> entry = it.next();
            if (isChildren(path, entry.getKey())) {
                Log.v(LOGTAG, entry.getKey() + " is a children!");
                StoreitFile parent = getParentFile(getFileByPath(entry.getKey()));
                if (parent != null && parent.getFiles() != null) {
                    parent.getFiles().remove(path);
                    toDelete.add(path);
                }

                it.remove();
            }
        }
        mFileMap.remove(path);
    }

    public void addFile(StoreitFile file, StoreitFile parent) {
        StoreitFile p = getFileByPath(parent.getPath());
        if (p != null) {
            p.addFile(file);
        }
        mFileMap.put(file.getPath(), file);
    }

    public void addFile(StoreitFile file) {
        StoreitFile parent = getParentFile(file);
        parent.addFile(file);
        mFileMap.put(file.getPath(), file);
    }


    public void updateFile(StoreitFile file) {
        StoreitFile toUpdate = getFileByPath(file.getPath());

        if (toUpdate != null) {
            toUpdate.setIPFSHash(file.getIPFSHash());
            toUpdate.setFiles(file.getFiles());
            toUpdate.setIsDir(file.isDirectory());
            toUpdate.setMetadata(file.getMetadata());
        }
    }

    public void moveFile(String src, String dst) {

        for (Map.Entry<String, StoreitFile> entry : mFileMap.entrySet()) {
            if (isChildren(src, entry.getKey())) {


            }

        }
        /*
            Recupere le path du parent

            Pour tous les fichiers dans le map:
                Si c'est un enfant
                    On creer un nouveau fichier a partir de l'ancien
                    On delete l'enfant
                    On insere le nouveau fichier
         */
    }

    private boolean isChildren(String parentPath, String childPath) {
        if (childPath.length() < parentPath.length()) { // A child cannot have a shorter name than its parent
            return false;
        }

        for (int i = 0; i < parentPath.length() - 1; i++) {
            if (parentPath.charAt(i) != childPath.charAt(i))
                return false;
        }

        return true;
    }

    public StoreitFile[] getChildrens(String path) {
        List<StoreitFile> files = new ArrayList<>();

        int numSlashes = countOccurrences(path, '/');

        for (Map.Entry<String, StoreitFile> entry : mFileMap.entrySet()) {
            if (entry.getKey().equals(path))
                continue;

            // Root case
            if (path.equals("/")
                    && (countOccurrences(entry.getKey(), '/') - numSlashes == 0)
                    && isChildren(path, entry.getKey())) {
                files.add(entry.getValue());
            } else if (!path.equals("/") // Other folders case
                    && (countOccurrences(entry.getKey(), '/') - numSlashes == 1)
                    && isChildren(path, entry.getKey())) {
                files.add(entry.getValue());
            }
        }

        StoreitFile[] filesArray = new StoreitFile[files.size()];
        filesArray = files.toArray(filesArray);

        return filesArray;
    }

    public static int countOccurrences(String haystack, char needle) {
        int count = 0;
        for (int i = 0; i < haystack.length(); i++) {
            if (haystack.charAt(i) == needle) {
                count++;
            }
        }
        return count;
    }
}
