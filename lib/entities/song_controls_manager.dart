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

class SongControlsManager {
    final AudioPlayerService audioService;
    final BuildContext context; // Needed for status display when clicking loop. 

    StreamSubscription<Duration>? _onPositionSubscription;
    StreamSubscription<Duration>? _onDurationSubscription;
    StreamSubscription<PlayerState>? _playerStateSubscription;
    StreamSubscription<void>? _playerCompleteSubscription;

    // State Getters (To read the current state from the parent)
    final Song? Function() getCurrentSong;
    final bool Function() getIsLooping;
    final GetSongListCallback getCurrentSongList;

    // State Setters (To write new state and trigger rebuilds on the parent)
    final SetSongCallback setCurrentSong;
    final SetLoopingCallback setIsLooping;
    final ResetStateCallback resetPlaybackState;
    final SetPositionCallback setCurrentPosition;
    final SetDurationCallback setCurrentDuration; 
    final AddSongCallback notifySongListChanged;
    //List<Song> currentSongList; 

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
        //required this.currentSongList,
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

    /// Method to cancel the audio stream subscriptions.
    /// This must be called from the parent widget's dispose() method.
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

    /// Synchronizes the UI state with the persistent audio service when the page loads.
    /// Synchronizes the UI state with the persistent audio service when the page loads.
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
        
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Looping this playlist: ${newLoopingState ? "ON" : "OFF"}'),
                duration: const Duration(milliseconds: 1000),
            ),
        );
    }

    /// The only function called by the song manager itself, not by user action. 
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
                        content: Text('Removing missing file: ${nextSong.title}'),
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
        
        final currentSongList = getCurrentSongList();  // Get fresh list
        // Play the first song if nothing is playing/on pause.  
        if (getCurrentSong() == null && currentSongList.isNotEmpty) { 
            final firstSong = currentSongList.first;
            setCurrentSong(firstSong); 
            audioService.playFile(firstSong.assetPath);
        }
    }

    /// Play song when user clicks on it. 
    Future <void> playSelectedSong(Song song) async{
        if (await SongRepository.isSongFileAvailable(song.assetPath)) {
            // If valid, play the song (delegating to the UI to update the state)
            setCurrentSong(song); // Updates _currentSong in SongScreenState
            audioService.playFile(song.assetPath);
        } else {
            // If missing: Notify user, clean up file, and refresh UI
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Song file is missing or moved: ${song.title}')),
            );
            await reloadSongList(); 
            //Reset the currently playing song if the missing song was the current one
            if (getCurrentSong()?.assetPath == song.assetPath) {resetPlaybackState();}
        }
    }

    /// Stops playback and resets the UI state (song, duration, position) -  User action dependent.
    void stop() {
        audioService.stop();
        // Implementation of resetPlaybackState is in the song_screen_state.dart init function. 
        resetPlaybackState(); 
    }
    
    /// Handles when the user moves the slider - User action dependent. 
    void handleSeek(double value) {
        final newPosition = Duration(milliseconds: value.round());
        audioService.seek(newPosition);        
        // Update the UI position
        setCurrentPosition(newPosition);
    }

    /// Opens the system file picker, filters for MP3, and adds selected songs to the list.
    /// 
    /// Actual logic is delegated to SongRepository. Go there and check!
    Future<void> handleAddSong({String? playlistName}) async {
        int songsAdded = await SongRepository.addSongsFromUserSelection(); 
        if (songsAdded > 0) {
            // Notify the SongScreenState to rebuild the SongList
            notifySongListChanged();  
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$songsAdded song(s) added!')),
            );
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new songs selected.')),
            );
        }
    }
}