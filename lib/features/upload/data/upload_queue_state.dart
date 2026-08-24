import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

// paused = сеть пропала, авто-резюм; pausedByUser = юзер сам поставил на
// паузу конкретный файл через кнопку — разные состояния, разный UI.
enum UploadFileStatus {
  waiting,
  uploading,
  paused,
  pausedByUser,
  done,
  error,
  cancelled,
}

class UploadFileItem {
  final String id;
  final XFile file;
  final String name;
  UploadFileStatus status;
  double progress;
  String? error;
  bool cancelRequested;

  UploadFileItem({
    required this.file,
    required this.name,
    // ignore: unused_element_parameter
    this.status = UploadFileStatus.waiting,
    // ignore: unused_element_parameter
    this.progress = 0,
    // ignore: unused_element_parameter
    this.error,
    // ignore: unused_element_parameter
    this.cancelRequested = false,
  }) : id = const Uuid().v4();
}
