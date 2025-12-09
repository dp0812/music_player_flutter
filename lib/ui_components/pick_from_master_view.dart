import 'package:flutter/material.dart';

import 'package:music_player/entities/song.dart';
import 'package:music_player/entities/song_repository.dart';

/// Class provides a menu for selecting Song from the master list. 
/// 
/// This is invoked inside the playlist view. 
class PickFromMasterView extends StatelessWidget{

    final String currentPlaylistName; 
    const PickFromMasterView({super.key, required this.currentPlaylistName});

    /// The only usage of clicking on a song is to select it. For now, no multiple selection allowed. 
    void _addSongToPlaylist(Song currentSong){
        SongRepository.addSongsFromCollection(playlistName: currentPlaylistName, newSong: currentSong);
    }

    @override
    Widget build(BuildContext context) {
        return SimpleDialog(
            title: const Text("Select a Song: "), 
            children: [ // that ... is the spread operator, for pulling out each item. 
                ...SongRepository.songCollection.map((song) {
                    return ListTile(
                    title: Text(song.title),
                    onTap: () {
                        _addSongToPlaylist(song);
                        Navigator.of(context).pop(); // Close the dialog
                    },
                    );
                }),
                Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close"),
                    ),
                ),
            ],
        );
    }
}