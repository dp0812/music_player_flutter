import 'package:flutter/material.dart';
import 'package:music_player/pages/playlist_page.dart';
import 'package:music_player/pages/song_screen.dart';
import 'package:music_player/pages/welcome_page.dart';

/// Let user switch between different sections of the app, using the navigation rails. 
class WelcomePageState extends State<WelcomePage> {
    @override
    Widget build (BuildContext context){
        int selectedIndex = 0;
        Widget page;
        switch (selectedIndex){
            case 0: page = SongScreen();
            case 1: page = PlaylistPage(); //needs implementation. 
            default: throw UnimplementedError("No widget for selected index: $selectedIndex ");
        }

        return Scaffold(
            body: Row(
                children: [
                    SafeArea(
                        child: NavigationRail(
                        extended: false,
                        destinations: [
                            NavigationRailDestination(
                                icon: Icon(Icons.home),
                                label: Text('Home'),
                            ),
                            NavigationRailDestination(
                                icon: Icon(Icons.featured_play_list),
                                label: Text('Favorites'),
                            ),
                        ],
                        selectedIndex: selectedIndex,
                        onDestinationSelected: (value) {
                            setState(() {selectedIndex = value;});
                            print('selected: $value'); //just to check if button is working.
                        },
                        ),
                    ),
                    Expanded(
                        child: Container(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: page,
                        ),
                    ),
                ],
            ),
		);

    }
}