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

    /// Call this to play a new song from a local file path, specify by the getApplicationDocumentsDirectory() function;
    /// On windows this would be: C:\Users\username\OneDrive\Documents
    Future<void> playFile(String filePath) async {
        await _audioPlayer.stop(); //stop current before running new one. 
        await _audioPlayer.setSource(DeviceFileSource(filePath));
        await _audioPlayer.resume(); 
    }

    Future<void> pause() async {
        await _audioPlayer.pause();
    }

    Future<void> resume()async {
        await _audioPlayer.resume();
    }

    Future<void> stop() async {
        await _audioPlayer.stop();
    }

    /// Jump to the time specified by the parameter position. 
    Future<void> seek(Duration position) async {
        await _audioPlayer.seek(position);
    }

    void dispose() {
        _audioPlayer.dispose();
    }
}