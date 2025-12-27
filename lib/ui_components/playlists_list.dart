import 'package:flutter/material.dart';

import '../entities/song_repository.dart';
import '../entities/song_playlist.dart';

typedef PlaylistTapCallback = void Function(SongsPlaylist playlist);

/// Displays the currently available playlist(s).
/// 
/// Refresh playlist songs count based on listener [playlistNotifier] from [SongRepository]. 
class PlaylistsList extends StatelessWidget {
    final PlaylistTapCallback onPlaylistTap; 
    final PlaylistTapCallback? onPlaylistButtonTap; 
    
    const PlaylistsList({
        super.key, 
        required this.onPlaylistTap, 
        this.onPlaylistButtonTap
    });

    /// Projects all available playlists from the SongRepository.
    ///  
    /// Use the change notifier [playlistNotifier] from [SongRepository] to update its view everytime a change to the data happen (not just identity change).
    @override
    Widget build(BuildContext context) {
        // Warning: this is here to ensure that the playlist page state has the correct numbers of song after adding songs. 
        return Scaffold(
            body: AnimatedBuilder(
                animation: SongRepository.playlistNotifier,
                builder: (context, child) {
                    final List<SongsPlaylist> playlists = 
                        SongRepository.playlistNotifier.playlists.values.toList();
                    return _buildPlaylistsIfAvailable(playlists);
                },
            ),
        );
    }

    /// If there exist some playlist => provide list of playlists. Otherwise provide placeholder.  
    Widget _buildPlaylistsIfAvailable(List<SongsPlaylist> playlists){
        return playlists.isEmpty
            ? _buildPlaceholderIfNoPlaylistFound()
            : _buildPlaylistLists(playlists);
    }

    Widget _buildPlaylistLists(List<SongsPlaylist> playlists){
        return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                    leading: const Icon(Icons.featured_play_list),
                    title: Text(playlist.playlistName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${playlist.songCount} song(s)"),
                    onTap: () => onPlaylistTap(playlist),
                    trailing: 
                        Row(
                            spacing: 2.0,
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

    Widget _buildPlaceholderIfNoPlaylistFound(){
        return const Center(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    "No playlists found. Click the 'Add Playlist' button to create one!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                ),
            ),
        );
    }
}