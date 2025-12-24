import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'audio_player_service.dart';
import 'song.dart';
import 'song_repository.dart';
import '../entities/song_playlist.dart';
import '../utilities/io_print.dart';

// Define interfaces for clarity purpose. 
typedef SetSongCallback = void Function(Song? song);
typedef SetLoopingCallback = void Function(bool isLooping);
typedef SetRandomCallback = void Function(bool isRandom);
typedef SetPositionCallback = void Function(Duration position);
typedef SetDurationCallback = void Function(Duration duration); 
typedef ResetStateCallback = void Function();
typedef AddSongCallback = void Function();

/// This class provides service for pause, resume, stop, loop and progress bar information for songs. 
/// 
/// Client of this class must call [cancelAudioStreams] in their dispose function to ensure the audio is correctly stopped. 
class SongControlsManager {
    /// Interface for interacting with mp3 files (play, pause, resume...).
    final AudioPlayerService audioService;
    final BuildContext context;

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

    // Track which list is currently active for playback - There can only be 1.  
    static final SongsPlaylist _activeSongsPlaylist = SongsPlaylist(); 
    static SongsPlaylist getActivePlaylist() => _activeSongsPlaylist;
    
    // Read the current state from the parent.
    final Song? Function() getCurrentSong;
    final bool Function() getIsLooping;
    final bool Function() getIsRandom; 

    // Write new state and trigger rebuilds on the parent.
    final SetSongCallback setCurrentSong;
    final SetLoopingCallback setIsLooping;
    final SetRandomCallback setIsRandom; 

    final ResetStateCallback resetPlaybackState;
    final SetPositionCallback setCurrentPosition;
    final SetDurationCallback setCurrentDuration; 
    final AddSongCallback notifySongListChanged;
    
