import 'package:flutter/material.dart';

import '../entities/song.dart';
import '../entities/song_repository.dart';

/// Prompt the user to delete a Song. 
class DeleteSong extends StatelessWidget{
    final String playlistName; 
    final Song someSong; 
    const DeleteSong({super.key, required this.playlistName, required this.someSong});
    
    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text("Delete song : ${someSong.title}"),
            content: Text("Are you sure you want to remove this from playlist?"),
            actions: [
                TextButton(
                    onPressed: ()  { 
                        Navigator.of(context).pop();
                        SongRepository.deleteSongFromPlaylist(playlistName: playlistName, newSong: someSong); 
                    },
                    child: const Text("Delete"),
                ),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                ),
            ],
        );
    }
}