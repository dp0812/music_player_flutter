import 'package:flutter/material.dart';
import 'package:music_player/entities/song_repository.dart';
import 'package:music_player/entities/song_playlist.dart';

class PlaylistView extends StatelessWidget {
    
    final VoidCallback onAddPlaylist;
    const PlaylistView({super.key, required this.onAddPlaylist});

    /// Projects all available playlists from the SongRepository.
    @override
    Widget build(BuildContext context) {
        final List<SongsPlaylist> playlists = SongRepository.allSongPlaylists.values.toList();
        final isPlaylistsEmpty = playlists.isEmpty;

        return Scaffold(
            appBar: AppBar(
                title: const Text("Playlists View"),
            ),
            body: isPlaylistsEmpty? 
                const Center(
                    child: Text(
                        "No playlists found. Click the button on the right to create one!",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                )
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                            leading: const Icon(Icons.featured_play_list),
                            title: Text(playlist.playlistName),
                            subtitle: Text("${playlist.songCount} song(s)"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                            // TODO: tap should move to playlist page!
                            onTap: () {
                                print("Tapped on playlist: ${playlist.playlistName}");
                            },
                        );
                    },
                ),
            floatingActionButton: FloatingActionButton(
                onPressed: onAddPlaylist, // Calls the handler from the state
                tooltip: "Add Playlist",
                child: const Icon(Icons.add),
            ),
        );
    }
}