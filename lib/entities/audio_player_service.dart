import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
    final AudioPlayer _audioPlayer = AudioPlayer();
    AudioPlayer get audioPlayer => _audioPlayer;

    // Custom stream controllers to handle completion properly
    final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
    final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();

    ///Song total length. 
    Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
    ///Current time position. 
    Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;

    bool get isPlaying => _audioPlayer.state == PlayerState.playing;
    bool get isPaused => _audioPlayer.state == PlayerState.paused;

    // Variable to track the currently loaded file path.
    String? _currentFilePath; 
    String? get currentAssetPath => _currentFilePath;
    Future<Duration?> getCurrentPosition() async => _audioPlayer.getCurrentPosition();
    Future<Duration?> getCurrentDuration() async => _audioPlayer.getDuration();

    // Track subscription for cleanup
    StreamSubscription<Duration>? _playerPositionSubscription;
    StreamSubscription<Duration>? _playerDurationSubscription;
    StreamSubscription<void>? _playerCompleteSubscription;
    StreamSubscription<PlayerState>? _playerStateSubscription;

    AudioPlayerService() {
        _setupListeners();
    }

    /// Call this to play a new song from a local file path.
    /// 
    /// The caller must guarantee that said [filePath] is valid and exist - otherwise will throw exception. 
    Future<void> playFile(String filePath) async {
        await _audioPlayer.stop(); //stop current before running new one. 
        await _audioPlayer.setSource(DeviceFileSource(filePath));
        await _audioPlayer.resume(); 
        _currentFilePath = filePath; //set current path when play. 

        // Emit zero position when starting new song
        // This ensures UI resets if previous song was at the end
        _positionController.add(const Duration(milliseconds: 0));
    }

    Future<void> pause() async {
        await _audioPlayer.pause();
    }

    Future<void> resume()async {
        await _audioPlayer.resume();
    }

    Future<void> stop() async {
        await _audioPlayer.stop();
        _currentFilePath = null; //clear current path when stop. 
        _positionController.add(const Duration(milliseconds: 0)); // Emit zero position when stopping
    }

    /// Jump to the time specified by the parameter position. 
    Future<void> seek(Duration position) async {
        await _audioPlayer.seek(position);
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
        // Forward position updates from audio player
        _playerPositionSubscription = _audioPlayer.onPositionChanged.listen((position) {
            _positionController.add(position);
        });
        
        // Forward duration updates from audio player
        _playerDurationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
            _durationController.add(duration);
        });
        
        // Handle song completion
        _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
            // When song completes, emit the final position then zero
            // This ensures UI knows the song ended and position reset
            _positionController.add(const Duration(milliseconds: 0));
        });
        
        // Also listen to state changes for more reliable completion detection
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