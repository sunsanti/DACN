import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web: wrap the bytes in a Blob and open the PDF in a new browser tab.
Future<String?> openPdf(Uint8List bytes, String filename) async {
  final blob = html.Blob(<Object>[bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // The object URL is kept until the tab opens; the browser cleans it up.
  return null;
}
