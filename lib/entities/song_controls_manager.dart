import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:music_player/utilities/io_print.dart';

import 'audio_player_service.dart';
import 'song.dart';
import 'song_repository.dart';

// Define the required interfaces for updating the SongScreenState
typedef SetSongCallback = void Function(Song? song);
typedef SetLoopingCallback = void Function(bool isLooping);
typedef SetPositionCallback = void Function(Duration position);
typedef SetDurationCallback = void Function(Duration duration); 
typedef ResetStateCallback = void Function();
typedef AddSongCallback = void Function();
typedef GetSongListCallback = List<Song> Function();  // Indicating which song List we are working with. 

/// This class provides service for pause, resume, stop, loop and progress bar information for songs. 
/// 
/// Client of this class must call [cancelAudioStreams] in their dispose function to ensure the audio is correctly stopped. 
class SongControlsManager {
    final AudioPlayerService audioService;
    final BuildContext context; // Needed for status display when clicking loop. 

    // Information to display the progress bar. 
    StreamSubscription<Duration>? _onPositionSubscription;
    StreamSubscription<Duration>? _onDurationSubscription;

    // To cancel the audio 
    StreamSubscription<PlayerState>? _playerStateSubscription;
    StreamSubscription<void>? _playerCompleteSubscription;

    // Read the current state from the parent.
    final Song? Function() getCurrentSong;
    final bool Function() getIsLooping;
    final GetSongListCallback getCurrentSongList;

    // Write new state and trigger rebuilds on the parent.
    final SetSongCallback setCurrentSong;
    final SetLoopingCallback setIsLooping;
    final ResetStateCallback resetPlaybackState;
    final SetPositionCallback setCurrentPosition;
    final SetDurationCallback setCurrentDuration; 
    final AddSongCallback notifySongListChanged;
    /// Caller should supply the reference to [_loadAndSynchronizeSongs] for this attribute, not calling the function.    
    final Future<void> Function() reloadSongList;

    SongControlsManager({
        required this.audioService,
        required this.context,
        required this.getCurrentSong,
        required this.getIsLooping,
        required this.setCurrentSong,
        required this.getCurrentSongList,  // Caller provide the current Song list. 
        required this.setIsLooping,
        required this.resetPlaybackState,
        required this.setCurrentPosition,
        required this.setCurrentDuration, 
        required this.notifySongListChanged,
        required this.reloadSongList,
    }) {
        // Initialize stream listeners and store the subscriptions
        _onDurationSubscription = audioService.onDurationChanged.listen((d) {
            setCurrentDuration(d);
        });
        
        _onPositionSubscription = audioService.onPositionChanged.listen((p) {
            setCurrentPosition(p);
        });

        // Playlist logic 
        _playerCompleteSubscription = audioService.audioPlayer.onPlayerComplete.listen((_) {
            _handleSongCompletion();
        });

        // Listen to player state changes
        _playerStateSubscription = audioService.audioPlayer.onPlayerStateChanged.listen((state) {
            // This is just prep. WIP
        });
    }

    /// Cancel the audio stream subscriptions and set everything subscription to null.
    /// 
    /// This must be called in the parent's [dispose] function to avoid any left over audio when leave the current the tab.
    void cancelAudioStreams() {
        _onPositionSubscription?.cancel();
        _onDurationSubscription?.cancel();
        _playerCompleteSubscription?.cancel();
        _playerStateSubscription?.cancel();
        
        // Reset all subscriptions to null
        _onPositionSubscription = null;
        _onDurationSubscription = null;
        _playerCompleteSubscription = null;
        _playerStateSubscription = null;
    }

    /// Correctly update the current duration and position for a song, when switching between different pages. 
    /// 
    /// This function is called to make sure there is no left over audio while the progress bar is empty.
    Future<void> synchronizePlaybackState() async {
        try {
            final currentAssetPath = audioService.currentAssetPath; 
            final songList = getCurrentSongList();  // Get current list
            
            if (currentAssetPath != null) {
                // Find the Song object corresponding to the playing file
                final playingSong = songList.firstWhere(
                    (song) => song.assetPath == currentAssetPath,
                );
                
                // Update the UI's current song state
                setCurrentSong(playingSong);
                // Read the current position and duration and update the UI's state (async)
                final position = await audioService.getCurrentPosition() ?? Duration.zero;
                final duration = await audioService.getCurrentDuration() ?? Duration.zero;
                setCurrentPosition(position); 
                setCurrentDuration(duration);
                
            }
        } catch (e) {
            IO.e("Error synchronizing playback state: ",error: e);
        }
    }

