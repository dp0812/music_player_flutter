import 'package:flutter/material.dart';
import 'package:music_player/entities/song_repository.dart';

typedef LoadAndSyncPlaylists = Future<void> Function();

class PlaylistsManager {
    final BuildContext context;
    final LoadAndSyncPlaylists reloadPlaylistsList;
    final TextEditingController _playlistNameController = TextEditingController();

    PlaylistsManager({
        required this.context,
        required this.reloadPlaylistsList,
    });

    /// Handles the entire playlist creation workflow: dialog, business logic, and UI feedback.
    Future<void> handleAddPlaylist() async {

        final newPlaylistName = await _showAddPlaylistDialog();
        if (newPlaylistName == null || newPlaylistName.isEmpty) return; 
        final added = await SongRepository.addPlaylist(newPlaylistName);

        if (added) {
            await reloadPlaylistsList(); 
            showMessage('Playlist "$newPlaylistName" created!');
        } else {
            showMessage('Error: Playlist "$newPlaylistName" already exists.');
        }
    }

    /// Purely responsible for displaying the dialog and awaiting user input.
    /// 
    /// Returns the trimmed name if it is not empty, otherwise null.
    Future<String?> _showAddPlaylistDialog() async {
        _playlistNameController.clear(); 

        return showDialog<String>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
                title: const Text("Create New Playlist"),
                content: TextField(
                    controller: _playlistNameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: "Playlist Name",
                        hintText: "Enter a name for your playlist",
                    ),
                ),
                actions: <Widget>[
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, null), // Cancel returns null
                        child: const Text("Cancel"),
                    ),
                    TextButton(
                        onPressed: () {
                            final name = _playlistNameController.text.trim();
                            if (name.isNotEmpty) Navigator.pop(dialogContext, name);
                        },
                        child: const Text("Create"),
                    ),
                ],
            ),
        );
    }

    /// Disposes of internal resources (TextEditingController). Must be called by the parent State.
    void dispose() {
        _playlistNameController.dispose();
    }

    /// Helper to display snackbar message with a preset duration. 
    void showMessage(String message, {Duration duration = const Duration(seconds: 2)}){
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: duration),
        );
    }
}