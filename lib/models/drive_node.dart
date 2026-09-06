class DriveNode {
  final String type; // 'folder' or 'file'
  final String id;
  final String name;
  final List<DriveNode> children;

  // Folder-only: direct child count reported by the server for
  // folders that haven't been opened/fetched yet (children is empty
  // in that case, but we still know how many items are inside).
  final int? itemCount;

  // File-only fields
  final String? mimeType;
  final int? sizeBytes;
  final String? modifiedAt;
  final String? viewUrl;
  final String? downloadUrl;

  DriveNode({
    required this.type,
    required this.id,
    required this.name,
    this.children = const [],
    this.itemCount,
    this.mimeType,
    this.sizeBytes,
    this.modifiedAt,
    this.viewUrl,
    this.downloadUrl,
  });

  bool get isFolder => type == 'folder';

  /// Number of items to show on a folder card: the real loaded
  /// children count once fetched, otherwise the server-provided hint.
  int get displayItemCount => children.isNotEmpty ? children.length : (itemCount ?? 0);

  factory DriveNode.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? [];
    return DriveNode(
      type: json['type'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
      children: rawChildren
          .map((c) => DriveNode.fromJson(c as Map<String, dynamic>))
          .toList(),
      itemCount: json['itemCount'] as int?,
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      modifiedAt: json['modifiedAt'] as String?,
      viewUrl: json['viewUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  /// Simple icon hint based on mime type, used by the UI layer.
  String get iconHint {
    if (isFolder) return 'folder';
    final mt = mimeType ?? '';
    if (mt.contains('pdf')) return 'pdf';
    if (mt.contains('image')) return 'image';
    if (mt.contains('presentation')) return 'ppt';
    if (mt.contains('word') || mt.contains('document')) return 'doc';
    if (mt.contains('spreadsheet')) return 'xls';
    return 'file';
  }
}
