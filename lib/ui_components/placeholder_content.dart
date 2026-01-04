import 'package:flutter/material.dart';

/// Provide a placeholder screen for a message. 
/// 
/// Examples of usage include if a song list (or playlist list) is empty, then we display this.  
class PlaceholderContent extends StatelessWidget {
    final String displayMessage; 
    const PlaceholderContent({super.key, required this.displayMessage});

    @override
    Widget build(BuildContext context) {
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    displayMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                ),
            ),
        );
    }
}