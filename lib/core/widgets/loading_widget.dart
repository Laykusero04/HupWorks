import 'package:flutter/material.dart';

import 'rubik_color_loader.dart';

/// Default full-area loading indicator — 4×4 color Rubik (not the splash images).
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.size = 56,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RubikColorLoader(size: size),
    );
  }
}
