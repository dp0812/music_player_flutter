import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'audio_player_service.dart';
import 'song.dart';
import 'song_repository.dart';
import '../entities/song_playlist.dart';
import '../utilities/io_print.dart';

/// This class provides service for pause, resume, stop, loop and progress bar information for songs. 
/// 
/// Client of this class must call [cancelAudioStreams] in their dispose function to ensure the audio is correctly stopped. 
/// Remarks: 
/// 1. The only current client that call [cancelAudioStreams] is the one that created the [SongControlsManager] - our [WelcomePageState]. 
/// 2. This class contains all streams needed. User of the [SongControlsManager] should access the public getters of this class, and not opening another stream.   
class SongControlsManager extends ChangeNotifier {
    /// There exists exactly ONE [_activeSongsPlaylist] at any given time.
    static SongsPlaylist get activeSongsPlaylist => _activeSongsPlaylist;
    static final SongsPlaylist _activeSongsPlaylist = SongsPlaylist();

    /// Interface for interacting with mp3 files (play, pause, resume...).
    final AudioPlayerService audioService;
    final BuildContext context;
    
    Song? _currentSong;
    bool _isLooping = false;
    bool _isRandom = false;
    Duration _currentDuration = Duration.zero;
    Duration _currentPosition = Duration.zero;
    bool _songEnded = false;
    Song? _lastPlayedSong;
    
    // Public getters (replacement for stream in clients). 
    Song? get currentSong => _currentSong;
    bool get isLooping => _isLooping;
    bool get isRandom => _isRandom;
    Duration get currentDuration => _currentDuration;
    Duration get currentPosition => _currentPosition;
    bool get songEnded => _songEnded;

    // All the streams, at a single place. 
    StreamSubscription<Duration>? _onPositionSubscription;
    StreamSubscription<Duration>? _onDurationSubscription;
    StreamSubscription<PlayerState>? _playerStateSubscription;
    StreamSubscription<void>? _playerCompleteSubscription;
    
    SongControlsManager({
        required this.audioService,
        required this.context,
    }) {
        // Set this listener up once, and exactly once. 
        _setupAudioListeners();
    }

