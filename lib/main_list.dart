import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:open_app_file/open_app_file.dart';

class MainList extends StatelessWidget {
  final List<FileSystemEntity> items;
  final void Function(String, int) menuSelected;

  const MainList({super.key, required this.items, required this.menuSelected});

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
            onSelected: (value) => menuSelected(value, index),
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
        );
      },
    );
  }

  Widget makeTitle(FileSystemEntity item, String? mime) {
    final type = mime != null ? mime.split('/').first : 'other';
    if (type == 'text') {
      return showText(item);
    }
    return showFilePath(item);
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

  final iconMap = const {
    'text': Icons.text_fields,
    'audio': Icons.audio_file,
    'other': Icons.question_mark
  };

  Icon makeLeading(String? mime) {
    final type = mime != null ? mime.split('/').first : 'other';
    return Icon(iconMap[type]);
  }
}