import 'package:flutter/material.dart';

/// A list of listTile button, providing info of the project.  
class SettingsList extends StatelessWidget {
    
    final void Function() onTapAbout; 

    const SettingsList({
        super.key,
        required this.onTapAbout,
    });

    @override
    Widget build(BuildContext context) {
        final currentTheme = Theme.of(context);
        return Card(
            child: Column(
                children: [
                    ListTile( // Could be a preset directory that being read everytime the app start. 
                        leading: Icon(Icons.library_music, color: currentTheme.colorScheme.primary),
                        title: Text("Directory",style: TextStyle(color: currentTheme.colorScheme.onSurface)),
                        trailing: Icon(Icons.chevron_right, color: currentTheme.colorScheme.secondary),
                        onTap: () {},
                    ),
                    Divider(height: 0, color: currentTheme.colorScheme.secondary),
                    ListTile(
                        leading: Icon(Icons.info_outline, color: currentTheme.colorScheme.primary),
                        title: Text("About", style: TextStyle(color: currentTheme.colorScheme.onSurface)),
                        trailing: Icon(Icons.chevron_right, color: currentTheme.colorScheme.secondary),
                        onTap: onTapAbout,
                    ),
                ],
            ),
        );
    }
}