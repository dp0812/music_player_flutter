import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
    final AudioPlayer _audioPlayer = AudioPlayer();
    AudioPlayer get audioPlayer => _audioPlayer;
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

    /// Call this to play a new song from a local file path.
    /// 
    /// The caller must guarantee that said [filePath] is valid and exist - otherwise will throw exception. 
    Future<void> playFile(String filePath) async {
        await _audioPlayer.stop(); //stop current before running new one. 
        await _audioPlayer.setSource(DeviceFileSource(filePath));
        await _audioPlayer.resume(); 
        _currentFilePath = filePath; //set current path when play. 
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
    }

    /// Jump to the time specified by the parameter position. 
    Future<void> seek(Duration position) async {
        await _audioPlayer.seek(position);
    }

    void dispose() {
        _audioPlayer.dispose();
    }
}