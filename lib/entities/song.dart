import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';

/// All metadata of the Song can be obtained from the current tag. 
/// 
/// However, this class provide quick access to the title, assetPath and mainly the song cover art.
class Song {
    String title;
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
    /// [title] is a backup solution if the metadata does not contain a title. 
    static Future<Song> create({required String title, required String assetPath}) async{
        Song newSong = Song._create(title: title, assetPath: assetPath);
        await newSong._readMetadata();
        return newSong;
    }

    /// Read the picture, title and artist from the tag.  
    Future<void> _readMetadata() async {
        try {
            Tag? tag = await AudioTags.read(assetPath);
            currentTag = tag; // This tag contains ALL metadata info. 
            if (currentTag == null) return; 
            
            // Extract album art from pictures.
            if (currentTag!.pictures.isNotEmpty) {
                // Try to find front cover first.
                Picture? cover = currentTag!.pictures.firstWhere(
                    (picture) => picture.pictureType == PictureType.coverFront,
                    orElse: () => currentTag!.pictures.first,
                );
                albumArtBytes = cover.bytes;
            } else {
                albumArtBytes = null;
            }

            // Find the title. 
            if (currentTag!.title != null) title = currentTag!.title!; 

            // Find the artist. Use albumArtist if not found trackArtist. 
            if (currentTag!.trackArtist != null) {
                artist = currentTag!.trackArtist;
            } else if (currentTag!.albumArtist != null ){
                artist = currentTag!.albumArtist;
            }
            
        } catch (e) {
            errorMessage = "Error reading metadata: $e";
            currentTag = null;
            albumArtBytes = null;
        }
    }

    /// Return true if name or assetPath is the same, and false if null. 
    /// 
    /// This is due to the behavior of the file picker in android platform.  
    bool isEqual(Song? someSong){
        if (someSong == null) return false; 
        return ((someSong.assetPath == assetPath) || (someSong.title == title));
    }
}