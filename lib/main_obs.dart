import 'package:get/state_manager.dart';

class MainObs {
  static final shortcutStatus = ''.obs;
  static final RxInt focusItemIndex = (-1).obs;

  static void setShortcutStatus(String action, [int? index]) {
    var i = index ?? focusItemIndex.value;
    if (index == null && focusItemIndex.value == -1) {
      return;
    }
    shortcutStatus.value = '$action/$i/${DateTime.now()}';
  }
}