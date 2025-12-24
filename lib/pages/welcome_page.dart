import 'package:flutter/material.dart';

import 'welcome_page_state.dart';

/// Provides navigation bar and initializes resources in its state.
/// 
/// These resources will carry on around all different pages of the application.  
class WelcomePage extends StatefulWidget {
    const WelcomePage({super.key});

    @override
    State<WelcomePage> createState() => WelcomePageState();
}