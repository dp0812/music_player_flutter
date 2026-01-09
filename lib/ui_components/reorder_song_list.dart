import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_player/ui_components/custom_list_tile.dart';
import 'package:music_player/ui_components/trailing_row.dart';

import 'album_art.dart';
import 'rotating_disc.dart';
import '../entities/song.dart';
import '../entities/song_controls_manager.dart';
import '../entities/song_playlist.dart';
import '../entities/song_repository.dart';
import '../entities/song_saver.dart';

/// A dragable song list for reordering song in a playlist. 
/// 
/// Include a bottom padding (by default = 180) just enough for the dock in compact mode when scroll to the bottom of the list. 
/// 
/// The update (write back to file) is immediate after EACH movement, where a movement is defined as a transition from the source index to the target index, 
/// and source != target and the user has lift the mouse (or finger) so the item can relocate itself correctly. 
/// 
/// From this movement mechanics, the following are established:
/// 1. Corollary 1: Moving the song around many times but not putting it down will NOT trigger the rewrite multiple times.
/// 2. Corollary 2: The confirm and the back button (on the app bar) of whoever call this widget is of no use - that is, the saving of a new order does not depend on them. 
class ReorderableSongList extends StatefulWidget {
    final SongsPlaylist currentPlaylist;
    final Song? currentSong;

    final SongControlsManager controlsManager;
    final ValueChanged<List<Song>> onSongsReordered;
    final double bottomPadding;
    /// Decide whether to display the rotating disc and the wavy sound effect. 
    final bool isPlaying;
    final double dragHandleSpacing;

    const ReorderableSongList({
        super.key,
        this.currentSong,
        required this.currentPlaylist,
        required this.controlsManager,
        required this.onSongsReordered,
        this.isPlaying = false,
        this.bottomPadding = 180,
        this.dragHandleSpacing = 16,
    });

    @override
    State<ReorderableSongList> createState() => _ReorderableSongListState();
}

class _ReorderableSongListState extends State<ReorderableSongList> {
    List<Song> _localSongs = [];

    @override
    void initState() {
        super.initState();
        _localSongs = List<Song>.from(widget.currentPlaylist.getCurrentPlaylistSongs());
    }

    @override
    void didUpdateWidget(ReorderableSongList oldWidget) {
        super.didUpdateWidget(oldWidget);
        if (widget.currentPlaylist.getCurrentPlaylistSongs().length != _localSongs.length ||
            !_areSongListsEqual(widget.currentPlaylist.getCurrentPlaylistSongs(), _localSongs)) {
        _localSongs = List<Song>.from(widget.currentPlaylist.getCurrentPlaylistSongs());
        }
    }

    @override
    Widget build(BuildContext context) {
        return ReorderableListView.builder(
            // Remove the default right handle (which look very bad with the custom list tile). 
            buildDefaultDragHandles: false, 
            padding: EdgeInsets.only(
                bottom: widget.bottomPadding + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: _localSongs.length,
            itemBuilder: (context, index) {
                final song = _localSongs[index];
                // Highlight and rotating leading logic. 
                final isSamePlaylist = (widget.currentPlaylist.playlistName == SongControlsManager.activeSongsPlaylist.playlistName);
                final isSelected = song.isEqual(widget.currentSong) && isSamePlaylist;
                final bool shouldRotate = isSelected && widget.isPlaying;
                // Highlight effect. 
                final selectedTileEffect = BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha:0.3)),
                );
                
                return Container(
                    key: ValueKey(song.assetPath),
                    child: Row(
                        children: [
                            _buildMinimalistDragHandle(context, index),
                            SizedBox(width: widget.dragHandleSpacing),
                            Expanded(
                                child: CustomListTile(
                                    title: song.title, 
                                    subtitle: song.artist ?? "Unknown", 
                                    onTap: () {
                                        HapticFeedback.lightImpact();
                                    },
                                    isSelected: isSelected,
                                    selectedTextColor: Theme.of(context).colorScheme.onPrimary,
                                    selectedTileEffect: selectedTileEffect,
                                    leading: shouldRotate || isSelected
                                        ? RotatingDisc(
                                            isPlaying: shouldRotate,
                                            child: AlbumArt(
                                            albumArtBytes: song.albumArtBytes,
                                            artWidth: 30,
                                            artHeight: 30,
                                            ),
                                        )
                                        : AlbumArt(
                                            albumArtBytes: song.albumArtBytes,
                                            artWidth: 30,
                                            artHeight: 30,
                                        ),
                                
                                    trailing: TrailingRow(
                                        song: song,
                                        isSelected: isSelected,
                                        isPlaying: widget.isPlaying,
                                    ),
                                ),
                            ),
                        ],
                    ),
                );
            },

            onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) newIndex -= 1;
                
                setState(() {
                    final Song movedSong = _localSongs.removeAt(oldIndex);
                    _localSongs.insert(newIndex, movedSong);
                });

                // Update the current re ordering playlist.
                widget.currentPlaylist.replaceSongs(_localSongs);
                // Save to repository and file
                await _saveCurrentPlaylistOrder();
                // Provide new song to parent widget.
                widget.onSongsReordered(_localSongs);    
                HapticFeedback.selectionClick();
            },

            proxyDecorator: (child, index, animation) {
                return Material(
                elevation: 8,
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                child: child,
                );
            },
        );
    }

    /// New handle, with better color. 
    Widget _buildMinimalistDragHandle(BuildContext context, int index) {
        return ReorderableDragStartListener(
            index: index,
            child: Container(
            width: 40,
            padding: const EdgeInsets.only(left: 16),
            child: Center(
                child: Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
                    size: 24,
                
                ),
            ),
            ),
        );
    }

    Future<void> _saveCurrentPlaylistOrder() async {
        final playlistName = widget.currentPlaylist.playlistName;
        
        if (SongRepository.allSongPlaylists.containsKey(playlistName)) {
            SongRepository.allSongPlaylists[playlistName]!.replaceSongs(_localSongs);
            
            await SongSaver.savePlaylist(
                playlistName: playlistName,
                songs: _localSongs,
            );
            
            SongRepository.playlistNotifier.updatePlaylist(
                playlistName,
                SongRepository.allSongPlaylists[playlistName]!,
            );
        }
    }

    /// Check both the length and the content. 
    /// 
    /// Remarks: This is different from the last version due to the reorder feature. 
    /// Since reordering does not change the total number of song, we need to check each Song in the list, WITH the ordering exactly as they are. 
    /// If we spot a different, we know that some reordering has been done.
    bool _areSongListsEqual(List<Song> list1, List<Song> list2) {
        if (list1.length != list2.length) return false;
        for (int i = 0; i < list1.length; i++) {
            if (!list1[i].isEqual(list2[i])) return false; 
        }
        return true;
    }
}