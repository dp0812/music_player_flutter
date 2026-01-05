import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../entities/song.dart';

/// Allow a single song button, and a single effect enable on selected and playing (SpinKitWave). 
class TrailingRow extends StatelessWidget {
    final Function(Song)? onSongButtonTap;
    final Song song;
    final bool? isSelected; 
    final bool? isPlaying; 

    const TrailingRow({
        super.key, 
        required this.song,
        required this.isSelected, 
        required this.isPlaying,
        this.onSongButtonTap,
    });

    @override
    Widget build(BuildContext context) {
        return Row(
            // If not provided the correct function, then we dont display the button.
            mainAxisSize: MainAxisSize.min,
            children: [
                // Playing wave effect (to the left of the delete button).
                if ((isSelected != null && isSelected == true) && (isPlaying != null && isPlaying == true))
                    Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child: SpinKitWave(
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 16,
                            ),
                        ),
                    ),
                // Delete button, if provided. 
                if (onSongButtonTap != null)
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red), 
                        onPressed: () => onSongButtonTap!(song),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: "Delete Song", 
                    )
            ]
        );
    }
}