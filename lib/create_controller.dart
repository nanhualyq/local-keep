import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_keep/home_controller.dart';
import 'package:record/record.dart';

class CreateController extends GetxController {
  final formKey = GlobalKey<FormState>();
  var textController = TextEditingController();
  late final Record record;
  bool isRecording = false;

  @override
  void onInit() {
    record = Record();
    super.onInit();
  }

  @override
  void onClose() {
    textController.dispose();
    record.dispose();
    super.onClose();
  }

  void addText() {
    if (formKey.currentState!.validate()) {
      HomeController.to.addText(textController.text);
      Get.back();
    }
  }

  Future<void> startRecord() async {
    // Check and request permission
    if (await record.hasPermission()) {
      // Start recording
      isRecording = true;
      await record.start();
      update();
    }
  }

  Future<void> stopRecord() async {
    if (await record.isRecording()) {
      // Stop recording
      var path = await record.stop();
      HomeController.to.saveAsNew(path);
    }
    isRecording = false;
    update();
    Get.back();
  }

  Future<void> addPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    HomeController.to.saveAsNew(photo?.path);
    Get.back();
  }

  Future<void> addVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? cameraVideo =
        await picker.pickVideo(source: ImageSource.camera);
    HomeController.to.saveAsNew(cameraVideo?.path);
    Get.back();
  }

  Future<void> addFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) {
      return;
    }
    for (var file in result.files) {
      HomeController.to.saveAsNew(file.path);
    }
    Get.back();
  }

  void leavePage() {
    if (textController.text != '') {
      Get.defaultDialog(
          title: 'Are you sure?',
          middleText: '',
          textCancel: 'Stay',
          onCancel: () {},
          textConfirm: 'Leave',
          onConfirm: () => Get.back(closeOverlays: true));
    } else {
      Get.back();
    }
  }
}
