import 'package:flutter/material.dart';

import 'repmind_colors.dart';
import 'repmind_radius.dart';

abstract final class RepmindDecorations {
  static BoxDecoration limeHero(RepmindColors colors) => BoxDecoration(
    color: colors.lime,
    borderRadius: BorderRadius.circular(RepmindRadius.hero),
    border: Border.all(color: colors.limeEdge),
  );
}
