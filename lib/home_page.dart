import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_keep/home_controller.dart';
import 'package:local_keep/settings_page.dart';
import 'package:mime/mime.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
        init: HomeController(),
        builder: (_) {
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyR, control: true):
                  _.fetchItems,
              const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                  _.goCreatePage,
              const SingleActivator(LogicalKeyboardKey.keyC, control: true):
                  () => _.callShortcut('Copy'),
              const SingleActivator(LogicalKeyboardKey.delete): () =>
                  _.callShortcut('Delete'),
              const SingleActivator(LogicalKeyboardKey.enter): () =>
                  _.callShortcut('Open')
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                appBar: AppBar(title: const Text('Local Keep'), actions: [
                  IconButton(
                    onPressed: _.fetchItems,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                  IconButton(
                    onPressed: () => Get.to(() => const SettingsPage()),
                    icon: const Icon(Icons.settings),
                    tooltip: 'Settings',
                  ),
                ]),
                body: Focus(
                  onFocusChange: (value) => _.onListFocusChange(value),
                  child: ListView.builder(
                    itemCount: _.items.length,
                    itemBuilder: (context, index) {
                      var item = _.items[index];
                      var mime = lookupMimeType(item.path);
                      return ListTile(
                        leading: makeLeading(mime),
                        title: makeTitle(item, mime),
                        trailing: PopupMenuButton(
                          onSelected: (value) =>
                              _.itemMenuSelected(value, index),
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem(
                                value: 'Copy',
                                child: Text('Copy'),
                              ),
                              const PopupMenuItem(
                                value: 'Delete',
                                child: Text('Delete'),
                              )
                            ];
                          },
                        ),
                        onTap: () => _.openItem(index),
                        onFocusChange: (value) =>
                            _.onItemFocusChange(value, index),
                      );
                    },
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: _.goCreatePage,
                  tooltip: 'Add (Ctrl+N)',
                  child: const Icon(Icons.add),
                ), //
              ),
            ),
          );
        });
  }

  final iconMap = const {
    'text': Icons.text_fields,
    'audio': Icons.audio_file,
    'image': Icons.photo,
    'video': Icons.video_file,
    'other': Icons.question_mark
  };

  Icon makeLeading(String? mime) {
    final type = mime != null ? mime.split('/').first : 'other';
    return Icon(iconMap[type] ?? iconMap['other']);
  }

  Widget makeTitle(FileSystemEntity item, String? mime) {
    final type = mime != null ? mime.split('/').first : 'other';
    if (mime == 'text/plain') {
      return showText(item);
    } else if (type == 'image') {
      return showImage(item);
    }
    return showFilePath(item);
  }

  Widget showImage(FileSystemEntity item) {
    return ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 200,
        ),
        child: Image.file(
          File(item.path),
          alignment: Alignment.centerLeft,
        ));
  }

  Text showFilePath(FileSystemEntity item) {
    return Text(item.path);
  }

  Text showText(FileSystemEntity item) {
    return Text(
      File(item.path).readAsStringSync(),
      overflow: TextOverflow.ellipsis,
      maxLines: 3,
    );
  }
}
