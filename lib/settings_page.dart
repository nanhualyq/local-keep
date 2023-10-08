import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_keep/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: SettingsController(),
        builder: (_) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Settings'),
              actions: [
                IconButton(
                    onPressed: _.submitForm, icon: const Icon(Icons.save))
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _.pathController,
                      decoration: InputDecoration(
                          labelText: 'data path',
                          helperText: 'defalut is ApplicationSupportDirectory',
                          suffixIcon: IconButton(
                              onPressed: _.pickDir,
                              icon: const Icon(Icons.more_horiz))),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'data path is required!';
                        }
                        if (!FileSystemEntity.isDirectorySync(value)) {
                          return 'data path must be a directory!';
                        }
                        return null;
                      },
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
