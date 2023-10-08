import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_keep/home_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsController extends GetxController {
  final box = GetStorage();

  var pathController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  get dataPath => box.read('dataPath');

  @override
  void onInit() {
    pathController.text = dataPath;
    super.onInit();
  }

  @override
  void onClose() {
    pathController.dispose();
    super.onClose();
  }

  Future<void> pickDir() async {
    String? dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) {
      pathController.text = dir;
    }
  }

  Future<void> submitForm() async {
    var path = pathController.text;
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (!await checkAndroidPermission(path)) {
      return;
    }
    box.write('dataPath', path);
    Get.back();
    HomeController.to.fetchItems();
  }

  Future<bool> checkAndroidPermission(path) async {
    try {
      File('$path/.checkPermission')
        ..writeAsStringSync('')
        ..deleteSync();
    } on PathAccessException catch (e) {
      if (e.osError?.errorCode == 1) {
        if (Platform.isAndroid) {
          return await Permission.manageExternalStorage.request().isGranted;
        }
      }
    }
    return true;
  }
}
