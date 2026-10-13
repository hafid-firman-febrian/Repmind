import 'package:flutter/material.dart';

import 'repmind_colors.dart';
import 'repmind_text.dart';

extension RepmindThemeContext on BuildContext {
  RepmindColors get colors => Theme.of(this).extension<RepmindColors>()!;
  RepmindText get textStyles => Theme.of(this).extension<RepmindText>()!;
}
