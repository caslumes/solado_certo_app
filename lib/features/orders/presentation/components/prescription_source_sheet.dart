import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solado_certo_app/core/files/image_picking.dart';
import 'package:solado_certo_app/core/files/pdf_picking.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';

enum PrescriptionSource { camera, gallery, pdf }

Future<UploadFile?> pickPrescription(BuildContext context) async {
  final source = await showModalBottomSheet<PrescriptionSource>(
    context: context,
    builder: (context) => const PrescriptionSourceSheet(),
  );
  return switch (source) {
    PrescriptionSource.camera => pickImage(ImageSource.camera),
    PrescriptionSource.gallery => pickImage(ImageSource.gallery),
    PrescriptionSource.pdf => pickPdf(),
    null => null,
  };
}

class PrescriptionSourceSheet extends StatelessWidget {
  const PrescriptionSourceSheet({super.key});

  static const _sources = [
    (PrescriptionSource.camera, Icons.photo_camera_outlined, 'Tirar foto'),
    (
      PrescriptionSource.gallery,
      Icons.photo_library_outlined,
      'Escolher da galeria',
    ),
    (PrescriptionSource.pdf, Icons.picture_as_pdf_outlined, 'Arquivo PDF'),
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
            child: Text('Enviar receita', style: textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'PDF, JPEG ou PNG de até 5 MB. A foto precisa estar nítida e '
              'mostrar a receita inteira.',
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
