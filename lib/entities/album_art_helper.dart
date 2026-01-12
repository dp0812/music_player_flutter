import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../utilities/io_print.dart';

/// Helper to store and retrieve album art for notification fast. 
/// 
/// Remarks: When the app terminates in the correct way, that is, clicking on the stop button on the notification bar, it deletes all saved art files. 
/// Thus the [cleanUpOldFiles] might feels redundant. That [cleanUpOldFiles] is for the system to self check and clean up if the app terminates unexpectedly. 
class AlbumArtHelper {
    /// Store the art Path with a Key. 
    static final Map<String, String> _artPathsMap = {};

    /// Convert album art bytes to a temporary file and return its URI.
    static Future<Uri?> getAlbumArtUri(Uint8List? albumArtBytes, String songId) async {
        if (albumArtBytes == null || albumArtBytes.isEmpty) return null;

        // Check available files. 
        if (_artPathsMap.containsKey(songId)) {
            final String savedArtPath = _artPathsMap[songId]!;
            if (await File(savedArtPath).exists()){
                IO.t("Found art already saved at $songId");
                return Uri.file(savedArtPath);
            } 
        }

        try {
            final Directory tempDir = await getTemporaryDirectory();
            final String fileName = "album_art_${songId.hashCode}_${DateTime.now().millisecondsSinceEpoch}.jpg";
            final String filePath = path.join(tempDir.path, fileName);
            final File file = File(filePath);
            await file.writeAsBytes(albumArtBytes);
            IO.t("Saved new art image: $filePath");
            _artPathsMap[songId] = filePath;
            return Uri.file(filePath);
        } catch (e) {
            IO.e("Error creating album art file: $e");
            return null;
        }
    }

    /// Clean up old album art files, in case the app terminates incorrectly (not with the stop button on the notification bar). 
    static Future<void> cleanUpOldFiles() async {
        try {
            IO.i("Cleaning up temp files older than 1 days...");
            final Directory tempDir = await getTemporaryDirectory();
            final List<FileSystemEntity> files = tempDir.listSync();
            final DateTime now = DateTime.now();
            int deleteCount = 0; 
            
            for (var file in files) {
                if (file is File && file.path.contains("album_art_")) {
                    try {
                        final stat = await file.stat();
                        final age = now.difference(stat.modified);
                        // Delete files older than 1 day.
                        if (age.inDays > 1) {
                            await file.delete();
                            IO.t("Delete album art number: ${deleteCount++}"); 
                            _artPathsMap.removeWhere((key, value) => value == file.path);
                        }
                    } catch (e) {
                        IO.e("Error processing file ${file.path}: $e");
                    }
                }
            }
        } catch (e) {
            IO.e("Error cleaning up album art files: $e");
        }
    }

    /// Clear all temp files when terminate the app.
    static Future<void> clearAllFiles() async {
        try {
            IO.i("Cleaning up cache files before closing app...");
            final tempDir = await getTemporaryDirectory();
            final files = tempDir.listSync();
            int deleteCount = 0; 
            
            for (var file in files) {
                if (file is File && file.path.contains("album_art_")) {
                    try {
                        await file.delete();
                        IO.t("Delete album art number: ${deleteCount++}"); 
                    } catch (e) {
                        IO.e("Error deleting file ${file.path}: $e");
                    }
                }
            }
            _artPathsMap.clear();
            // Do not attempt to delete all "others" file. There will be non existance file exception throw if do so. 
        } catch (e) {
            IO.e("Error clearing album art files: $e");
        }
    }
}