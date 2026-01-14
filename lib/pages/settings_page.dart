import 'package:flutter/widgets.dart';

import '../entities/audio_player_service.dart';
import '../entities/song_controls_manager.dart';
import 'settings_page_state.dart';

/// The setting maintain persistent theme using the shared preferences. 
class SettingsPage extends StatefulWidget{
    final AudioPlayerService audioService;
    final SongControlsManager controlsManager;

    const SettingsPage({
        super.key,
        required this.audioService,
        required this.controlsManager,
    });

    @override
    State<StatefulWidget> createState() => SettingsPageState();
}