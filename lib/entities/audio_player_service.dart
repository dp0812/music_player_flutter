import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
    final AudioPlayer _audioPlayer = AudioPlayer();

    /// Call this to play a new song from a local file path, specify by the getApplicationDocumentsDirectory() function;
    /// On windows this would be: C:\Users\tomph\OneDrive\Documents\Music
    Future<void> playFile(String filePath) async {
        await _audioPlayer.stop(); //stop current before running new one. 
        await _audioPlayer.setSource(DeviceFileSource(filePath));
        await _audioPlayer.resume(); 
    }

    // Status update, based on external library audioplayers.dart
    bool get isPlaying => _audioPlayer.state == PlayerState.playing;
    bool get isPaused => _audioPlayer.state == PlayerState.paused;

    Future<void> pause() async {
        await _audioPlayer.pause();
    }

    Future<void> resume()async {
        await _audioPlayer.resume();
    }

    Future<void> stop() async {
        await _audioPlayer.stop();
    }

    void dispose() {
        _audioPlayer.dispose();
    }
}