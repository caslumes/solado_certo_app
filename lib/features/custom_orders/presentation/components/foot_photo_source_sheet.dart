import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solado_certo_app/core/files/image_picking.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';

Future<UploadFile?> pickFootPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => const FootPhotoSourceSheet(),
  );
  return source == null ? null : pickImage(source);
}

class FootPhotoSourceSheet extends StatelessWidget {
  const FootPhotoSourceSheet({super.key});

  static const _sources = [
    (ImageSource.camera, Icons.photo_camera_outlined, 'Tirar foto'),
    (ImageSource.gallery, Icons.photo_library_outlined, 'Escolher da galeria'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Foto do pé', style: textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'JPEG ou PNG de até 5 MB. Fotografe a sola do pé descalço, de '
              'cima e com boa luz.',
              style: textTheme.bodySmall,
            ),
          ),
          for (final (source, icon, label) in _sources)
            ListTile(
              leading: Icon(icon),
              title: Text(label, style: textTheme.bodyLarge),
              onTap: () => Navigator.of(context).pop(source),
            ),
        ],
      ),
    );
  }
}
