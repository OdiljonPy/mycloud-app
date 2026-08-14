class MediaTypeHelper {
  MediaTypeHelper._();

  static bool isImage(String mimeType) =>
      mimeType.toLowerCase().startsWith('image/');

  static bool isVideo(String mimeType) =>
      mimeType.toLowerCase().startsWith('video/');
}
