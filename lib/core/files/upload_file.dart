/// A file picked by the user, ready to be sent as a multipart field.
///
/// The server detects the type from the bytes, so [filename] is only
/// informative.
class UploadFile {
  const UploadFile({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;
}
