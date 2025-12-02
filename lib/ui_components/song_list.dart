import 'package:flutter/material.dart';
import '../entities/song.dart';
// ------------------------------------------------
// 3. Extracted UI Component: Song List
// ------------------------------------------------

class SongList extends StatelessWidget {
    final List<Song> songs;
    final Song? currentSong;
    // Callback function to communicate taps back to the parent state
    final Function(Song) onSongTap;

    const SongList({
        super.key,
        required this.songs,
        required this.currentSong,
        required this.onSongTap,
    });

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