import 'package:flutter/material.dart';

/// The image on top of the island. 
class PlaylistCover extends StatelessWidget {
    /// How much of the CD is out. This number must be the same as [PlaylistGridTile] padding to the right, else the CD will be clipped. 
    final double sliding; 
    final bool enableDisc; 
    final Widget? playlistArt; 

    const PlaylistCover({super.key, this.sliding = -20, this.enableDisc = false, this.playlistArt});

    @override
    Widget build(BuildContext context) {
        return Stack(
            clipBehavior: Clip.none,
            children: [
                // Black CD. 
                if (enableDisc)
                    Positioned(
                        right: sliding,
                        top: 5,
                        bottom: 5,
                        child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black, 
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3), 
                                        width: 0.5,
                                    ),
                                ),
                                child: Center(
                                    child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.onSecondary,
                                            shape: BoxShape.circle,
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                        children: [
                            // Solid background to hide the disc.
                            Container(
                                color: Theme.of(context).colorScheme.onSecondary,
                            ),
                            // Overlay image, placeholder if not found. 
                            Container(
                                decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        width: 2,
                                    ),
                                ),
                                child: 
                                playlistArt ??
                                const Center(
                                    child: Icon(
                                        Icons.featured_play_list_rounded,
                                        size: 48,
                                        color: Colors.white,
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        );
    }
}