import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

typedef PickedFile = ({String name, Uint8List bytes});

/// Opens the system file picker. Returns null when the user cancels.
/// Replaceable in tests.
Future<PickedFile?> Function() pickStatementFile = () async {
  final f = await FilePicker.pickFile(dialogTitle: 'Escolher extrato (OFX ou CSV)');
  if (f == null) return null;
  return (name: f.name, bytes: await f.readAsBytes());
};
