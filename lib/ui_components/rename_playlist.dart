import 'package:flutter/material.dart';

import '../entities/song_repository.dart';

/// Prompt the user to rename the playlist. 
class RenamePlaylist extends StatelessWidget {
    final BuildContext context;
    final String currentPlaylistName; 
    final TextEditingController _playlistNameTextBox = TextEditingController();

    RenamePlaylist({super.key, required this.context, required this.currentPlaylistName});

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Rename Playlist"),
            content: TextField(
                controller: _playlistNameTextBox,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: "Playlist Name",
                    hintText: "Enter a new name for your playlist",
                ),
            ),
            actions: [
                TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                    child: const Text("Rename"),
                    onPressed: () {
                        final String newPlaylistName = _playlistNameTextBox.text.trim();
                        if (newPlaylistName.isNotEmpty) {
                            SongRepository.renamePlaylist(currentPlaylistName, newPlaylistName);
                            Navigator.of(context).pop();
                        }
                    },
                ),
            ],
        );
    }
}