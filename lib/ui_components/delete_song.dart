import 'package:flutter/material.dart';

import '../entities/song.dart';
import '../entities/song_repository.dart';

/// Prompt the user to delete a Song. 
class DeleteSong extends StatelessWidget{
    final String playlistName; 
    final Song someSong; 
    final bool isMaster;
    const DeleteSong({super.key, required this.playlistName, required this.someSong, this.isMaster = false});
    
    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text("Delete song : ${someSong.title}"),
            content: isMaster 
                ? Text("Are you sure you want to remove this from the master list? Reminder: It will also be removed from all playlists.")
                : Text("Are you sure you want to remove this from playlist?"),
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