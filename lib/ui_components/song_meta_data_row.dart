import 'package:flutter/material.dart';

/// Each rows contain one meta data information - one attribute of Song object. 
class SongMetadataRow extends StatelessWidget {
    final String label;
    final String value;

    const SongMetadataRow({
        super.key,
        required this.label,
        required this.value,
    });

    @override
    Widget build(BuildContext context) {
        return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            SizedBox(
                width: 80,
                child: Text(
                    "$label:",
                    style: TextStyle(fontWeight: FontWeight.w500),
                ),
            ),
            Expanded(
                child: SelectableText(
                    value,
                    style: TextStyle(color: Colors.grey[100]),
                ),
            ),
            ],
        ),
        );
    }
}