import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import '../utilities/io_print.dart';

/// Responsible for playing of mp3 files. 
class AudioPlayerService {
    final AudioPlayer _audioPlayer = AudioPlayer();
    AudioPlayer get audioPlayer => _audioPlayer;

    // Custom stream controllers to handle completion properly.
    final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
    final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();

    /// Song total length. 
    Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
    /// Current time position. 
    Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;

    bool get isPlaying => _audioPlayer.state == PlayerState.playing;
    bool get isPaused => _audioPlayer.state == PlayerState.paused;

    // Variable to track the currently loaded file path.
    String? _currentFilePath; 
    String? get currentAssetPath => _currentFilePath;
    Future<Duration?> getCurrentPosition() async => _audioPlayer.getCurrentPosition();
    Future<Duration?> getCurrentDuration() async => _audioPlayer.getDuration();

    // Track subscription for cleanup. 
    StreamSubscription<Duration>? _playerPositionSubscription;
    StreamSubscription<Duration>? _playerDurationSubscription;
    StreamSubscription<void>? _playerCompleteSubscription;
    StreamSubscription<PlayerState>? _playerStateSubscription;

    AudioPlayerService() {
        _setupListeners();
    }

    /// Call this to play a new song from a local file path.
    /// 
    /// The caller must guarantee that said [filePath] is valid and exist. Otherwise throw exception. 
    Future<void> playFile(String filePath) async {
        try {
            await _audioPlayer.stop(); // Stop current before running new one. 
            await _audioPlayer.setSource(DeviceFileSource(filePath));
        } catch (e){
            IO.e("Some shutdown exception.", error: e);
        } finally {
            _currentFilePath = filePath; // Set current path when play. 
            await _audioPlayer.resume(); 
            _positionController.add(const Duration(milliseconds: 0)); // Notify UI to revert to 0. 
        }
    }

    Future<void> pause() async {
        await _audioPlayer.pause();
    }

    Future<void> resume()async {
        await _audioPlayer.resume();
    }

    Future<void> stop() async {
        await _audioPlayer.stop();
        _currentFilePath = null; // Clear current path when stop. 
        _positionController.add(const Duration(milliseconds: 0)); // Notify UI to revert to 0.
    }

    /// Jump to the time specified by the parameter position. 
    /// 
    /// Use try catch due to sometime (rare) there is a future timeout exception that I do not know how to reproduce.
    Future<void> seek(Duration position) async {
        try{
            await _audioPlayer.seek(position);
        } catch (e){
            IO.w("Seek timeout exception.", error: e);
        }
    }

    void dispose() {
        // Cancel all subscriptions
        _playerPositionSubscription?.cancel();
        _playerDurationSubscription?.cancel();
        _playerCompleteSubscription?.cancel();
        _playerStateSubscription?.cancel();
        // Close all controllers
        _durationController.close();
        _positionController.close();
        
        _audioPlayer.dispose();
    }

    void _setupListeners() {
        // Notify progress bar position changes. 
        _playerPositionSubscription = _audioPlayer.onPositionChanged.listen((position) {
            _positionController.add(position);
        });
        
        // Notify total duration changes.
        _playerDurationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
            _durationController.add(duration);
        });
        
        // Handle song completion
        _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
            _positionController.add(const Duration(milliseconds: 0)); // Notify UI to revert to 0. 
        });

        // Remarks: This being here to prevent a rare instance that the random mode plays a song, 
        // and said song cannot be control with the progress bar on the dock 
        // (but can still be contorlled using the progress bar in song detail page)
        // I currently have no clue why in some rare instance this behavior happen - just like the future not completed one. 
        _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
            if (state == PlayerState.completed || state == PlayerState.stopped) {
                // Add a small delay to ensure position stream has time to process
                Future.delayed(const Duration(milliseconds: 50), () {
                    if (!_positionController.isClosed) {
                        _positionController.add(const Duration(milliseconds: 0));
                    }
                });
            }
        });
    }
}