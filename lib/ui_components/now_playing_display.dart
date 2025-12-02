import 'package:flutter/material.dart';
import '../entities/song.dart';

// ------------------------------------------------
// 2. Extracted UI Component: Now Playing Display
// ------------------------------------------------

class NowPlayingDisplay extends StatelessWidget {
    final Song? currentSong;

    const NowPlayingDisplay({super.key, required this.currentSong});

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
                'Now Playing: ${currentSong?.title ?? "None"}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
        );
    }
}
