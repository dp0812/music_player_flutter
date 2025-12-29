import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import '../utilities/io_print.dart';

/// Responsible for playing of mp3 files. 
/// 
/// This class is a thin wrapper for [audioplayers], with some function to track the [_currentFilePath] loaded.
/// No more nasty stream problems and setUpListeners inconsistency.   
class AudioPlayerService {
    final AudioPlayer _audioPlayer = AudioPlayer();
    AudioPlayer get audioPlayer => _audioPlayer;

    /// Song total length. 
    Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
    /// Current time position. 
    Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;

    bool get isPlaying => _audioPlayer.state == PlayerState.playing;
    bool get isPaused => _audioPlayer.state == PlayerState.paused;

    /// Track the currently loaded file path.
    String? _currentFilePath; 
    String? get currentAssetPath => _currentFilePath;
    Future<Duration?> getCurrentPosition() async => _audioPlayer.getCurrentPosition();
    Future<Duration?> getCurrentDuration() async => _audioPlayer.getDuration();

    AudioPlayerService();

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
    }

    /// Jump to the time specified by the parameter position. 
    /// 
    /// Remarks: Future timeout exception happen when user seek but current song is null.
    Future<void> seek(Duration position) async {
        try{
            await _audioPlayer.seek(position);
        } catch (e){
            IO.w("Seek timeout exception.", error: e);
        }
    }

    void dispose() {
        _audioPlayer.dispose();
    }
}