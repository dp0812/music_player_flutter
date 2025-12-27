import 'package:flutter/material.dart';

import 'song.dart';
import '../utilities/io_print.dart';

/// Search for the song in the list and let user to click on a song in the search result and play the song. 
/// 
/// This immediately set the active list to the current playlist.    
/// If user click on any song of the search result => immediately return user to the previous page. 
class SongSearchDelegate extends SearchDelegate {
    List<Song> availableSongs = [];
    final void Function(Song song) onSongTap; 

    SongSearchDelegate({required this.onSongTap, required this.availableSongs}){
        if (availableSongs.isNotEmpty) IO.t("Song names updated.");
    }

    /// Clear the search text box. 
    @override
    List<Widget>? buildActions(BuildContext context) {
        return [IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
                query = "";
            },
        )];
    }

    /// Go back button. 
    @override
    Widget? buildLeading(BuildContext context) {
        return IconButton(
            icon: const Icon(Icons.arrow_back), 
            onPressed: () {
                close(context,null);
            } 
        );
    }

    @override
    Widget buildResults(BuildContext context) {
        return _buildSongsList();
    }

    @override
    Widget buildSuggestions(BuildContext context) {
        return _buildSongsList();
    }

    /// List view of the search result items.
    /// 
    /// Remark: this is very similar to the SongList.  
    Widget _buildSongsList(){
        List<Song> matchingSongs = availableSongs.where((song) => song.title.toLowerCase().contains(query.toLowerCase())).toList();
        return ListView.builder(
            itemCount: matchingSongs.length,
            itemBuilder: (context, index){
                Song result = matchingSongs[index];
                return ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(result.title, style: TextStyle(fontWeight: FontWeight.bold),),
                    subtitle: Text(result.artist ?? "Unknown"),
                    onTap: (){
                        onSongTap(result);
                        close(context, null);
                    },
                );
            }
        );
    }
}