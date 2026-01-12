import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'album_art_helper.dart';
import 'audio_player_service.dart';
import 'song.dart';

/// This handler track the song service, and add the song metadata (including the picture) to the app notification. 
/// 
/// Remarks: This handler use the implementation provided by [SongControlsManager] for each playback control, except for the stop function. 
/// The [stop] function is intended to shut down the app and delete temporary files.  
class CustomAudioHandler extends BaseAudioHandler with SeekHandler {
    final AudioPlayerService _service;
    VoidCallback onSkipNext;
    VoidCallback onSkipPrev;
    VoidCallback onPlayPauseResume;
    VoidCallback onStop; 
    Function(Duration) onSeek;

    CustomAudioHandler(this._service, { 
        required this.onSkipPrev, 
        required this.onPlayPauseResume, 
        required this.onSkipNext, 
        required this.onSeek,
        required this.onStop,
    }) {

        _service.onPositionChanged.listen((pos) {
            playbackState.add(
                playbackState.value.copyWith(
                    updatePosition: pos, 
                    speed: _service.isPlaying ? 1.0 : 0.0,
                )
            );
        });

        _service.onDurationChanged.listen((dur) {
            if (mediaItem.value != null) {
                mediaItem.add(mediaItem.value!.copyWith(duration: dur));
            }
        });

        _service.audioPlayer.onPlayerStateChanged.listen((state) {
            final playing = (state == PlayerState.playing);
            /// Send this to the notification. 
            playbackState.add(
                playbackState.value.copyWith(
                    playing: playing,
                    controls: [
                        MediaControl.skipToPrevious,
                        playing ? MediaControl.pause : MediaControl.play,
                        MediaControl.skipToNext,
                        MediaControl.stop,
                    ],
                    androidCompactActionIndices: const [0, 1, 2], 
                    systemActions: {
                        MediaAction.seek,
                        MediaAction.seekForward,
                        MediaAction.seekBackward,
                        MediaAction.skipToNext,
                        MediaAction.skipToPrevious,
                    },

                    updatePosition: playbackState.value.position,
                    speed: playing ? 1.0 : 0.0,
                    processingState: AudioProcessingState.ready, 
                )
            );
        });

        _service.audioPlayer.onPlayerComplete.listen((_) {
            playbackState.add(
                playbackState.value.copyWith(
                    processingState: AudioProcessingState.completed,
                    updatePosition: Duration.zero, // Reset position for next song.
                )
            );
        });
    }

    @override
    Future<void> skipToPrevious() async => onSkipPrev();
    @override
    Future<void> play() async => onPlayPauseResume();
    @override
    Future<void> pause() async => onPlayPauseResume();
    @override
    Future<void> skipToNext() async => onSkipNext();
    @override
    Future<void> seek(Duration position) async {
        onSeek(position);
        playbackState.add(playbackState.value.copyWith(updatePosition: position));
    }

    /// Clear all files, stop audio and shutdown the app.
    @override
    Future<void> stop() async {
        await AlbumArtHelper.clearAllFiles();
        onStop;
        await super.stop(); 
        // Exit. 
        if (Platform.isAndroid) SystemNavigator.pop();        
        exit(0);
    }

    void updateMetadata(Song song) async {
        // Reset the playback state for the new song.
        playbackState.add(
            playbackState.value.copyWith(
                updatePosition: Duration.zero, // Start from beginning.
                speed: 1.0,
                processingState: AudioProcessingState.loading,
            )
        );

        final currentDuration = await _service.getCurrentDuration() ?? Duration.zero;

        Uri? albumArtUri;
        if (song.albumArtBytes != null && song.albumArtBytes!.isNotEmpty) {
            albumArtUri = await AlbumArtHelper.getAlbumArtUri(song.albumArtBytes!, song.assetPath);
        }

        mediaItem.add(
            MediaItem(
                id: song.assetPath,
                album: song.album,
                title: song.title,
                artist: song.artist,
                duration: currentDuration,
                artUri: albumArtUri,
            )
        );
    }
}