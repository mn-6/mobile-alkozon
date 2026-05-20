import 'package:flutter/material.dart';

class HorizontalScrollText extends StatelessWidget {
  const HorizontalScrollText({
    super.key,
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Text(
        text,
        style: style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
