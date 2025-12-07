import 'package:flutter/material.dart';
import '../entities/song.dart';

/// Display the current list of Song objects. 
/// 
/// This widget is built to be used when user wants to see what the Songs inside some container. 
class SongList extends StatelessWidget {
    final List<Song> songs;
    final Song? currentSong;
    /// Callback function to communicate taps back to the parent state
    final Function(Song) onSongTap;

    const SongList({
        super.key,
        required this.songs,
        required this.currentSong,
        required this.onSongTap,
    });
    /// Projects the song list and highlight what song is currently being play. 
    @override
    Widget build(BuildContext context) {
        return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(song.title),
                    onTap: () => onSongTap(song),
                    selected: song == currentSong,
                    selectedTileColor: Colors.blue.shade100,
                );
            },
        );
    }
}