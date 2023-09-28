import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const dataPath = 'data_path';

class Settings {
  static SharedPreferences? spIns;

  static Future<SharedPreferences> getSpIns() async {
    if (spIns != null) {
      return Future.value(spIns);
    }
    return SharedPreferences.getInstance();
  }  
  
  static getDataPath() async {
    final SharedPreferences prefs = await getSpIns();
    String? path = prefs.getString(dataPath);
    if (path == null || path.isEmpty) {
      return setDataPath();
    }
    return path;
  }

  static setDataPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      // User canceled the picker
      return;
    }

    final SharedPreferences prefs = await getSpIns();
    await prefs.setString(dataPath, selectedDirectory);
    return selectedDirectory;
  }
}
