import 'package:file_picker/file_picker.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';

Future<UploadFile?> pickPdf() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  if (file == null) return null;

  return UploadFile(bytes: await file.readAsBytes(), filename: file.name);
}
