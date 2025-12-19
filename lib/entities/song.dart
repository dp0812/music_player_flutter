import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:music_player/utilities/io_print.dart';

class Song {
    final String title;
    final String assetPath;
    
    // Derived from assetPath.
    /// All metadata is store in this Tag. 
    Tag? currentTag;
    /// In order to display the picture, we MUST have its bytes. 
    Uint8List? albumArtBytes;
    String? errorMessage;
    String? artist;
    String? album;

    /// Prohibit the usage of this class without using the factory. 
    Song._create({required this.title, required this.assetPath});

    /// User must use this to ensure reading of metadata is completed. 
    /// 
    /// This functions wait for all metadata to be in place, and loaded correctly before returning an instance with this metadata. 
    static Future<Song> create({required String title, required String assetPath}) async{
        Song newSong = Song._create(title: title, assetPath: assetPath);
        await newSong._readMetadata();
        return newSong;
    }

    /// Tag store all metadata BUT we only want picture, and artist/album artist. NOTHING else. 
    Future<void> _readMetadata() async {
        try {
            Tag? tag = await AudioTags.read(assetPath);
            currentTag = tag; //this tag contains ALL metadata info. 
            // Extract album art from pictures
            if (tag?.pictures != null && tag!.pictures.isNotEmpty) {
                // Try to find front cover first
                Picture? cover = tag.pictures.firstWhere(
                    (picture) => picture.pictureType == PictureType.coverFront,
                    orElse: () => tag.pictures.first,
                );
                albumArtBytes = cover.bytes;
                IO.t("Found album art for Song '$title'.");
            } else {
                albumArtBytes = null;
            }

            if (currentTag != null){
                if (currentTag?.trackArtist != null) {
                    artist = currentTag!.trackArtist;
                } else if (currentTag?.albumArtist != null ){
                    artist = currentTag!.albumArtist;
                }
            }
            errorMessage = null;
        } catch (e) {
            errorMessage = "Error reading metadata: $e";
            currentTag = null;
            albumArtBytes = null;
        }
    }
}