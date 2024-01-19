import 'package:renpy_decompiler_backend/cli.dart';

Future<void> main(List<String> arguments) async {
  print('Started CLI');
  await loadCLI(arguments);
}
