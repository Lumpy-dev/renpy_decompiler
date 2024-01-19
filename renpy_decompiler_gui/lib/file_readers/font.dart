import 'package:flutter/material.dart';

class FontTextReader extends StatefulWidget {
  final String family;

  const FontTextReader({super.key, required this.family});

  @override
  State<FontTextReader> createState() => _FontTextReaderState();
}

class _FontTextReaderState extends State<FontTextReader> {
  String fontText = '';
  final String defaultFontText =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz123456789?!@#\$%^&*()_+-=';
  @override
  Widget build(BuildContext context) {
    if (fontText.isEmpty) {
      fontText = defaultFontText;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            TextField(
                onChanged: (value) {
                  setState(() {
                    fontText = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Change text'),
                maxLines: null),
            const SizedBox(height: 16),
            Text('Original text: $fontText', textAlign: TextAlign.center),
          ],
        ),
        Expanded(
            child: Center(
                child: Text(fontText,
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(fontFamily: widget.family),
                    textAlign: TextAlign.center))),
      ],
    );
  }
}
