import 'package:image_picker/image_picker.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';

/// Opens the gallery and returns the chosen photo, or null if the user
/// cancels.
///
/// The photo is scaled down before upload, which keeps phone pictures well
/// under the server's 5 MB limit.
Future<UploadFile?> pickImageFromGallery({ImagePicker? picker}) async {
  final image = await (picker ?? ImagePicker()).pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );
  if (image == null) return null;

  return UploadFile(bytes: await image.readAsBytes(), filename: image.name);
}
