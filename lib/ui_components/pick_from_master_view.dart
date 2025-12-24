import 'package:flutter/material.dart';

import '../entities/song.dart';
import '../entities/song_repository.dart';

/// Class provides a menu for selecting multiple Songs from the master list using checkbox. 
/// 
/// This is invoked inside the playlists_list.dart
class PickFromMasterView extends StatefulWidget {
    final String currentPlaylistName;
    
    const PickFromMasterView({super.key, required this.currentPlaylistName});

    @override
    State<PickFromMasterView> createState() => _PickFromMasterViewState();
}

class _PickFromMasterViewState extends State<PickFromMasterView> {
    /// Track selected songs to be added. 
    final List<Song> _selectedSongs = [];

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Select Songs:"),
            content: SingleChildScrollView(
                child: ListBody(
                    children: [
                        ...SongRepository.masterSongPlaylist.getCurrentPlaylistSongs()
                            .map((song) {
                                return CheckboxListTile(
                                    title: Text(song.title),
                                    value: _selectedSongs.contains(song),
                                    onChanged: (bool? isChecked) => _checkedItem(song, isChecked!),
                                );
                            }),
                    ],
                ),
            ),
            actions: [
                /// Closes dialog without saving.
                TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.of(context).pop(),
                ),
                
                /// Adds selected songs and closes dialog.
                TextButton(
                    child: const Text("Add"),
                    onPressed: () {
                        _addSelectedSongsToPlaylist();
                        Navigator.of(context).pop();
                    },
                ),
            ],
            actionsAlignment: MainAxisAlignment.spaceBetween,
        );
    }

    /// Add selected songs to playlist and save that to disk. 
    void _addSelectedSongsToPlaylist() async {
        await SongRepository.addSongsFromCollection(
            playlistName: widget.currentPlaylistName,
            newSongs: _selectedSongs,
        );
    }

    /// If the box is checked, add item to the list. 
    void _checkedItem (Song someSong, bool isSelected){
        setState(() {
            if (isSelected){
                _selectedSongs.add(someSong);
            } else {
                _selectedSongs.remove(someSong);
            }
        });
    }
}