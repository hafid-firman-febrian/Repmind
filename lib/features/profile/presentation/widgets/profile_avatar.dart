import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.imageUrl, this.name, this.size = 44});

  final String? imageUrl;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = (name?.trim().isNotEmpty ?? false)
        ? name!.trim()[0].toUpperCase()
        : '?';
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceSunken,
        border: Border.all(color: colors.line),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.25),
          child: SizedBox.expand(
            child: FittedBox(
              child: Text(
                initial,
                style: context.textStyles.subtitle.copyWith(color: colors.ink),
              ),
            ),
          ),
        ),
      ),
    );
    final imageUrl = this.imageUrl;

    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: imageUrl == null
            ? fallback
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
