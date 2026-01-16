import 'package:flutter/material.dart';

import 'playlists_list.dart';
import '../entities/song_playlist.dart';

/// Renaming and deleting of a playlist. 
class PlaylistPopUpMenu extends StatelessWidget {
    final SongsPlaylist playlist;
    final PlaylistTapCallback? onRename;
    final PlaylistTapCallback? onDelete;

    const PlaylistPopUpMenu({
        super.key,
        required this.playlist,
        this.onRename,
        this.onDelete,
    });

    @override
    Widget build(BuildContext context) {
        return PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (BuildContext context) {
                final menuItems = <PopupMenuEntry<String>>[];

                if (onRename != null) {
                    menuItems.add(
                        PopupMenuItem<String>(
                        value: "rename",
                        child: Row(
                            children: [
                                const Icon(Icons.edit, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text("Rename"),
                            ],
                        ),
                        ),
                    );
                }

                if (onDelete != null) {
                    menuItems.add(
                        PopupMenuItem<String>(
                        value: "delete",
                        child: Row(
                            children: [
                                const Icon(Icons.delete, color: Colors.red),
                                const SizedBox(width: 8),
                                Text("Delete"),
                            ],
                        ),
                        ),
                    );
                }

                return menuItems;
            },
            onSelected: (String value) {
                if (value == "rename" && onRename != null) onRename!(playlist);
                if (value == "delete" && onDelete != null) onDelete!(playlist);
            },
        );
    }
}