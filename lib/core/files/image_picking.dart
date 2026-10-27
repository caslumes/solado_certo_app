import 'package:image_picker/image_picker.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';

Future<UploadFile?> pickImageFromGallery({ImagePicker? picker}) =>
    pickImage(ImageSource.gallery, picker: picker);

Future<UploadFile?> pickImage(ImageSource source, {ImagePicker? picker}) async {
  final image = await (picker ?? ImagePicker()).pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );
  if (image == null) return null;

  return UploadFile(bytes: await image.readAsBytes(), filename: image.name);
}
