import 'dart:io';
import 'dart:typed_data';

/// En movil y escritorio `record` devuelve una ruta de archivo real.
Future<Uint8List> readAudio(String path) => File(path).readAsBytes();

Future<void> deleteAudio(String path) async {
  final file = File(path);
  if (file.existsSync()) await file.delete();
}
