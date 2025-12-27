import 'package:flutter/material.dart';

import 'settings_page.dart';
import '../ui_components/current_theme_preview.dart';
import '../ui_components/music_player_dock.dart';
import '../ui_components/settings_list.dart';
import '../ui_components/theme_boxes_list.dart';

/// Provide a preset theme selection and show what color is being used. 
class SettingsPageState extends State<SettingsPage>{

    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        final currentTheme = Theme.of(context);
        // Rebuild when controlsManager changes.
        return ListenableBuilder(
            listenable: widget.controlsManager,
            builder: (context, child) {
                return Scaffold(
                    backgroundColor: currentTheme.scaffoldBackgroundColor,
                    appBar: AppBar(
                        title: const Text("Settings"),
                    ),
                    body: Stack(
                        children: [
                            _buildSettingsSections(),
                            _buildMusicPlayerDock(),
                        ],
                    ),
                );
            },
        );
    }

    /// Lists of current theme setting(s), with bottom padding.
    /// 
    /// This padding (180) is just enough for the dock in compact mode if scroll to list bottom.
    Widget _buildSettingsSections(){
        return CustomScrollView(
            slivers: [
                // Theme selection section.
                SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(child: ThemeBoxesList()),
                ),
                
                // Current theme preview.
                SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    sliver: SliverToBoxAdapter(child: CurrentThemePreview()),
                ),
                
                // App Settings Section. 
                SliverPadding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom+180),
                    sliver: SliverToBoxAdapter(child: SettingsList(onTapAbout: _showAboutInfo,)),
                ),
            ],
        );
    }

    /// Normal [MusicPlayerDock] configuration. 
    /// 
    /// Expandable, default in compact mode, showing the title. 
    Widget _buildMusicPlayerDock(){
        return Positioned(
            left: 0, 
            right: 0, 
            bottom: 0, 
            child: MusicPlayerDock(
                currentSong: widget.controlsManager.currentSong,
                duration: widget.controlsManager.currentDuration,
                position: widget.controlsManager.currentPosition,
                onSeek: widget.controlsManager.handleSeek,
                pushToDetail: widget.controlsManager.pushToSongDetailPage,
                
                audioService: widget.audioService,
                onNextSong: widget.controlsManager.gotoNextSong, 
                onPreviousSong: widget.controlsManager.gotoPreviousSong, 
                onPlayPauseResume: widget.controlsManager.handlePlayResumePause, 
                onStop: widget.controlsManager.stop,
                onToggleLoop: widget.controlsManager.toggleLoop,
                isLooping: widget.controlsManager.isLooping,
                onToggleRandom: widget.controlsManager.toggleRandom,
                isRandom: widget.controlsManager.isRandom,
            ),
        );
    }

    void _showAboutInfo() async {
        await showDialog(
            context: context, 
            builder: (BuildContext context) {
                return AlertDialog(
                    title: Text(
                        "About this project",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                        ),
                    ),
                    content: Text(
                        "Version whatever number.\n\n"
                        "This is work is progress, due to me hating music player with ads.\n\n"
                        "Feel free to join and contribute in the github repo.\n\n",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                    ),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                                "Close",
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                ),
                            ),
                        ),
                    ],
                );
            },
        );
    }

}