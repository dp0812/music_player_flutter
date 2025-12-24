import 'package:flutter/material.dart';

import '../entities/song_repository.dart';

/// Prompt the user to delete the playlist. 
class DeletePlaylist extends StatelessWidget {
    final String playlistName; 
    
    const DeletePlaylist({super.key, required this.playlistName});

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text("Delete Playlist: $playlistName"),
            content: Text("Are you sure you want to delete this playlist?"),
            actions: [
                TextButton(
                    onPressed: ()  { 
                        SongRepository.deletePlaylist(playlistName);  
                        Navigator.of(context).pop();
                    },
                    child: Text("Delete"),
                ),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                ),
            ],
        );
    }
}