    SongControlsManager({
        required this.audioService,
        required this.context,
        required this.getCurrentSong,
        required this.getIsLooping,
        required this.getIsRandom,
        required this.setCurrentSong,
        required this.setIsLooping,
        required this.setIsRandom, 
        required this.resetPlaybackState,
        required this.setCurrentPosition,
        required this.setCurrentDuration, 
        required this.notifySongListChanged,
    }) {
        // Initialize stream listeners and store the subscriptions
        _onDurationSubscription = audioService.onDurationChanged.listen((d) {
            setCurrentDuration(d);
        });
        
        _onPositionSubscription = audioService.onPositionChanged.listen((p) {
            setCurrentPosition(p);
            _positionController.add(p); // Broadcast
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

    /// Get the current active song list.
    /// 
    /// This persists during navigation, and is only changed when user tap to play a NEW song on some list view.  
    List<Song> _getActiveSongList() {
        // If no active list is set => use master list as fallback
        if (_activeSongsPlaylist.getCurrentPlaylistSongs().isEmpty) {
            _activeSongsPlaylist.playlistName = SongRepository.masterSongPlaylist.playlistName;
            return SongRepository.masterSongPlaylist.getCurrentPlaylistSongs();
        }
        return _activeSongsPlaylist.getCurrentPlaylistSongs();
    }

    /// Cancel the audio stream subscriptions and set everything subscription to null.
    /// 
    /// This must be called in the parent's [dispose] function to avoid any left over audio when leave the current the tab.
    void cancelAudioStreams() {
        _onPositionSubscription?.cancel();
        _onDurationSubscription?.cancel();
        _playerStateSubscription?.cancel();
        _currentSongController.close();
        _loopController.close();
        _positionController.close();
        _randomController.close();
        
        // Reset all subscriptions to null
        _onPositionSubscription = null;
        _onDurationSubscription = null;
        _playerStateSubscription = null;
    }

    /// Correctly update the current duration and position for a song, when switching between different pages. 
    /// 
    /// This function is called to make sure there is no left over audio while the progress bar is empty.
    Future<void> synchronizePlaybackState(SongsPlaylist currentPageList) async {
        // Lưu trước khi đổi. Khúc này quằn vcl. 
        try {
            final currentAssetPath = audioService.currentAssetPath; 
            
            if (currentAssetPath != null) {
                // Is song in the page's list?
                Song? playingSongInPage;
                for (Song song in currentPageList.getCurrentPlaylistSongs()) {
                    if (song.assetPath == currentAssetPath) {
                        playingSongInPage = song;
                        break;
                    }
                }

                if (playingSongInPage != null) {
                    // Update UI but DO NOT change active list.
                    _setCurrentSongAndBroadcast(playingSongInPage);
                    final position = await audioService.getCurrentPosition() ?? Duration.zero;
                    final duration = await audioService.getCurrentDuration() ?? Duration.zero;
                    setCurrentPosition(position); 
                    setCurrentDuration(duration);
                } else { // Song is playing (perhaps) but not in currentPageList.
                    // Find it in the active list.
                    Song? playingSongInActiveList;
                    for (Song song in _activeSongsPlaylist.getCurrentPlaylistSongs()) {
                        if (song.assetPath == currentAssetPath) {
                            playingSongInActiveList = song;
                            break;
                        }
                    }
                    // Show the playing song from active list if found.
                    if (playingSongInActiveList != null) {
                        _setCurrentSongAndBroadcast(playingSongInActiveList);
                        final position = await audioService.getCurrentPosition() ?? Duration.zero;
                        final duration = await audioService.getCurrentDuration() ?? Duration.zero;
                        setCurrentPosition(position); 
                        setCurrentDuration(duration);
                    } else {
                        // Song not found anywhere - pull the progress bar to 0.
                        setCurrentSong(null);
                        setCurrentPosition(Duration.zero);
                        setCurrentDuration(Duration.zero);
                    }
                }
            } else {
                // No song is playing - pull the progress bar to 0.
                setCurrentSong(null);
                setCurrentPosition(Duration.zero);
                setCurrentDuration(Duration.zero);
            }
        } catch (e) {
            IO.e("Error synchronizing playback state: ", error: e);
        }
    }

    /// Go to the previous Song in the active list. 
    void gotoPreviousSong() async {
        final currentSongList = _getActiveSongList();
        final Song? currentSong = getCurrentSong();

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

        final int currentSongIndex = currentSongList.indexWhere((song) => song.assetPath == currentSong.assetPath);
        final int previousIndex = (currentSongIndex - 1) % currentSongList.length;
        final Song previousSong = currentSongList[previousIndex];

        if (await SongRepository.isSongFileAvailable(previousSong.assetPath)){
            _setCurrentSongAndBroadcast(previousSong);
            audioService.playFile(previousSong.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${previousSong.title}'", isWarning: true);
            stop();
        }
    }

    /// Go to the next Song in the active list. 
    void gotoNextSong() async {
        final currentSongList = _getActiveSongList();
        final Song? currentSong = getCurrentSong();

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

        final int currentSongIndex = currentSongList.indexWhere((song) => song.assetPath == currentSong.assetPath);
        final int nextIndex = (currentSongIndex + 1) % currentSongList.length;
        final Song nextSong = currentSongList[nextIndex];

        if (await SongRepository.isSongFileAvailable(nextSong.assetPath)){
            _setCurrentSongAndBroadcast(nextSong);
            audioService.playFile(nextSong.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${nextSong.title}'", isWarning: true);
            stop();
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
        final currentSongList = _getActiveSongList();
        IO.t("Active list name: ${_activeSongsPlaylist.playlistName}, songs: ${currentSongList.length}");
        
        // Check if a song is playing that's NOT in the active list
        final currentAssetPath = audioService.currentAssetPath;
        if (currentAssetPath != null && _activeSongsPlaylist.getCurrentPlaylistSongs().isNotEmpty) {
            bool isPlayingSongInActiveList = _activeSongsPlaylist.getCurrentPlaylistSongs()
                .any((song) => song.assetPath == currentAssetPath);
            
            if (!isPlayingSongInActiveList) {
                // Stop the old song that's not in the active list
                audioService.stop();
                _songEnded = false;
                // Reset UI state
                setCurrentSong(null);
                setCurrentPosition(Duration.zero);
                setCurrentDuration(Duration.zero);
            }
        }
        
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
                    showMessage("Error: Song file is missing or moved: '${songToPlay.title}'", isWarning: true);
                    stop();
                }
            }
        }

        // Fallback: Play the first song if nothing is playing/on pause. 
        if (getCurrentSong() == null && currentSongList.isNotEmpty) { 
            final firstSong = currentSongList.first;
            _setCurrentSongAndBroadcast(firstSong); 
            audioService.playFile(firstSong.assetPath);
        }
    }

    /// Play song when user clicks on it. This sets the [currentSongsPlaylist] as the active playlist.
    /// 
    /// [context] is only use for debug printing. 
    Future<void> playSelectedSong(Song song, SongsPlaylist currentSongsPlaylist, {String context = "unknown"}) async{
        // Create a copy - do NOT swap the identity. 
        _activeSongsPlaylist.replaceSongs(currentSongsPlaylist.getCurrentPlaylistSongs());
        _activeSongsPlaylist.playlistName = currentSongsPlaylist.playlistName;

        // _activeListContext = context;
        
        if (await SongRepository.isSongFileAvailable(song.assetPath)) {
            _songEnded = false;
            _setCurrentSongAndBroadcast(song);
            audioService.playFile(song.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${song.title}'", isWarning: true);
            stop();

        }
    }

    /// Play song using existing active list (for internal use)
    Future<void> _playSongInActiveList(Song song) async{
        if (await SongRepository.isSongFileAvailable(song.assetPath)) {
            _songEnded = false;
            _setCurrentSongAndBroadcast(song);
            audioService.playFile(song.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${song.title}'", isWarning: true);
            stop();
        }
    }

    /// Stops playback and resets the UI state (song, duration, position) and broadcast null. 
    void stop() async {
        audioService.stop(); 
        // Reset progress bar before other operations
        setCurrentPosition(Duration.zero);
        setCurrentDuration(Duration.zero);
        _positionController.add(Duration.zero);
        // Reload the master list will remove invalid file from the list. 
        await SongRepository.loadSongs();      
        await SongRepository.loadPlaylists();   
        resetPlaybackState(); 
        _lastPlayedSong = null; 
        _songEnded = false;
        _activeSongsPlaylist.clearSongs();
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
            _positionController.add(newPosition);   // Notify listener to refresh.
            _songEnded = false;                     // Reset ended flag when user seeks.
            return;
        }

        // Otherwise, song ends, we should replay this song. 
        _songEnded = false;     // Reset ended flag when user seeks.
        
        final currentSong = getCurrentSong();
        if (currentSong != null) {
            await _playSongInActiveList(currentSong);  
            // 50 ms is the "safe" wait time, some of my devices work on 10ms, but just to make sure. 
            await Future.delayed(Duration(milliseconds: 50));
            audioService.seek(newPosition);
            setCurrentPosition(newPosition);        // Update slider. 
            _positionController.add(newPosition);   // Notify listener to refresh.
        }
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

    /// Opens the system file picker and let user select 1 directory. Adds all songs from this directory to the masterList. 
    /// 
    /// Does not change any other storage file than the masterList.txt. Actual logic is delegated to [SongRepository].
    Future<void> handleAddMusicDirectory() async {
        int songsAdded = await SongRepository.fetchSongsFromUserDirectory(); 
        if (songsAdded > 0) {
            notifySongListChanged(); // Notify to rebuild UI.   
            showMessage("$songsAdded song(s) added!");
        } else {
            showMessage("No new songs selected.");
        }
    }

    /// If [getIsLooping] is false, stop the audio, revert to the start of current song. Otherwise find the next Song in the list. 
    void handleSongCompletion() async {
        final currentSongList = _getActiveSongList();
        IO.t("=== SONG COMPLETION HANDLER ===");
        IO.t("Active list: ${_activeSongsPlaylist.playlistName} (${currentSongList.length} songs)");

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
    /// Helper for handleSongCompletion. 
    /// Revert the progress bar back to 0 but does NOT call stop.
    void _backToStartIfNotLooping() async {
        final currentSong = getCurrentSong();
        if (currentSong != null) {
            _lastPlayedSong = currentSong;
            _songEnded = true;
        }

        try {
            setCurrentPosition(Duration.zero);
            _positionController.add(Duration.zero); // Notify listener to refresh.
        } catch (e){
            IO.e("Error reverting to beginning after song completetion: ", error: e);
        }

        // Get the current duration from the service before resetting
        final currentDuration = await audioService.getCurrentDuration();
        if (currentDuration != null && currentDuration > Duration.zero) {
            setCurrentDuration(currentDuration);
        }
    }
    
    /// Select the next song in the active list, based on the index. If at the end of the list, go to the 1st song. 
    ///
    /// Helper for handleSongCompletion. 
    void _advanceToNextSongIfLooping() async {
        final currentSongList = _getActiveSongList(); // this info is already without the defective songs. 
        final Song? currentSong = getCurrentSong();

        // Reset progress bar immediately before checking next song
        setCurrentPosition(Duration.zero);
        _positionController.add(Duration.zero);
        // Refresh UI 
        setIsLooping(getIsLooping());

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
        final int currentSongIndex = currentSongList.indexWhere((song) => song.assetPath == currentSong.assetPath);
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
            showMessage("Error: Song file is missing or moved: '${nextSong.title}'", isWarning: true);
            stop();
        }
    }

    /// Helper to display snackbar message with a preset duration. 
    void showMessage(String message, {Duration duration = const Duration(seconds: 2), bool isWarning = false}){
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    message,
                    style: TextStyle(
                        color: isWarning ? Colors.red.shade600 : Colors.grey.shade800,
                        fontWeight: isWarning ? FontWeight.bold : FontWeight.normal
                    )
                ), 
                duration: duration, 
            ),
        );
    }
}