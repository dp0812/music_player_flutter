import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Provides visualization of album art, constrained to a sized box, with default placeholder for null. 
class AlbumArt extends StatelessWidget{
    /// The bytes extracted from metadata of an mp3 file that holds an album art. 
    final Uint8List? albumArtBytes;
    final double artHeight; 
    final double artWidth;
    /// How small is too small to show text in the image. 
    static const int threshold = 60; 

    const AlbumArt({super.key, this.albumArtBytes, this.artHeight = 200, this.artWidth = 200});

    @override
    Widget build(BuildContext context) {
        return Container(
            width: artWidth,
            height: artHeight,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                    ),
                ],
                color: Theme.of(context).colorScheme.surface , // Same as background color. 
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
    /// 
    /// Based on the size constraint, determine how to resize its content.  
    Widget _buildPlaceholderIcon(String text) {
        final bool showText = artHeight > threshold && artWidth > threshold;
        return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Resize icon if needed. 
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Icon(Icons.music_note, size: _calculateIconSize(), color: Colors.grey,),
                    ),
                    if (showText) const SizedBox(height: 8),
                    if (showText) FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                                text,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                            ),
                        ),
                ],
            ),
        );
    }

    /// Get icon size based on container dimensions.
    double _calculateIconSize() {
        final double minDimension = artHeight < artWidth ? artHeight : artWidth;
        // Resize based on min side. 
        double iconSize = minDimension * 0.5;
        if (iconSize > 50) iconSize = 50; // Max size. 
        if (iconSize < 16) iconSize = 16; // Min size.        
        return iconSize;
    }
}