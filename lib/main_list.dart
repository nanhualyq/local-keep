import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_keep/main_obs.dart';
import 'package:mime/mime.dart';
import 'package:open_app_file/open_app_file.dart';

class MainList extends StatelessWidget {
  final List<FileSystemEntity> items;

  const MainList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        var item = items[index];
        var mime = lookupMimeType(item.path);
        return ListTile(
          leading: makeLeading(mime),
          title: makeTitle(item, mime),
          trailing: PopupMenuButton(
            onSelected: (value) => MainObs.shortcutStatus.value =
                '$value/$index/${DateTime.now()}',
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'Delete',
                  child: Text('Delete'),
                )
              ];
            },
          ),
          onTap: () => OpenAppFile.open(item.path),
          onFocusChange: (value) {
            if (value) {
              MainObs.focusItemIndex.value = index;
            } else if (index == MainObs.focusItemIndex.value) {
              MainObs.focusItemIndex.value = -1;
            }
          },
        );
      },
    );
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
    return Icon(iconMap[type]);
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
