import 'package:flutter/material.dart';
import 'package:music_player/entities/song_repository.dart';
import 'package:music_player/entities/song_playlist.dart';

typedef PlaylistTapCallback = void Function(SongsPlaylist playlist);

/// Displays the currently available playlist.
/// 
/// Refresh playlist songs count based on listener [playlistNotifier] from [SongRepository]. 
class PlaylistView extends StatelessWidget {
    
    final VoidCallback onAddPlaylist;
    final PlaylistTapCallback onPlaylistTap; 
    const PlaylistView({super.key, required this.onAddPlaylist, required this.onPlaylistTap});

    /// Projects all available playlists from the SongRepository.
    /// 
    /// This list of playlists is nearly identical from before. 
    /// The difference is that it is updated using the value listener [playlistNotifier] from [SongRepository].
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text("Playlists View"),
            ),
            body: ValueListenableBuilder<Map<String, SongsPlaylist>>(
                valueListenable: SongRepository.playlistNotifier,
                builder: (context, playlistsMap, child) {
                    final List<SongsPlaylist> playlists = playlistsMap.values.toList();
                    return _buildPlaylistLists(playlists);
                },
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: onAddPlaylist,
                tooltip: "Add Playlist",
                child: const Icon(Icons.add),
            ),
        );
    }

    Widget _buildPlaylistLists(List<SongsPlaylist> playlists){
        final bool isPlaylistsEmpty = playlists.isEmpty;
        /// Build placeholder
        if (isPlaylistsEmpty){
            return const Center(
                child: Text(
                    "No playlists found. Click the button on the right to create one!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
            );
        }
        /// Otherwise build list. 
        return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                    leading: const Icon(Icons.featured_play_list),
                    title: Text(playlist.playlistName),
                    subtitle: Text("${playlist.songCount} song(s)"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () {
                        onPlaylistTap(playlist);
                    },
                );
            },
        );
    }
}