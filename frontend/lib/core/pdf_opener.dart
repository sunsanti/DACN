import 'dart:typed_data';

// Picks the native or web implementation at compile time.
import 'pdf_opener_io.dart' if (dart.library.html) 'pdf_opener_web.dart' as impl;

/// Saves/opens the PDF bytes. Returns a path on native, null on web (opened in
/// a new browser tab). Throws on failure.
Future<String?> openPdf(Uint8List bytes, String filename) =>
    impl.openPdf(bytes, filename);
