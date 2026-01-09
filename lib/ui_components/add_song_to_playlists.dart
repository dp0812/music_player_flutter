import 'package:flutter/material.dart';
import 'package:music_player/ui_components/custom_checkbox_list_tile.dart';

import '../entities/song.dart';
import '../entities/song_repository.dart';

/// Let the user add the current song to available Playlist(s) using checkbox.
/// 
/// This required the Repository to properly be loaded BEFORE its usage.  
class AddSongToPlaylists extends StatefulWidget {
    final Song currentSong;
    
    const AddSongToPlaylists({super.key, required this.currentSong});

    @override
    State<AddSongToPlaylists> createState() => AddSongToPlaylistsState();
}

class AddSongToPlaylistsState extends State<AddSongToPlaylists> {
    /// Track selected playlists to be added. 
    final List<String> _selectedPlaylists = [];

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Select Playlist(s) to add to:"),
            content: SingleChildScrollView(
                child: ListBody(
                    children: [
                        ...SongRepository.allSongPlaylists.values 
                            .map((songsPlaylist) { 
                                return CustomCheckboxListTile(
                                    title: songsPlaylist.playlistName, 
                                    subtitle: "${songsPlaylist.songCount} song(s)",
                                    isSelected: _selectedPlaylists.contains(songsPlaylist.playlistName),
                                    onChanged: (bool? isChecked) => _checkedItem(songsPlaylist.playlistName, isChecked!),
                                );
                            }),
                    ],
                ),
            ),
            actions: [
                /// Close dialog without saving.
                TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.of(context).pop(),
                ),
                
                /// Add to selected playlist(s) and closes dialog.
                TextButton(
                    child: const Text("Add"),
                    onPressed: () {
                        _addSongToSelectedPlaylists();
                        Navigator.of(context).pop();
                    },
                ),
            ],
            actionsAlignment: MainAxisAlignment.spaceBetween,
        );
    }

    /// Add current song to selected playlists and save that to disk. 
    void _addSongToSelectedPlaylists() async {
        await SongRepository.addSongToSelectedPlaylists(
            playlistNames: _selectedPlaylists, 
            newSong: widget.currentSong, 
        );
    }

    /// If the box is checked, add item to the list. 
    void _checkedItem (String somePlaylist, bool isSelected){
        setState(() {
            if (isSelected){
                _selectedPlaylists.add(somePlaylist);
            } else {
                _selectedPlaylists.remove(somePlaylist);
            }
        });
    }
}