    /// Go to the previous Song in the active list. 
    void gotoPreviousSong() async {
        final currentSongList = _getActiveSongList();
        final Song? currentSong = _currentSong; 

        if (currentSong == null) {
            if (currentSongList.isNotEmpty) {
                final firstSong = currentSongList.first;
                _setCurrentSong(firstSong);
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
            _setCurrentSong(previousSong);
            audioService.playFile(previousSong.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${previousSong.title}'", isWarning: true);
            stop();
        }
    }

    /// Go to the next Song in the active list. 
    void gotoNextSong() async {
        final currentSongList = _getActiveSongList();
        final Song? currentSong = _currentSong; 

        if (currentSong == null) {
            if (currentSongList.isNotEmpty) {
                final firstSong = currentSongList.first;
                _setCurrentSong(firstSong);
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
            _setCurrentSong(nextSong);
            audioService.playFile(nextSong.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${nextSong.title}'", isWarning: true);
            stop();
        }
    }

    /// Handles Play, Resume, and Pause based on the audio state. 
    void handlePlayResumePause() async {
        final currentSongList = _getActiveSongList();
        IO.t("Active list name: ${_activeSongsPlaylist.playlistName}, songs: ${currentSongList.length}");
        
        // Check if a song is playing that's NOT in the active list.
        final currentAssetPath = audioService.currentAssetPath;
        if (currentAssetPath != null && _activeSongsPlaylist.getCurrentPlaylistSongs().isNotEmpty) {
            bool isPlayingSongInActiveList = _activeSongsPlaylist.getCurrentPlaylistSongs()
                .any((song) => song.assetPath == currentAssetPath);
            
            if (!isPlayingSongInActiveList) {
                // Stop the old song that's not in the active list.
                audioService.stop();
                _songEnded = false;
                // Reset UI.
                _currentSong = null;
                _currentPosition = Duration.zero;
                _currentDuration = Duration.zero;
                notifyListeners();
            }
        }
        
        if (audioService.isPlaying) {
            audioService.pause();
            notifyListeners();
            return;
        }
        if (audioService.isPaused) {
            audioService.resume();
            notifyListeners();
            return;
        }
        
        IO.t("Audio service state: isPlaying=${audioService.isPlaying}, isPaused=${audioService.isPaused}");
        IO.t("Current song: ${_currentSong?.title}"); 
        IO.t("Last played song: ${_lastPlayedSong?.title}");

        // Audio is stopped/ended => replay last played song.
        if (_songEnded) {
            // Song ended => replay from beginning.
            Song? songToPlay = _currentSong ?? _lastPlayedSong;  
            // Removal of song(s) that are no longer available. 
            if (songToPlay != null) {
                if (await SongRepository.isSongFileAvailable(songToPlay.assetPath)){
                    _songEnded = false;
                    _setCurrentSong(songToPlay);
                    IO.d("Playing this path: ${songToPlay.assetPath}");
                    audioService.playFile(songToPlay.assetPath);                
                    return;
                } else {
                    showMessage("Error: Song file is missing or moved: '${songToPlay.title}'", isWarning: true);
                    stop();
                }
            }
        }

        // Play the first song of the master list if nothing is playing/on pause. 
        if ( _currentSong == null && currentSongList.isNotEmpty) {  
            _songEnded = false;
            final firstSong = currentSongList.first;
            _activeSongsPlaylist.replaceSongs(SongRepository.masterSongPlaylist.getCurrentPlaylistSongs());
            _activeSongsPlaylist.playlistName = SongRepository.masterSongPlaylist.playlistName; 
            IO.d("Default to: ${activeSongsPlaylist.playlistName}");
            _setCurrentSong(firstSong);
            audioService.playFile(firstSong.assetPath);
        }
    }

    /// Play song when user clicks on it. This sets the [currentSongsPlaylist] as the active playlist.
    Future<void> playSelectedSong(Song song, SongsPlaylist currentSongsPlaylist) async{
        // Create a copy. Do NOT swap the identity. 
        _activeSongsPlaylist.replaceSongs(currentSongsPlaylist.getCurrentPlaylistSongs());
        _activeSongsPlaylist.playlistName = currentSongsPlaylist.playlistName;
        
        if (await SongRepository.isSongFileAvailable(song.assetPath)) {
            _songEnded = false;
            _setCurrentSong(song);
            audioService.playFile(song.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${song.title}'", isWarning: true);
            stop();
        }
    }

    /// Stop song, reset the UI state and reload data from [SongRepository]. Then notify all listeners.  
    void stop() async {
        audioService.stop(); 
        // Reset progress bar before other operations. 
        _currentPosition = Duration.zero;
        _currentDuration = Duration.zero; 
        // Reload the master list will remove invalid file from the list. 
        await SongRepository.loadSongs();      
        await SongRepository.loadPlaylists();   
        _lastPlayedSong = null; 
        _songEnded = false;
        _activeSongsPlaylist.clearSongs();
        notifyListeners();
    }
    
    /// Let user use the progress bar to control the Song. 
    /// 
    /// Remarks: If [_songEnded] = true and [getIsLooping] = false => seeking will automatically play the song.  
    void handleSeek(double value) async {
        final newPosition = Duration(milliseconds: value.round());

        // Changing position when song has not ended does not need the controlsManager to replay the song.
        if (!_songEnded){  
            audioService.seek(newPosition);
            _currentPosition = newPosition;         // Update slider.
            _songEnded = false;                     // Reset ended flag when user seeks.
            return;
        }

        // Otherwise, song ends, we should replay this song. 
        _songEnded = false;     // Reset ended flag when user seeks.
        
        final currentSong = _currentSong;  
        if (currentSong != null) {
            await _playSongInActiveList(currentSong);  
            // 50 ms is the "safe" wait time, some of my devices work on 10ms, but just to make sure. 
            await Future.delayed(Duration(milliseconds: 50));
            audioService.seek(newPosition);
            _currentPosition = newPosition;         // Update slider. 
        }
    }

    /// Toogle loop using setter that notify listener. 
    void toggleLoop() {
        setLooping(!_isLooping);
        showMessage("Loop mode: ${_isLooping ? "ON" : "OFF"}", duration: const Duration(seconds: 1));
    }

    /// Toogle random using setter that notify listener. 
    void toggleRandom() {
        setRandom(!_isRandom);
        showMessage("Random mode: ${_isRandom ? "ON" : "OFF"}", duration: const Duration(seconds: 1));
    }

    /// If [getIsLooping] is false, stop the audio, revert to the start of current song. Otherwise find the next Song in the list. 
    void handleSongCompletion() async {
        final currentSongList = _getActiveSongList();
        IO.t("=== SONG COMPLETION HANDLER ===");
        IO.t("Active list: ${_activeSongsPlaylist.playlistName} (${currentSongList.length} songs)");

        // For non-looping + non-random mode:
        if (!_isLooping && !_isRandom) {
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
        final currentSong = _currentSong;  
        if (currentSong != null) {
            _lastPlayedSong = currentSong;
            _songEnded = true;
        }

        try {
            _currentPosition = Duration.zero; 
            notifyListeners();
        } catch (e){
            IO.e("Error reverting to beginning after song completetion: ", error: e);
        }

        // Get the current duration from the service before resetting.
        final currentDuration = await audioService.getCurrentDuration();
        if (currentDuration != null && currentDuration > Duration.zero) {
            _currentDuration = currentDuration;
        }
    }
    
    /// Select the next song in the active list, based on the index. If at the end of the list, go to the 1st song. 
    ///
    /// Helper for handleSongCompletion. 
    void _advanceToNextSongIfLooping() async {
        final currentSongList = _getActiveSongList(); // This info is already without the defective songs. 
        final Song? currentSong = _currentSong; 

        // Reset progress bar immediately before checking next song
        _currentPosition = Duration.zero; 
        // Refresh UI 
        notifyListeners();
        if (currentSong == null) { // Use first song if not found. 
            if (currentSongList.isNotEmpty) {
                final firstSong = currentSongList.first;
                _setCurrentSong(firstSong);
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
        if (_isRandom){ 
            nextIndex = (currentSongIndex + Random().nextInt(currentSongList.length)) % currentSongList.length;
        }
        Song nextSong = currentSongList[nextIndex];
        
        if (await SongRepository.isSongFileAvailable(nextSong.assetPath)){
            _setCurrentSong(nextSong);
            audioService.playFile(nextSong.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${nextSong.title}'", isWarning: true);
            stop();
        }
    }

    /// Opens the system file picker, filters for MP3, and adds selected songs to the masterList. 
    /// 
    /// This method notify all listeners. 
    /// Does not change any other storage file than the masterList.txt. Actual logic is delegated to [SongRepository].
    Future<void> handleAddSong() async {
        int songsAdded = await SongRepository.addSongsFromUserSelection(); 
        if (songsAdded > 0) {
            notifyListeners();
            showMessage("$songsAdded song(s) added!");
        } else {
            showMessage("No new songs selected.");
        }
    }

    /// Opens the system file picker and let user select 1 directory. Adds all songs from this directory to the masterList. 
    /// 
    /// This method notify all listeners.
    /// Does not change any other storage file than the masterList.txt. Actual logic is delegated to [SongRepository].
    Future<void> handleAddMusicDirectory() async {
        int songsAdded = await SongRepository.fetchSongsFromUserDirectory(); 
        if (songsAdded > 0) {
            notifyListeners();
            showMessage("$songsAdded song(s) added!");
        } else {
            showMessage("No new songs selected.");
        }
    }

    /// Get the current active song list. If active list playlist has no song, use the [masterSongPlaylist].
    /// 
    /// This persists during navigation, and is only changed when user tap to play a NEW song on some list view.  
    List<Song> _getActiveSongList() {
        // If no active list is set => use master list as fallback
        if (_activeSongsPlaylist.getCurrentPlaylistSongs().isEmpty) {
            // Set the name, so that we hightlight the correct song. 
            _activeSongsPlaylist.playlistName = SongRepository.masterSongPlaylist.playlistName;
            return SongRepository.masterSongPlaylist.getCurrentPlaylistSongs();
        }
        return _activeSongsPlaylist.getCurrentPlaylistSongs();
    }

    /// Play song using existing active list (for internal use).
    Future<void> _playSongInActiveList(Song song) async{
        if (await SongRepository.isSongFileAvailable(song.assetPath)) {
            _songEnded = false;
            _setCurrentSong(song);
            audioService.playFile(song.assetPath);
        } else {
            showMessage("Error: Song file is missing or moved: '${song.title}'", isWarning: true);
            stop();
        }
    }

    /// Set loop mode and notify listener. 
    void setLooping(bool looping) {
        _isLooping = looping;
        notifyListeners();
    }
    /// Set random mode and notify listener. 
    void setRandom(bool random) {
        _isRandom = random;
        notifyListeners();
    }

    /// Set current song and notify listeners
    void _setCurrentSong(Song? song) {
        _currentSong = song;
        if (song != null) {
            _lastPlayedSong = song;
            _songEnded = false;
        }
        notifyListeners();
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
                    _setCurrentSong(playingSongInPage);
                    final position = await audioService.getCurrentPosition() ?? Duration.zero;
                    final duration = await audioService.getCurrentDuration() ?? Duration.zero;
                    _currentPosition = position;
                    _currentDuration = duration;
                    notifyListeners();
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
                        _setCurrentSong(playingSongInActiveList);
                        final position = await audioService.getCurrentPosition() ?? Duration.zero;
                        final duration = await audioService.getCurrentDuration() ?? Duration.zero;
                        _currentPosition = position;
                        _currentDuration = duration;
                        notifyListeners();
                    } else {
                        // Song not found anywhere - pull the progress bar to 0.
                        _currentSong = null;
                        _currentPosition = Duration.zero;
                        _currentDuration = Duration.zero;
                        notifyListeners();
                    }
                }
            } else {
                // No song is playing - pull the progress bar to 0.
                _currentSong = null;
                _currentPosition = Duration.zero;
                _currentDuration = Duration.zero;
                notifyListeners();
            }
        } catch (e) {
            IO.e("Error synchronizing playback state: ", error: e);
        }
    }

    /// This will be the only time you see the listeners getting set up.
    void _setupAudioListeners() {
        // Listen to duration changes and notify UI. 
        _onDurationSubscription = audioService.onDurationChanged.listen((duration) {
            _currentDuration = duration;
            notifyListeners();
        });
        
        // Listen to position changes and notify UI. 
        _onPositionSubscription = audioService.onPositionChanged.listen((position) {
            _currentPosition = position;
            notifyListeners();
        });

        // Listen to player state changes and notify UI. 
        _playerStateSubscription = audioService.audioPlayer.onPlayerStateChanged.listen((state) {
            if (state == PlayerState.playing) {
                _songEnded = false;
                notifyListeners();
            }
        });

        // Listen to player completion and notify UI. 
        _playerCompleteSubscription = audioService.audioPlayer.onPlayerComplete.listen((_) {
            handleSongCompletion();
        });
    }

    /// Cancel the audio stream subscriptions and set every subscription to null.
    /// 
    /// This must be called in the parent's [dispose] function to avoid any left over audio when leave the current the tab.
    void cancelAudioStreamsAndSubscriptions() {
        _onPositionSubscription?.cancel();
        _onDurationSubscription?.cancel();
        _playerStateSubscription?.cancel();
        _playerCompleteSubscription?.cancel();
        _onPositionSubscription = null;
        _onDurationSubscription = null;
        _playerStateSubscription = null;
        _playerCompleteSubscription = null;  
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