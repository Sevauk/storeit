package com.storeit.storeit.adapters;

import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.support.v7.app.AlertDialog;
import android.support.v7.widget.RecyclerView;
import android.view.ContextMenu;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.MimeTypeMap;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.storeit.storeit.R;
import com.storeit.storeit.ipfs.DownloadAsync;
import com.storeit.storeit.protocol.StoreitFile;
import com.storeit.storeit.utils.FilesManager;

import java.io.File;
import java.lang.reflect.Array;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Deque;
import java.util.Map;

public class ExplorerAdapter extends RecyclerView.Adapter<ExplorerAdapter.ViewHolder> {

    private StoreitFile[] mFiles;
    private Deque<StoreitFile> historyStack = new ArrayDeque<>();
    private Context context;
    private String storeitPath;
    private FilesManager manager;
    int position;

    public StoreitFile getCurrentFile() {
        return historyStack.peek();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener, View.OnCreateContextMenuListener {
        TextView fileNameTextView;
        ImageView fileTypeImageView;
        Context contxt;

        public ViewHolder(View itemView, int ViewType, Context c) {
            super(itemView);
            contxt = c;
            itemView.setClickable(true);
            itemView.setOnClickListener(this);
            fileNameTextView = (TextView) itemView.findViewById(R.id.file_item_row_name);
            fileTypeImageView = (ImageView) itemView.findViewById(R.id.explorer_image_file_type);
            itemView.setOnCreateContextMenuListener(this);
        }

        @Override
        public void onClick(View v) {
            Toast.makeText(contxt, "The Item Clicked is: " + getPosition(), Toast.LENGTH_SHORT).show();
        }


        @Override
        public void onCreateContextMenu(ContextMenu menu, View v,
                                        ContextMenu.ContextMenuInfo menuInfo) {

            menu.add(Menu.NONE, R.id.action_delete_file, Menu.NONE, "Delete");
            menu.add(Menu.NONE, R.id.action_delete_file_disk, Menu.NONE, "Delete from storage");
            menu.add(Menu.NONE, R.id.action_rename_file, Menu.NONE, "Rename");
        }
    }

    public ExplorerAdapter(FilesManager manager, Context passedContext) {
        StoreitFile rootFile = manager.getRoot();
        ArrayList<StoreitFile> files = new ArrayList<>();
        this.manager = manager;

        for (Map.Entry<String, StoreitFile> entry : rootFile.getFiles().entrySet()) { // list all files from current folder
            files.add(entry.getValue());
        }

        historyStack.push(rootFile);

        mFiles = files.toArray(new StoreitFile[files.size()]); // Store file list
        this.context = passedContext;
        storeitPath = manager.getFolderPath();
    }

    public void backPressed() {

        if (historyStack.size() <= 1) // Check if this is not the root
            return;

        ArrayList<StoreitFile> files = new ArrayList<>();
        historyStack.pop();
        StoreitFile parentDir = historyStack.peek();

        for (Map.Entry<String, StoreitFile> entry : parentDir.getFiles().entrySet()) { // list all files from current folder
            files.add(entry.getValue());
        }
        mFiles = files.toArray(new StoreitFile[files.size()]); // Store file list
        notifyDataSetChanged();
    }

    private void createDownloadDialog(final StoreitFile file) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("Download File")
                .setMessage("File is not on phone. Download it?")
                .setPositiveButton("Yes", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        new DownloadAsync(context).execute(manager.getFolderPath(), file.getIPFSHash());
                    }
                })
                .setNegativeButton("No", null)
                .show();
    }

    public void fileClicked(int position) {

        if (!mFiles[position].isDirectory()) // Check if is a directory or a file
        {
            if (!manager.exist(mFiles[position])) {
                createDownloadDialog(mFiles[position]);
                return;
            }
            Intent intent = new Intent(Intent.ACTION_VIEW);

            File file = new File(storeitPath + File.separator + mFiles[position].getPath()); // To get the file type
            File phyiscalFile = new File(storeitPath + File.separator + mFiles[position].getIPFSHash()); // the location of the real file

            String extension = MimeTypeMap.getFileExtensionFromUrl(Uri.fromFile(file).toString());
            String mimetype = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
            intent.setDataAndType(Uri.fromFile(phyiscalFile), mimetype);

            context.startActivity(intent);

            return;
        }


        ArrayList<StoreitFile> files = new ArrayList<>();

        historyStack.push(mFiles[position]);

        for (Map.Entry<String, StoreitFile> entry : mFiles[position].getFiles().entrySet()) { // list all files from current folder
            files.add(entry.getValue());
        }
        mFiles = files.toArray(new StoreitFile[files.size()]); // Store file list

        notifyDataSetChanged();
    }

    @Override
    public ExplorerAdapter.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.file_item_row, parent, false);
        return new ViewHolder(v, viewType, context);
    }

    @Override
    public void onBindViewHolder(final ExplorerAdapter.ViewHolder holder, int position) {
        holder.fileNameTextView.setText(mFiles[position].getFileName()); // Get file name
        if (mFiles[position].isDirectory()) { // Directory, we use folder icon
            holder.fileTypeImageView.setImageResource(R.drawable.ic_folder_black_24dp);
        } else { // File, we use file icon
            holder.fileTypeImageView.setImageResource(R.drawable.ic_insert_drive_file_black_24dp);
        }
        holder.itemView.setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View v) {
                setPosition(holder.getPosition());
                return false;
            }
        });
    }

    @Override
    public int getItemCount() {
        return mFiles.length;
    }

    @Override
    public void onViewRecycled(ViewHolder holder) {
        holder.itemView.setOnLongClickListener(null);
        super.onViewRecycled(holder);
    }

    public void setPosition(int position) {
        this.position = position;
    }

    public int getPosition() {
        return position;
    }

    public StoreitFile getFileAt(int position) {
        return mFiles[position];
    }

    public void removeFile(int position) {
        ArrayList<StoreitFile> files = new ArrayList<>( Arrays.asList(mFiles));
        files.remove(position);
        mFiles = files.toArray(new StoreitFile[files.size()]);
        notifyDataSetChanged();
    }
}
