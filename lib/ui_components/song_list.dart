import 'package:flutter/material.dart';
import '../entities/song.dart';

/// Display the current list of Song objects. 
/// 
/// This widget is built to be used when user wants to see what the Songs inside some container. 
class SongList extends StatelessWidget {
    final List<Song> songs;
    final Song? currentSong;
    /// Callback function to do something with the tapped tile. 
    final Function(Song) onSongTap;
    /// Callback function for the trailing button. 
    final Function(Song)? onSongButtonTap;

    const SongList({
        super.key,
        required this.songs,
        required this.currentSong,
        required this.onSongTap,
        this.onSongButtonTap
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
                    selectedTileColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    trailing: // button append to the right of the list. 
                        Row(
                            //if not provided the correct function, then we dont display the button
                            mainAxisSize: MainAxisSize.min,
                            children: [ // The idea is to add more button later on. 
                            if (onSongButtonTap!= null)
                                IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red), 
                                    onPressed: () => onSongButtonTap!(song),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Delete Song", 
                                )
                            ]
                        )
                );
            },
        );
    }
}