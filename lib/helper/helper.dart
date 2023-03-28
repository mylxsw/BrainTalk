import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

String randomId() {
  return const Uuid().v4();
}

Future<void> writeFile(String path, String content) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$path');
    print('${directory.path}/$path');
    await file.writeAsString(content);
  } catch (e) {
    print('写入文件失败: $e');
  }
}

Future<String> readFile(String path) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$path');
    return await file.readAsString();
  } catch (e) {
    return '[]';
  }
}

Future<String> copyExternalFileToAppDocs(String externalFilePath) async {
  // Get the external file
  final File externalFile = File(externalFilePath);

  // Check if the external file exists
  if (!await externalFile.exists()) {
    throw Exception('External file not found at: $externalFilePath');
  }

  // Get the ApplicationDocumentsDirectory
  final Directory appDocsDir = await getApplicationDocumentsDirectory();

  // Generate a UUID for the new file name
  final String uuid = const Uuid().v4();

  // Get the file extension
  final String fileExtension = externalFile.path.split('.').last;

  // Create a new file in the ApplicationDocumentsDirectory with the UUID as its name
  final File newFile = File('${appDocsDir.path}/$uuid.$fileExtension');

  // Copy the external file to the new file in the ApplicationDocumentsDirectory
  await externalFile.copy(newFile.path);

  print('File copied to: ${newFile.path}');
  return newFile.path;
}
