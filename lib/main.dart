import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:local_keep/settings.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    fetchItems();
    _txtController = TextEditingController();
    if (Platform.isAndroid) {
      receiveShareingListener();
    }
  }

  @override
  void dispose() {
    _txtController.dispose();
    if (Platform.isAndroid) {
      _intentDataStreamSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):() {
          fetchItems();
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):() {
          quickCreate(context);
        }
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
            actions: [
              IconButton(onPressed: fetchItems, icon: const Icon(Icons.refresh)),
              IconButton(onPressed: setDataPath, icon: const Icon(Icons.settings)),
            ],
          ),
          body: ListView.builder(
            itemCount: items.length,
            // prototypeItem: ListTile(
            //   title: Text(itemsfirst.path),
            // ),
            itemBuilder: (context, index) {
              var item = items[index];
              return ListTile(
                leading: const Icon(Icons.text_fields),
                title: Text(
                  File(item.path).readAsStringSync(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
                // subtitle: Text(items[index].path),
                // subtitleTextStyle: const TextStyle(color: Colors.black26),
                // isThreeLine: true,
                trailing: PopupMenuButton(
                  onSelected: (value) {
                    switch (value) {
                      case 'Delete':
                        deleteItem(index);
                        break;
                      default:
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem(
                        value: 'Delete',
                        child: Text('Delete'),
                      )
                    ];
                  },
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => quickCreate(context),
            tooltip: 'Add',
            child: const Icon(Icons.add),
          ), // This trailing comma makes auto-formatting nicer for build methods.
        ),
      ),
    );
  }

  Future<void> addTxt(String text) async {
    final dataPath = await Settings.getDataPath();
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    String filePath = '${dataPath!}/$time.txt';
    var myFile = File(filePath);
    myFile.writeAsStringSync(text);
    _txtController.clear();
    fetchItems();
  }

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

  quickCreate(BuildContext context) async {
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
                  SimpleDialogOption(
                    onPressed: checkContent,
                    child: const Icon(Icons.add_task),
                  ),
                ],
              ),
            ],
          );
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
}
