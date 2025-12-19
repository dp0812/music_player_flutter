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
    final PlaylistTapCallback? onPlaylistButtonTap; 
    const PlaylistView({super.key, required this.onAddPlaylist, required this.onPlaylistTap, this.onPlaylistButtonTap});

    /// Projects all available playlists from the SongRepository.
    ///  
    /// Use the change notifier [playlistNotifier] from [SongRepository] to update its view everytime a change to the data happen (not just identity change).
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text("Playlists View"),
            ),
            body: AnimatedBuilder(
                animation: SongRepository.playlistNotifier,
                builder: (context, child) {
                    final List<SongsPlaylist> playlists = 
                        SongRepository.playlistNotifier.playlists.values.toList();
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
                    onTap: () => onPlaylistTap(playlist),
                    trailing: 
                        Row(
                            spacing: 1.0,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(Icons.more_vert), // needs tooltip rework. 
                                if (onPlaylistButtonTap != null)
                                IconButton (
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => onPlaylistButtonTap!(playlist),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Delete Playlist", 
                                ),
                            ],
                        ) 
                );
            },
        );
    }
}