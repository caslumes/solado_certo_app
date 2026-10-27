class DownloadedFile {
  const DownloadedFile({required this.bytes, required this.contentType});

  final List<int> bytes;
  final String contentType;

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType.startsWith('application/pdf');
}
