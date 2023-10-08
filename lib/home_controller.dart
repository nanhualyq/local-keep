import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_keep/create_page.dart';
import 'package:mime/mime.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:watcher/watcher.dart';

class HomeController extends GetxController {
  var box = GetStorage();
  List<FileSystemEntity> items = [];
  int? focusIndex;
  late StreamSubscription<List<SharedFile>> _intentDataStreamSubscription;

  @override
  void onInit() {
    fetchItems();
    if (Platform.isAndroid) {
      initQuickActions();
      initReceiveShareing();
    }
    initWatchDir();
    super.onInit();
  }

  @override
  void onClose() {
    if (Platform.isAndroid) {
      _intentDataStreamSubscription.cancel();
    }
    super.onClose();
  }

  static HomeController get to => Get.find();
  String get dataPath => box.read('dataPath');
  String get newName => DateTime.now().millisecondsSinceEpoch.toString();

  void goCreatePage() => Get.to(() => const CreatePage());
  void initQuickActions() {
    const QuickActions quickActions = QuickActions();
    quickActions.setShortcutItems(
        [const ShortcutItem(type: 'action_add', localizedTitle: 'Quick Add')]);
    quickActions.initialize((type) {
      if (type == 'action_add') {
        goCreatePage();
      }
    });
  }

  void initReceiveShareing() {
    if (!Platform.isAndroid) {
      return;
    }
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen(handleSharing, onError: (err) {
      if (kDebugMode) {
        print("getIntentDataStream error: $err");
      }
    });

    // For sharing images coming from outside the app while the app is closed
    FlutterSharingIntent.instance.getInitialSharing().then(handleSharing);
  }

  void handleSharing(List<SharedFile> event) {
    for (var o in event) {
      if ([SharedMediaType.TEXT, SharedMediaType.URL].contains(o.type)) {
        addText(o.value ?? '');
      } else {
        saveAsNew(o.value);
      }
    }
  }

  void initWatchDir() {
    var watcher =
        DirectoryWatcher(dataPath, pollingDelay: const Duration(minutes: 1));
    if (!watcher.isReady) {
      watcher.events.listen((e) {
        fetchItems();
      });
    }
  }

  void fetchItems() {
    final files = Directory(dataPath).listSync();
    files
        .sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    items = files;
    update();
  }

  addText(String text) {
    var file = File('$dataPath/$newName.txt');
    file.writeAsStringSync(text);
    items.add(file);
    update();
  }

  itemMenuSelected(String value, int index) {
    switch (value) {
      case 'Delete':
        deleteItem(index);
        break;
      case 'Copy':
        copyItem(index);
        break;
      case 'Open':
        openItem(index);
        break;
      default:
    }
  }

  void deleteItem(int index) {
    items[index].delete();
    items.removeAt(index);
    update();
  }

  void copyItem(int index) {
    var item = items[index];
    var text = item.path;
    var mime = lookupMimeType(item.path);
    if (mime != null && mime.startsWith('text/')) {
      text = File(item.path).readAsStringSync();
    }
    Clipboard.setData(ClipboardData(text: text));
  }

  void openItem(int index) {
    OpenAppFile.open(items[index].path);
  }

  void saveAsNew(String? path) {
    if (path == null) {
      return;
    }
    var shuffix = path.split('.').last;
    var newPath = '$dataPath/$newName.$shuffix';
    File(path).copySync(newPath);
    items.add(File(newPath));
    update();
  }

  void onItemFocusChange(bool value, int index) {
    if (value) {
      focusIndex = index;
    }
  }

  onListFocusChange(bool value) {
    if (!value) {
      focusIndex = null;
    }
  }

  callShortcut(String s) {
    if (focusIndex != null) {
      itemMenuSelected(s, focusIndex!);
    }
  }
}
