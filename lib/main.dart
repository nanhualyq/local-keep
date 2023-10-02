import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:local_keep/main_list.dart';
import 'package:local_keep/settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:record/record.dart';

const title = 'Local Keep';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey.shade900),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<FileSystemEntity> items = [];
  late TextEditingController _txtController;
  late StreamSubscription _intentDataStreamSubscription;
  final Record record = Record();
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    fetchItems();
    _txtController = TextEditingController();
    if (Platform.isAndroid) {
      receiveShareingListener();
      initQuickActions();
    }
  }

  @override
  void dispose() {
    _txtController.dispose();
    if (Platform.isAndroid) {
      _intentDataStreamSubscription.cancel();
    }
    record.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): () {
          fetchItems();
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          quickCreate();
        }
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
            actions: [
              IconButton(
                  onPressed: fetchItems, icon: const Icon(Icons.refresh)),
              IconButton(
                  onPressed: setDataPath, icon: const Icon(Icons.settings)),
            ],
          ),
          body: MainList(
            items: items,
            menuSelected: menuSelected,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => quickCreate(),
            tooltip: 'Add',
            child: const Icon(Icons.add),
          ), // This trailing comma makes auto-formatting nicer for build methods.
        ),
      ),
    );
  }

  Future<void> addTxt(String text) async {
    final dataPath = await Settings.getDataPath();
    String filePath = '${dataPath!}/${makeNewFileName()}.txt';
    var myFile = File(filePath);
    myFile.writeAsStringSync(text);
    _txtController.clear();
    fetchItems();
  }

  String makeNewFileName() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> fetchItems() async {
    String? dataPath = await Settings.getDataPath();
    if (dataPath == null) {
      return;
    }
    final files = Directory(dataPath).listSync();
    if (files.isEmpty) {
      try {
        File('$dataPath/.checkPermission')
          ..writeAsStringSync('')
          ..deleteSync();
      } on PathAccessException catch (e) {
        if (e.osError?.errorCode == 1 && Platform.isAndroid) {
          await Permission.manageExternalStorage.request();
        }
      }
    }
    files
        .sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    setState(() {
      items = files;
    });
  }

  quickCreate() async {
    void checkContent() {
      if (_txtController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Content is empty!")));
        return;
      }
      Navigator.pop(context, 'save');
    }

    var res = await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return SimpleDialog(
              title: TextField(
                controller: _txtController,
                focusNode: FocusNode(
                  onKey: (FocusNode node, RawKeyEvent event) {
                    if (event.isControlPressed &&
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      checkContent();
                      if (event is RawKeyDownEvent) {
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                ),
                minLines: 1,
                maxLines: 10,
                autofocus: true,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SimpleDialogOption(
                            onPressed: () => setState(() {
                              isRecording = !isRecording;
                              recordVoice();
                            }),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.keyboard_voice_outlined),
                                if (isRecording)
                                  const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        semanticsValue: 'Recording',
                                        strokeWidth: 1,
                                      )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SimpleDialogOption(
                      onPressed: checkContent,
                      child: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            );
          });
        });
    if (res == 'save') {
      addTxt(_txtController.text);
    }
  }

  Future<void> setDataPath() async {
    await Settings.setDataPath();
    fetchItems();
  }

  void deleteItem(int index) {
    items[index].deleteSync();
    fetchItems();
  }

  void receiveShareingListener() {
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
        addTxt(o.value ?? '');
      }
    }
  }

  void initQuickActions() {
    const QuickActions quickActions = QuickActions();
    quickActions.setShortcutItems(
        [const ShortcutItem(type: 'action_add', localizedTitle: 'Quick Add')]);
    quickActions.initialize((type) {
      if (type == 'action_add') {
        quickCreate();
      }
    });
  }

  void recordVoice() async {
    if (Platform.isLinux) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Linux cannot work for now!"),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (await record.isRecording()) {
      // Stop recording
      await record.stop();
      if (context.mounted) {
        Navigator.pop(context);
        fetchItems();
      }
      return;
    }

    // Check and request permission
    if (await record.hasPermission()) {
      final dataPath = await Settings.getDataPath();
      // Start recording
      await record.start(
        path: '${dataPath!}/${makeNewFileName()}.m4a',
        // encoder: AudioEncoder.aacLc, // by default
        // bitRate: 128000, // by default
        // samplingRate: 44100, // by default
      );
    }
  }

  void menuSelected(String value, int index) {
    switch (value) {
      case 'Delete':
        deleteItem(index);
        break;
      default:
    }
  }
}
