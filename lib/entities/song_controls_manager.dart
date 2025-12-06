import 'package:flutter/material.dart';

import 'audio_player_service.dart';
import 'song.dart';
import 'song_repository.dart';

// Define the required interfaces for updating the SongScreenState
typedef SetSongCallback = void Function(Song? song);
typedef SetLoopingCallback = void Function(bool isLooping);
typedef SetPositionCallback = void Function(Duration position);
typedef ResetStateCallback = void Function();
typedef AddSongCallback = void Function();

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
    final AddSongCallback notifySongListChanged;

    final Future<void> Function() reloadSongList;

    SongControlsManager({
        required this.audioService,
        required this.context,
        required this.getCurrentSong,
        required this.getIsLooping,
        required this.setCurrentSong,
        required this.setIsLooping,
        required this.resetPlaybackState,
        required this.setCurrentPosition,
        required this.notifySongListChanged,
        required this.reloadSongList,
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
    void _handleSongCompletion() async {
        if (!getIsLooping()) {
            stop();
            return;
        }
        
        final currentSong = getCurrentSong();
        if (currentSong == null) return;

        final currentSongIndex = SongRepository.songCollection.indexOf(currentSong);
        final nextIndex = (currentSongIndex + 1) % SongRepository.songCollection.length;
        final nextSong = SongRepository.songCollection[nextIndex];
        setCurrentSong(nextSong);

        // This is a temporary ass fix. Why? For some reason I CAN NOT MAKE IT REBUILD THE UI for the 1st time loading the app after spotting an invalid file. 
        // I DONT UNDERSTANDDD AAAA.
        if (await SongRepository.isSongFileAvailable(nextSong.assetPath)){
            audioService.playFile(nextSong.assetPath);
        } else {
            // If missing: Notify user, clean up file, and refresh UI
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Song file is missing or moved: ${nextSong.title}')),
            );
            await reloadSongList(); 
            // Shoot to the next song, skipping the invalid song. 
            if (getCurrentSong()?.assetPath == nextSong.assetPath) {_handleSongCompletion();} 
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
        if (getCurrentSong() == null && SongRepository.songCollection.isNotEmpty) { 
            final firstSong = SongRepository.songCollection.first;
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
    /// Actual logic is delegated to SongRepository. Go there and check!
    Future<void> handleAddSong() async {
        final songsAdded = await SongRepository.addSongsFromUserSelection(); 
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