import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_keep/home_page.dart';
import 'package:path_provider/path_provider.dart';

const title = 'Local Keep';

void main() async {
  await GetStorage.init();
  var box = GetStorage();
  if (box.read('dataPath') == null) {
    var appDir = await getApplicationSupportDirectory();
    box.write('dataPath', appDir.path);
  }
  runApp(GetMaterialApp(
    home: const HomePage(),
    title: title,
    theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue, foregroundColor: Colors.white)),
  ));
}