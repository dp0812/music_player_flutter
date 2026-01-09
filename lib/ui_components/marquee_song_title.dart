import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../entities/song.dart';
import 'constraints.dart';

/// Wrap the [newCurrentSong] title with a marquee effect. 
/// 
/// The size of the marquee effect box, by default is [Constraints.titleBoxHeight] and [Constraints.titleBoxWidth]. 
class MarqueeSongTitle extends StatelessWidget{
    final Song? newCurrentSong; 
    final double titleBoxHeight;
    final double titleBoxWidth;

    const MarqueeSongTitle({
        super.key, 
        required this.newCurrentSong,
        this.titleBoxHeight = Constraints.titleBoxHeight,
        this.titleBoxWidth = Constraints.titleBoxWidth, 
    });
  
    @override
    Widget build(BuildContext context) {
        String title = newCurrentSong?.title ?? "Not Playing Anything"; 

        // Max width of the song title is 100 pixel. 
        final titlePixelWidth = TextPainter(
            text: TextSpan(
                text: title, 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
        )..layout(maxWidth: titleBoxWidth);

        // If not enought space, use marquee effect. 
        if (titlePixelWidth.didExceedMaxLines) {
            return SizedBox(  // DO NOT remove this or the marque will crash the app. 
                width: titleBoxWidth, 
                height: titleBoxHeight, 
                child: Marquee(
                    text: title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    blankSpace: 50.0,
                    velocity: 30.0,
                    startPadding: 10.0,
                    fadingEdgeStartFraction: 0.1,
                    fadingEdgeEndFraction: 0.1,
                ),
            );
        }

        // If there is enough space then just use a normal text title. 
        return SizedBox(
            width: titleBoxWidth, 
            height: titleBoxHeight, 
            child: Padding( 
                padding: const EdgeInsets.only(top: 4), // Fine tunning for the text to go fuck down. 
                child: Text(
                    title, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                )
            ), 
        );
    }

}