    /// Toggle looping behavior of the current Song List - User action dependent. 
    void toggleLoop() {
        final newLoopingState = !getIsLooping();
        setIsLooping(newLoopingState);
        showMessage("Looping this playlist: ${newLoopingState ? "ON" : "OFF"}", duration: const Duration(seconds: 1));
    }

    /// If [getIsLooping] is false, stop the audio. Otherwise find the next Song in the list. 
    /// 
    /// This is called internally by the song_controls_manager. 
    void _handleSongCompletion() async {
        if (!getIsLooping()) {
            stop();
            return;
        }

        final currentSong = getCurrentSong();
        if (currentSong == null) return;
        final currentSongList = getCurrentSongList();  // Get fresh list
        final currentSongIndex = currentSongList.indexOf(currentSong);
        
        if (currentSongIndex == -1) {
            // Current song not found in list, try the first song
            if (currentSongList.isNotEmpty) {
                final firstSong = currentSongList.first;
                setCurrentSong(firstSong);
                audioService.playFile(firstSong.assetPath);
            } else {
                stop();
            }
            return;
        }
        
        final nextIndex = (currentSongIndex + 1) % currentSongList.length;
        final nextSong = currentSongList[nextIndex];

        if (await SongRepository.isSongFileAvailable(nextSong.assetPath)){
            setCurrentSong(nextSong);
            audioService.playFile(nextSong.assetPath);
        } else {
            // If missing: Notify user, clean up file, and refresh UI
            if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Removing missing file: ${nextSong.title}"),
                        duration: const Duration(milliseconds: 1500),
                    ),
                );
            }
            
            await reloadSongList(); 
            
            if (getIsLooping() && context.mounted) {
                await Future.delayed(const Duration(milliseconds: 100)); // make sure UI have time to refresh. 
                _handleSongCompletion();
            }
        }
    }

    /// Handles Play, Resume, and Pause based on the audio state - User action dependent. 
    void handlePlayResumePause() {
        
        if (audioService.isPlaying) {
            audioService.pause();
            // Call a setter to force a UI refresh (Play/Pause button change)
            setIsLooping(getIsLooping()); 
            return;
        }
        if (audioService.isPaused) {
            audioService.resume();
            // Call a setter to force a UI refresh (loop on/loop off)
            setIsLooping(getIsLooping()); 
            return;
        }
        
        // Play the first song if nothing is playing/on pause. 
        final currentSongList = getCurrentSongList();
        if (getCurrentSong() == null && currentSongList.isNotEmpty) { 
            final firstSong = currentSongList.first;
            setCurrentSong(firstSong); 
            audioService.playFile(firstSong.assetPath);
        }
    }

    /// Play song when user clicks on it. 
    Future <void> playSelectedSong(Song song) async{
        if (await SongRepository.isSongFileAvailable(song.assetPath)) {
            setCurrentSong(song); // Updates _currentSong
            audioService.playFile(song.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${song.title}'");
            stop();
            await reloadSongList(); 
        }
    }

    /// Stops playback and resets the UI state (song, duration, position) -  User action dependent.
    void stop() {
        audioService.stop(); 
        resetPlaybackState(); 
    }
    
    /// Handles when the user moves the slider - User action dependent. 
    void handleSeek(double value) {
        final newPosition = Duration(milliseconds: value.round());
        audioService.seek(newPosition);        
        // Update the UI position
        setCurrentPosition(newPosition);
    }

    /// Opens the system file picker, filters for MP3, and adds selected songs to the masterList. 
    /// 
    /// Does not change any other storage file than the masterList.txt. Actual logic is delegated to [SongRepository].
    Future<void> handleAddSong() async {
        int songsAdded = await SongRepository.addSongsFromUserSelection(); 
        if (songsAdded > 0) {
            // Notify the SongScreenState to rebuild the SongList
            notifySongListChanged();  
            showMessage("$songsAdded song(s) added!");
        } else {
            showMessage("No new songs selected.");
        }
    }

    /// Helper to display snackbar message with a preset duration. 
    void showMessage(String message, {Duration duration = const Duration(seconds: 2)}){
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: duration),
        );
    }
}