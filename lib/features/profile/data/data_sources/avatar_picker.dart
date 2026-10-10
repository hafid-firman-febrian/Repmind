import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/error_mapper.dart';

part 'avatar_picker.g.dart';

class AvatarPicker {
  AvatarPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<Uint8List?> pickFromGallery() => runGuarded(() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  });
}

@Riverpod(keepAlive: true)
AvatarPicker avatarPicker(Ref ref) => AvatarPicker();
