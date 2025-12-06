import 'package:flutter/material.dart';
import 'package:music_player/entities/song_repository.dart';

typedef NotifyListChangedCallback = void Function();

class PlaylistsManager {
    final BuildContext context;
    final NotifyListChangedCallback notifyListChanged;
    final TextEditingController _playlistNameController = TextEditingController();

    final Future<void> Function() reloadPlaylistsList;

    PlaylistsManager({
        required this.context,
        required this.notifyListChanged,
        required this.reloadPlaylistsList,
    });
    
    /// Disposes of internal resources (TextEditingController). Must be called by the parent State.
    void dispose() {
        _playlistNameController.dispose();
    }

    /// Purely responsible for displaying the dialog and awaiting user input.
    /// Returns the trimmed name or null if the user cancels.
    Future<String?> _showAddPlaylistDialog() async {
        _playlistNameController.clear(); 

        return showDialog<String>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
                title: const Text('Create New Playlist'),
                content: TextField(
                    controller: _playlistNameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Playlist Name',
                        hintText: 'Enter a name for your playlist',
                    ),
                ),
                actions: <Widget>[
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, null), // Cancel returns null
                        child: const Text('Cancel'),
                    ),
                    TextButton(
                        onPressed: () {
                            final name = _playlistNameController.text.trim();
                            if (name.isNotEmpty) Navigator.pop(dialogContext, name);
                        },
                        child: const Text('Create'),
                    ),
                ],
            ),
        );
    }
    
    /// Handles the entire playlist creation workflow: dialog, business logic, and UI feedback.
    Future<void> handleAddPlaylist() async {

        final newPlaylistName = await _showAddPlaylistDialog();
        if (newPlaylistName == null || newPlaylistName.isEmpty) return; 
        final added = await SongRepository.addPlaylist(newPlaylistName);

        if (added) {
            notifyListChanged(); 
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Playlist "$newPlaylistName" created!')),
            );
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Playlist "$newPlaylistName" already exists.')),
            );
        }
    }
}