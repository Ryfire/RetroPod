class NoteFileModel {
  final String path;
  final String name;
  final DateTime? dateModified;
  final int fileSize;

  const NoteFileModel({
    required this.path,
    required this.name,
    this.dateModified,
    required this.fileSize,
  });
}
