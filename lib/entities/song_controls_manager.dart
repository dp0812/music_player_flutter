import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:music_player/utilities/io_print.dart';

import 'audio_player_service.dart';
import 'song.dart';
import 'song_repository.dart';

// Define the required interfaces for updating the SongScreenState
typedef SetSongCallback = void Function(Song? song);
typedef SetLoopingCallback = void Function(bool isLooping);
typedef SetRandomCallback = void Function(bool isRandom);
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

    // Replay same song logic 
    final StreamController<Song?> _currentSongController = StreamController<Song?>.broadcast();
    Stream<Song?> get onCurrentSongChanged => _currentSongController.stream;
    Song? _lastPlayedSong;
    bool _songEnded = false; 
    bool get getSongEnded => _songEnded;

    /// Loop state changes.
    final StreamController<bool> _loopController = StreamController<bool>.broadcast();
    Stream<bool> get onLoopChanged => _loopController.stream;

    /// Random state changes. 
    final StreamController<bool> _randomController = StreamController<bool>.broadcast();
    Stream<bool> get onRandomChanged => _randomController.stream;

    /// Position on the progress bar in and out of [SongDetailPageState]. 
    final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
    Stream<Duration> get onPositionChanged => _positionController.stream;

    // Information to display the progress bar. 
    StreamSubscription<Duration>? _onPositionSubscription;
    StreamSubscription<Duration>? _onDurationSubscription;

    // To cancel the audio 
    StreamSubscription<PlayerState>? _playerStateSubscription;
    StreamSubscription<void>? _playerCompleteSubscription;

    // Read the current state from the parent.
    final Song? Function() getCurrentSong;
    final bool Function() getIsLooping;

    final bool Function() getIsRandom; 
    /// Caller must supply this with the current working lists of Song. 
    final GetSongListCallback getCurrentSongList;

    // Write new state and trigger rebuilds on the parent.
    final SetSongCallback setCurrentSong;
    final SetLoopingCallback setIsLooping;
    final SetRandomCallback setIsRandom; 

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
        required this.getIsRandom,

        required this.setCurrentSong,
        required this.getCurrentSongList,
        required this.setIsLooping,
        required this.setIsRandom, 

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
            _positionController.add(p); // Broadcast
        });

        // Playlist logic 
        _playerCompleteSubscription = audioService.audioPlayer.onPlayerComplete.listen((_) {
            _handleSongCompletion();
        });

        // Listen to player state changes
        _playerStateSubscription = audioService.audioPlayer.onPlayerStateChanged.listen((state) {
            if (state == PlayerState.playing) {
                _songEnded = false; // Reset ended flag when playback starts
            }
        });
    }

    /// Set current song and broadcast to stream
    void _setCurrentSongAndBroadcast(Song? song) {
        setCurrentSong(song); 
        if (song != null) {
            _lastPlayedSong = song; // Track as last played
            _songEnded = false; // Reset ended flag
        }
        _currentSongController.add(song); // Broadcast
    }

    /// Cancel the audio stream subscriptions and set everything subscription to null.
    /// 
    /// This must be called in the parent's [dispose] function to avoid any left over audio when leave the current the tab.
    void cancelAudioStreams() {
        _onPositionSubscription?.cancel();
        _onDurationSubscription?.cancel();
        _playerCompleteSubscription?.cancel();
        _playerStateSubscription?.cancel();
        _currentSongController.close();
        _loopController.close();
        _positionController.close();
        
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
                _setCurrentSongAndBroadcast(playingSong);
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

    /// Go to the previous Song in the list, by index. 
    /// 
    /// Similar logic to advance to next song - just -1 instead of +1. 
    void gotoPreviousSong() async {
        final Song? currentSong = getCurrentSong();
        final List<Song> currentSongList = getCurrentSongList(); 

        if (currentSong == null) {
            if (currentSongList.isNotEmpty) {
                final firstSong = currentSongList.first;
                _setCurrentSongAndBroadcast(firstSong);
                audioService.playFile(firstSong.assetPath);
            } else {
                stop();
            }
            return;
        }

        final int currentSongIndex = currentSongList.indexOf(currentSong);
        final int previousIndex = (currentSongIndex - 1) % currentSongList.length;
        final Song previousSong = currentSongList[previousIndex];

        if (await SongRepository.isSongFileAvailable(previousSong.assetPath)){
            _setCurrentSongAndBroadcast(previousSong);
            audioService.playFile(previousSong.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${previousSong.title}'");
            stop();
            await reloadSongList(); 
        }
    }

    /// Go to the next Song in the list, by index. 
    /// 
    /// Similar logic to advance to next song. 
    void gotoNextSong() async {
        final Song? currentSong = getCurrentSong();
        final List<Song> currentSongList = getCurrentSongList(); 

        if (currentSong == null) {
            if (currentSongList.isNotEmpty) {
                final firstSong = currentSongList.first;
                _setCurrentSongAndBroadcast(firstSong);
                audioService.playFile(firstSong.assetPath);
            } else {
                stop();
            }
            return;
        }

        final int currentSongIndex = currentSongList.indexOf(currentSong);
        final int nextIndex = (currentSongIndex + 1) % currentSongList.length;
        final Song nextSong = currentSongList[nextIndex];

        if (await SongRepository.isSongFileAvailable(nextSong.assetPath)){
            _setCurrentSongAndBroadcast(nextSong);
            audioService.playFile(nextSong.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${nextSong.title}'");
            stop();
            await reloadSongList(); 
        }
    }

    /// Toggle looping behavior of the current Song List - User action dependent. 
    void toggleLoop() {
        final newLoopingState = !getIsLooping();
        setIsLooping(newLoopingState);
        _loopController.add(newLoopingState); // Notify listeners
        showMessage("Loop mode: ${newLoopingState ? "ON" : "OFF"}", duration: const Duration(seconds: 1));
    }

    /// Toggle random behavior of the current Song List
    void toggleRandom(){
        final newRandomState = !getIsRandom();
        setIsRandom(newRandomState);
        _randomController.add(newRandomState); // Notify listeners. 
        showMessage("Random mode: ${newRandomState ? "ON" : "OFF"}", duration: const Duration(seconds: 1));
    }

    /// Handles Play, Resume, and Pause based on the audio state - User action dependent. 
    void handlePlayResumePause() async {
        IO.t("Value of _songEnded = $_songEnded");
        
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
        
        IO.t("Audio service state: isPlaying=${audioService.isPlaying}, isPaused=${audioService.isPaused}");
        IO.t("Current song: ${getCurrentSong()?.title}");
        IO.t("Last played song: ${_lastPlayedSong?.title}");

        // Audio is stopped/ended, try to replay last played song
        if (_songEnded) {
            // Song has ended - replay from beginning
            Song? songToPlay = getCurrentSong() ?? _lastPlayedSong;
            // Removal of song that are no longer available. 
            if (songToPlay != null) {
                if (await SongRepository.isSongFileAvailable(songToPlay.assetPath)){
                    _songEnded = false;
                    _setCurrentSongAndBroadcast(songToPlay);
                    IO.d("Playing this path: ${songToPlay.assetPath}");
                    audioService.playFile(songToPlay.assetPath);                
                    return;
                } else {
                    showMessage("Error: Song file is missing or moved: '${songToPlay.title}'");
                    stop();
                    await reloadSongList(); 
                }
            }
        }

        // Fallback: Play the first song if nothing is playing/on pause. 
        final currentSongList = getCurrentSongList();
        if (getCurrentSong() == null && currentSongList.isNotEmpty) { 
            final firstSong = currentSongList.first;
            _setCurrentSongAndBroadcast(firstSong); 
            audioService.playFile(firstSong.assetPath);
        }
    }

    /// Play song when user clicks on it. 
    Future <void> playSelectedSong(Song song) async{
        if (await SongRepository.isSongFileAvailable(song.assetPath)) {
            _songEnded = false;
            _setCurrentSongAndBroadcast(song);
            audioService.playFile(song.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${song.title}'");
            stop();
            await reloadSongList(); 
        }
    }

    /// Stops playback and resets the UI state (song, duration, position) and broadtcast null. 
    void stop() {
        audioService.stop(); 
        resetPlaybackState(); 
        _lastPlayedSong = null; 
        _songEnded = false;
        _currentSongController.add(null); // Broadcast that no song is playing
    }
    
    /// Let user use the progress bar to control the Song. 
    /// 
    /// Remarks: If [_songEnded] = true and [getIsLooping] = false => seeking will automatically play the song.  
    void handleSeek(double value) async {
        final newPosition = Duration(milliseconds: value.round());

        // Changing position when song has not ended does not need the controlsManager to replay the song.
        if (!_songEnded){  
            audioService.seek(newPosition);
            setCurrentPosition(newPosition);        // Update slider.
            _positionController.add(newPosition);   // Broadcast.
            _songEnded = false;                     // Reset ended flag when user seeks.
            return;
        }

        // Otherwise, song ends, we should replay this song. 
        _songEnded = false;     // Reset ended flag when user seeks.
        playSelectedSong(getCurrentSong()!);  
        // 50 ms is the "safe" wait time, some of my devices work on 10ms, but just to make sure. 
        await Future.delayed(Duration(milliseconds: 50));
        handleSeek(value);
        setCurrentPosition(newPosition);        // Update slider. 
        _positionController.add(newPosition);   // Broadcast.
    }

    /// Opens the system file picker, filters for MP3, and adds selected songs to the masterList. 
    /// 
    /// Does not change any other storage file than the masterList.txt. Actual logic is delegated to [SongRepository].
    Future<void> handleAddSong() async {
        int songsAdded = await SongRepository.addSongsFromUserSelection(); 
        if (songsAdded > 0) {
            notifySongListChanged(); // Notify to rebuild UI.   
            showMessage("$songsAdded song(s) added!");
        } else {
            showMessage("No new songs selected.");
        }
    }

    /// If [getIsLooping] is false, stop the audio, revert to the start of current song. Otherwise find the next Song in the list. 
    /// 
    /// This is called internally by the song_controls_manager. 
    void _handleSongCompletion() async {
        IO.t("=== SONG COMPLETION HANDLER ===");
        IO.t("Loop mode: ${getIsLooping()}");
        IO.t("Current song: ${getCurrentSong()?.title}");

        // For non-looping + non-random mode:
        if (!getIsLooping() && !getIsRandom()) { 
            _backToStartIfNotLooping();
            return;
        }

        // Otherwise in loop mode or random mode => continue playing the next song. 
        _advanceToNextSongIfLooping();
    }

    /// If not in looping mode, let user play the current song again.  
    /// 
    /// Helper for _handleSongCompletion. 
    /// Revert the progress bar back to 0 but does NOT call stop.
    void _backToStartIfNotLooping() async {
        final currentSong = getCurrentSong();
        if (currentSong != null) {
            _lastPlayedSong = currentSong;
            _songEnded = true;
        }

        try {
            setCurrentPosition(Duration.zero);
            _positionController.add(Duration.zero); //broadcast
        } catch (e){
            IO.e("Error reverting to beginning after song completetion: ", error: e);
        }

        // Get the current duration from the service before resetting
        final currentDuration = await audioService.getCurrentDuration();
        if (currentDuration != null && currentDuration > Duration.zero) {
            setCurrentDuration(currentDuration);
        }
        
        return;
    }
    
    /// Select the next song in the list, based on the index. If at the end of the list, go to the 1st song. 
    ///
    /// Helper for _handleSongCompletion. 
    void _advanceToNextSongIfLooping() async {
        final Song? currentSong = getCurrentSong();
        final List<Song> currentSongList = getCurrentSongList(); 

        if (currentSong == null) {
            if (currentSongList.isNotEmpty) {
                final firstSong = currentSongList.first;
                _setCurrentSongAndBroadcast(firstSong);
                audioService.playFile(firstSong.assetPath);
            } else {
                stop();
            }
            return;
        }

        // Normal loop. 
        final int currentSongIndex = currentSongList.indexOf(currentSong);
        int nextIndex = (currentSongIndex + 1) % currentSongList.length;

        // Randomize loop naive implementation. 
        if (getIsRandom()){
            nextIndex = (currentSongIndex + Random().nextInt(currentSongList.length)) % currentSongList.length;
        }
        Song nextSong = currentSongList[nextIndex];
        
        if (await SongRepository.isSongFileAvailable(nextSong.assetPath)){
            _setCurrentSongAndBroadcast(nextSong);
            audioService.playFile(nextSong.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${nextSong.title}'");
            await reloadSongList();
            _handleSongCompletion(); 
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