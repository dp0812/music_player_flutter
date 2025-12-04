import 'package:flutter/material.dart';

import 'audio_player_service.dart';
import 'song.dart';
import '../song_data.dart';

// Define the required interfaces for updating the SongScreenState
typedef SetSongCallback = void Function(Song? song);
typedef SetLoopingCallback = void Function(bool isLooping);
typedef SetPositionCallback = void Function(Duration position);
typedef ResetStateCallback = void Function();

class SongControlsManager {
    final AudioPlayerService audioService;
    final BuildContext context; // Needed for status display when clicking loop. 

    // State Getters (To read the current state from the parent)
    final Song? Function() getCurrentSong;
    final bool Function() getIsLooping;

    // State Setters (To write new state and trigger rebuilds on the parent)
    final SetSongCallback setCurrentSong;
    final SetLoopingCallback setIsLooping;
    final ResetStateCallback resetPlaybackState;
    final SetPositionCallback setCurrentPosition;


    SongControlsManager({
        required this.audioService,
        required this.context,
        required this.getCurrentSong,
        required this.getIsLooping,
        required this.setCurrentSong,
        required this.setIsLooping,
        required this.resetPlaybackState,
        required this.setCurrentPosition,
    }) {
        // Playlist logic 
        audioService.audioPlayer.onPlayerComplete.listen((_) {
            _handleSongCompletion();
        });
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
    void _handleSongCompletion() {
        if (!getIsLooping()) {
            stop();
            return;
        }
        
        final currentSong = getCurrentSong();
        if (currentSong == null) return;

        final currentSongIndex = SongData.availableSongs.indexOf(currentSong);
        final nextIndex = (currentSongIndex + 1) % SongData.availableSongs.length;
        final nextSong = SongData.availableSongs[nextIndex];

        setCurrentSong(nextSong);
        audioService.playFile(nextSong.assetPath);
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
        if (getCurrentSong() == null && SongData.availableSongs.isNotEmpty) { 
            final firstSong = SongData.availableSongs.first;
            setCurrentSong(firstSong); 
            audioService.playFile(firstSong.assetPath);
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
}