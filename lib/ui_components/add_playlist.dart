import 'package:flutter/material.dart';
import 'package:music_player/entities/song_repository.dart';

/// Provide a text box for user to enter a name of a playlist, and add that to the file system. 
class AddPlaylist extends StatelessWidget{
    final BuildContext context;
    final TextEditingController _playlistNameTextBox = TextEditingController();

    AddPlaylist({super.key, required this.context});
    
    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Create New Playlist"),
            content: TextField(
                controller: _playlistNameTextBox,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: "Playlist Name",
                    hintText: "Enter a name for your playlist",
                ),
            ),
            actions: [
                TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                    child: const Text("Create"),
                    onPressed: () {
                        final String name = _playlistNameTextBox.text.trim();
                        if (name.isNotEmpty) {
                            SongRepository.addPlaylist(name);
                            Navigator.of(context).pop();
                        }
                    },
                ),
            ],
        );
    }
}