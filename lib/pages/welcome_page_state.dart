import 'package:flutter/material.dart';

import 'playlist_page.dart';
import 'song_screen.dart';
import 'welcome_page.dart';
import '../entities/audio_player_service.dart'; 
import '../entities/song.dart'; 
import '../entities/song_controls_manager.dart'; 

/// Let user switch between different sections of the app, using the navigation rails. 
/// 
/// Page provides unified [AudioPlayerService] and [SongControlsManager] that will be passed to all other pages listed here. 
/// This ensure the playing of audio consistently across different pages. Currently, there are 2 direct pages - all other pages are sub-pages of these 2: 
/// 1. [SongScreen] which display the content of the masterPlaylist - [SongRepository.masterSongPlaylist]. 
/// 2. [PlaylistPage] which display the overview of all playlists - [SongRepository.allSongPlaylists]. 
class WelcomePageState extends State<WelcomePage> {
    int _selectedIndex = 0;

    // Unified audio and controls across all pages of the app to ensure song persists. 
    late final AudioPlayerService audioService;
    late SongControlsManager _controlsManager;
    
    // Audio state attribute that will be shared across all pages
    Song? _currentSong;
    bool _isLooping = false;
    bool _isRandom = false;
    Duration _currentDuration = Duration.zero;
    Duration _currentPosition = Duration.zero;
    
    @override
    void initState() {
        super.initState();
        // Shared audio service across all pages. 
        audioService = AudioPlayerService();
        // Shared controls manager across all pages. 
        _controlsManager = SongControlsManager(
            audioService: audioService,
            context: context,

            getCurrentSong: () => _currentSong,
            getIsLooping: () => _isLooping,
            getIsRandom: () => _isRandom,

            setCurrentSong: (song) => setState(() => _currentSong = song),
            setIsLooping: (isLooping) => setState(() => _isLooping = isLooping),
            setIsRandom: (isRandom) => setState(() => _isRandom = isRandom),
            resetPlaybackState: () {
                setState(() {
                    _currentSong = null;
                    _currentDuration = Duration.zero;
                    _currentPosition = Duration.zero;
                });
            },
            setCurrentPosition: (position) => setState(() => _currentPosition = position),
            setCurrentDuration: (duration) => setState(() => _currentDuration = duration),
            notifySongListChanged: () => setState(() { /* Trigger rebuild */ }),
        );
    }
    
    /// Provide the NavigationBar (bottom) with a fade transition to hide the loading. 
    @override 
    Widget build (BuildContext context) {    
        return Scaffold(
            body: SafeArea(
                child: Material(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: _buildTransitionAnimation(),
                ),
            ),
            bottomNavigationBar: NavigationBar(
                height: 70,
                onDestinationSelected: (value) => setState(() => _selectedIndex = value),
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
                ],
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
                return FadeTransition(
                    opacity: Tween <double> (begin: 0.0, end: 1).animate(animation),
                    child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        axisAlignment: -1,
                        child: child,
                    ),
                );
            },
            child: _buildPages(),
        );
    }

    /// Create destination pages and passed the corretly service to them. 
    Widget _buildPages() {
        switch (_selectedIndex) {
            case 0: 
                return SongScreen(
                    audioService: audioService,
                    controlsManager: _controlsManager,
                    currentSong: _currentSong,
                    isLooping: _isLooping,
                    isRandom: _isRandom,
                    currentDuration: _currentDuration,
                    currentPosition: _currentPosition,
                );
            case 1: 
                return PlaylistPage(
                    audioService: audioService,
                    controlsManager: _controlsManager,
                    currentSong: _currentSong,
                    isLooping: _isLooping,
                    isRandom: _isRandom,
                    currentDuration: _currentDuration,
                    currentPosition: _currentPosition,
                );
            default: 
                return const SizedBox(); // This should NOT happen. Like ever. 
        }
    }

    @override
    void dispose() {
        _controlsManager.cancelAudioStreams();
        audioService.stop();
        super.dispose();
    }
}