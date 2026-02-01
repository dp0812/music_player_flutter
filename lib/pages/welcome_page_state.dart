import 'package:flutter/material.dart';

import 'playlist_page.dart';
import 'settings_page.dart';
import 'song_screen.dart';
import 'welcome_page.dart';
import '../entities/audio_player_service.dart'; 
import '../entities/song_controls_manager.dart'; 

/// Let user switch between different sections of the app, using the navigation bar.
/// 
/// This navigation bar will be locked during loading time to ensure that one page MUST load FULLY before user can navigate away.
/// 
/// Page provides unified [AudioPlayerService] and [SongControlsManager] that will be passed to all other pages listed here. 
/// This ensure the playing of audio consistently across different pages. Currently, there are 3 direct pages - all other pages are sub-pages of these 3: 
/// 1. [SongScreen] which display the content of the masterPlaylist - [SongRepository.masterSongPlaylist]. 
/// 2. [PlaylistPage] which display the overview of all playlists - [SongRepository.allSongPlaylists]. 
/// 3. [SettingsPage] which display the theme setting and others info. 
class WelcomePageState extends State<WelcomePage> {
    int _selectedIndex = 0;
    /// Determining the direction of the slide animation. 
    int _previousIndex = 0;

    /// Loading state for each page, same as their selected index. 
    final Map<int, bool> _pageLoadingStates = {
        0: false, // SongScreen.
        1: false, // PlaylistPage.
        2: false, // SettingsPage.
    };

    @override
    void initState() {
        super.initState();
    }
    
    /// Provide the NavigationBar (bottom) with a slide transition to hide the loading. 
    /// 
    /// This navigation bar will be locked during loading time to ensure that one page MUST load FULLY before user can navigate away.
    @override 
    Widget build (BuildContext context) {    
        return Scaffold(
            body: SafeArea(
                child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: _buildTransitionAnimation(),
                ),
            ),
            bottomNavigationBar: _buildNavigationBar(),
        );
    }

    /// Build navigation bar with conditional lock. 
    Widget _buildNavigationBar() {
        // Determine if current page is loading.
        bool isCurrentPageLoading = _pageLoadingStates[_selectedIndex] ?? false;
        
        return AbsorbPointer(
            // Lock the navigation bar till we are done loading. 
            absorbing: isCurrentPageLoading,
            child: Opacity(
                opacity: isCurrentPageLoading ? 0.5 : 1.0,
                child: NavigationBar(
                    height: 70,
                    onDestinationSelected: isCurrentPageLoading ? null : 
                    (value) {
                        setState(() {
                            _previousIndex = _selectedIndex;
                            _selectedIndex = value;
                        });
                    },
                    selectedIndex: _selectedIndex,
                    destinations: [
                        NavigationDestination(
                            icon: Icon(Icons.home_outlined, size: 20),
                            label: "Home",
                        ),
                        NavigationDestination(
                            icon: Icon(Icons.library_music_outlined, size: 20),
                            label: "Library",
                        ),
                        NavigationDestination(
                            icon: Icon(Icons.settings, size: 20), 
                            label: "Settings",
                        ),
                    ],
                    labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                ),
            ),
        );
    }


    /// Create a fade animation, and also call the correct pages. 
    Widget _buildTransitionAnimation(){
        return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
                final slideOffset = _getSlideOffset();
                
                final slideAnimation = Tween<Offset>(
                    begin: slideOffset,
                    end: Offset.zero,
                ).animate(animation);
                
                return SlideTransition(
                    position: slideAnimation,
                    child: child,
                );
            },
            child: _buildPages(),
        );
    }   

    /// Create destination pages. 
    Widget _buildPages() {
        switch (_selectedIndex) {
            case 0: 
                return SongScreen(
                    audioService: widget.audioService,
                    controlsManager: widget.controlsManager,
                    onLoadingStateChanged: (isLoading) => _handlePageLoading(0, isLoading),
                );
            case 1: 
                return PlaylistPage(
                    audioService: widget.audioService,
                    controlsManager: widget.controlsManager,
                    onLoadingStateChanged: (isLoading) => _handlePageLoading(1, isLoading),
                );
            case 2: 
                return SettingsPage(
                    audioService: widget.audioService, 
                    controlsManager: widget.controlsManager, 
                );
            default: 
                return const SizedBox(); // This should NOT happen. Like ever. 
        }
    }

    /// Determine slide direction based on navigation.
    Offset _getSlideOffset() {
        if (_selectedIndex > _previousIndex) {
            // Moving right (Home -> Library, Library -> Settings).
            return const Offset(1.0, 0.0);
        } else if (_selectedIndex < _previousIndex) {
            // Moving left (Settings -> Library, Library -> Home).
            return const Offset(-1.0, 0.0);
        } else {
            // Same page. This should not happen. 
            return const Offset(1.0, 0.0);
        }
    }

    /// Handle page loading state changes.
    void _handlePageLoading(int pageIndex, bool isLoading) {
        // Still loading then we do nothing. 
        if (_pageLoadingStates[pageIndex] == isLoading) return;
        // Update page to complete loading status. 
        _pageLoadingStates[pageIndex] = isLoading;
        if (pageIndex == _selectedIndex && mounted) {
            /// The following error is avoided by using microtask: 
            /// From lib => home, the lib is disposed, => set the loading to false. 
            /// This mean the tree is locked. So calling a normal set state will crash the app. 
            /// 
            /// The exception looks something like this: 
            /// FlutterError (setState() or markNeedsBuild() called when widget tree was locked.
            /// This WelcomePage widget cannot be marked as needing to build because the framework is locked.
            /// The widget on which setState() or markNeeds Build() was called was:
            /// WelcomePage)
            /// 
            /// So instead, wait till this tree is unlocked (animation done), then call setstate.
            /// microtask is nothing but a scheduler. 
            Future.microtask(() {
                if (mounted) {
                    setState(() {/* Schedule rebuild. */});
                }
            });
        }
    }

    @override
    void dispose() {
        widget.controlsManager.cancelAudioStreamsAndSubscriptions();
        super.dispose();
    }
}