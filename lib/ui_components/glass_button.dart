import 'package:flutter/material.dart';
import 'glass_morph.dart';

/// Simple glass effect button.
/// 
/// Currently being used by the [SongManagementBar].
class GlassButton extends StatelessWidget {
    final VoidCallback onTap;
    final IconData icon;
    final String text;
    final Color color;

    const GlassButton({
        super.key,
        required this.onTap,
        required this.icon,
        required this.text,
        required this.color,
    });

    @override
    Widget build(BuildContext context) {
        return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: GlassMorph(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(icon, color: color, size: 18), 
                                const SizedBox(width: 6), 
                                Text(
                                    text,
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 13, 
                                        fontWeight: FontWeight.w500,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}