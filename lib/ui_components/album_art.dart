import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Provides visualization of album art, constrained to a sized box, with default placeholder for null. 
class AlbumArt extends StatelessWidget{
    /// The bytes extracted from metadata of an mp3 file that holds an album art. 
    final Uint8List? albumArtBytes;

    const AlbumArt({super.key, this.albumArtBytes});

    @override
    Widget build(BuildContext context) {
        return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                    ),
                ],
                color: Theme.of(context).colorScheme.surface , // same as background color. 
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildAlbumArtImage()
            ),
        );
    }

    /// Build album art from [albumArtBytes], has placeholder for null. 
    Widget _buildAlbumArtImage(){
        if (albumArtBytes != null){
            return Image.memory(
                albumArtBytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {return _buildPlaceholderIcon("Image Error");},
            );
        }
        return _buildPlaceholderIcon("No Album Art");
    }

    /// Build placeholder image. 
    Widget _buildPlaceholderIcon(String text) {
        return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                const Icon(Icons.music_note, size: 50, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                    text,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
        ),
        );
    }
}