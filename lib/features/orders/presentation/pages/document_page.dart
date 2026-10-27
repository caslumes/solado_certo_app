import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/downloaded_file.dart';
import 'package:solado_certo_app/core/files/file_opening.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    super.key,
    required this.url,
    required this.title,
    required this.load,
    this.openPdf = _openPdf,
  });

  final String url;
  final String title;
  final Future<DownloadedFile> Function(String url) load;
  final Future<bool> Function(List<int> bytes, String filename) openPdf;

  static Future<bool> _openPdf(List<int> bytes, String filename) =>
      openWithSystemViewer(bytes, filename);

  static Route<void> route(String url, {required String title}) {
    return MaterialPageRoute(
      builder: (_) => DocumentPage(
        url: url,
        title: title,
        load: getIt<OpenDocumentUseCase>().execute,
      ),
    );
  }

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  late Future<DownloadedFile> _file = widget.load(widget.url);

  void _retry() {
    setState(() {
      _file = widget.load(widget.url);
    });
  }

  Future<void> _open(DownloadedFile file) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = 'documento-${widget.url.split('/').last}.pdf';
    final opened = await widget.openPdf(file.bytes, name);
    if (opened) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Nenhum aplicativo deste aparelho abre PDF.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        title: Text(widget.title.toUpperCase(), style: textTheme.bodyMedium),
      ),
      body: FutureBuilder<DownloadedFile>(
        future: _file,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Message(
              message: Failure.from(snapshot.error!).message,
              action: ShoeTextButton(
                onPressed: _retry,
                text: 'Tentar novamente',
              ),
            );
          }
          final file = snapshot.data;
          if (file == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (file.isImage) {
            return InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.memory(Uint8List.fromList(file.bytes)),
              ),
            );
          }
          return _Message(
            icon: Icons.picture_as_pdf_outlined,
            message: file.isPdf
                ? 'O documento está em PDF. Abra no leitor do aparelho.'
                : 'Não é possível mostrar este arquivo.',
            action: file.isPdf
                ? ShoeTextButton(
                    onPressed: () => _open(file),
                    text: 'Abrir PDF',
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.icon, this.action});

  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          children: [
            if (icon != null) Icon(icon, size: 48),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
