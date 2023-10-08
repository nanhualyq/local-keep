import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_keep/create_controller.dart';

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: CreateController(),
        builder: (_) {
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _.leavePage,
              const SingleActivator(LogicalKeyboardKey.enter, control: true):
                  _.addText,
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Add'),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: Form(
                          key: _.formKey,
                          child: TextFormField(
                            controller: _.textController,
                            decoration: const InputDecoration(
                                // icon: Icon(Icons.text_fields),
                                border: OutlineInputBorder(),
                                hintText: 'Enter your ideas'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                            minLines: null,
                            maxLines: null,
                            expands: true,
                            autofocus: true,
                          )),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            children: [
                              if (_.isRecording)
                                TextButton(
                                    onPressed: _.stopRecord,
                                    child: const CircularProgressIndicator())
                              else
                                IconButton(
                                    onPressed: _.startRecord,
                                    icon: const Icon(
                                        Icons.keyboard_voice_outlined)),
                              IconButton(
                                onPressed: _.addPhoto,
                                icon: const Icon(Icons.camera_alt_outlined),
                              ),
                              IconButton(
                                onPressed: _.addVideo,
                                icon: const Icon(Icons.videocam_outlined),
                              ),
                              IconButton(
                                onPressed: _.addFiles,
                                icon: const Icon(Icons.attach_file),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                            tooltip: 'Save Text (Ctrl+Enter)',
                            iconSize: 30,
                            color: Colors.blue,
                            onPressed: _.addText,
                            icon: const Icon(Icons.done))
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
