import 'dart:typed_data';

class Report {
  final String? id;
  final String title;
  final String location;
  final DateTime date;
  final String inspectorName;
  final String referenceId;
  final int photosPerPage;
  final int targetPages; // New field for total documentation pages
  final String status; // 'draft', 'completed', 'exported'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ReportPhoto> photos;

  // New Fields for Cover
  final String pemasok;
  final String namaKapal;
  final String shipment;
  final String jobNo;

  Report({
    this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.inspectorName,
    required this.referenceId,
    this.photosPerPage = 8,
    this.targetPages = 12, // Default 12 pages
    this.status = 'draft',
    DateTime? createdAt,
    this.updatedAt,
    this.photos = const [],
    this.pemasok = '',
    this.namaKapal = '',
    this.shipment = '',
    this.jobNo = '',
  }) : createdAt = createdAt ?? DateTime.now();

  Report copyWith({
    String? id,
    String? title,
    String? location,
    DateTime? date,
    String? inspectorName,
    String? referenceId,
    int? photosPerPage,
    int? targetPages,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ReportPhoto>? photos,
    String? pemasok,
    String? namaKapal,
    String? shipment,
    String? jobNo,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      inspectorName: inspectorName ?? this.inspectorName,
      referenceId: referenceId ?? this.referenceId,
      photosPerPage: photosPerPage ?? this.photosPerPage,
      targetPages: targetPages ?? this.targetPages,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
      pemasok: pemasok ?? this.pemasok,
      namaKapal: namaKapal ?? this.namaKapal,
      shipment: shipment ?? this.shipment,
      jobNo: jobNo ?? this.jobNo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'location': location,
      'date': date.toIso8601String(),
      'inspector_name': inspectorName,
      'reference_id': referenceId,
      'photos_per_page': photosPerPage,
      'target_pages': targetPages,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'pemasok': pemasok,
      'nama_kapal': namaKapal,
      'shipment': shipment,
      'job_no': jobNo,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map, {List<ReportPhoto>? photos}) {
    return Report(
      id: map['id'],
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      date: DateTime.parse(map['date']),
      inspectorName: map['inspector_name'] ?? '',
      referenceId: map['reference_id'] ?? '',
      photosPerPage: map['photos_per_page'] ?? 8,
      targetPages: map['target_pages'] ?? 12,
      status: map['status'] ?? 'draft',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      photos: photos ?? [],
      pemasok: map['pemasok'] ?? '',
      namaKapal: map['nama_kapal'] ?? '',
      shipment: map['shipment'] ?? '',
      jobNo: map['job_no'] ?? '',
    );
  }

  int get totalPages => targetPages;
  int get totalPhotos => photos.length;
  int get maxPhotos => targetPages * 8; 
}

class ReportPhoto {
  final String? id;
  final String? reportId;
  final String localPath;
  final String? storageUrl;
  final String caption;
  final String customLabel; // New field for manual label (left side)
  final int orderIndex;
  final Uint8List? bytes; 

  // Fields for Categorization (mostly deprecated now but kept for compatibility)
  final String photoType; // 'form' or 'documentation'
  final String category;  // 'Draught Survey', 'Sampling', 'Preparasi'
  final bool isFullWidth; // To match IV-D (1 vs 2 photos per row)

  ReportPhoto({
    this.id,
    this.reportId,
    required this.localPath,
    this.storageUrl,
    this.caption = '',
    this.customLabel = '',
    required this.orderIndex,
    this.bytes,
    this.photoType = 'documentation',
    this.category = 'Draught Survey',
    this.isFullWidth = false,
  });

  ReportPhoto copyWith({
    String? id,
    String? reportId,
    String? localPath,
    String? storageUrl,
    String? caption,
    String? customLabel,
    int? orderIndex,
    Uint8List? bytes,
    String? photoType,
    String? category,
    bool? isFullWidth,
  }) {
    return ReportPhoto(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      localPath: localPath ?? this.localPath,
      storageUrl: storageUrl ?? this.storageUrl,
      caption: caption ?? this.caption,
      customLabel: customLabel ?? this.customLabel,
      orderIndex: orderIndex ?? this.orderIndex,
      bytes: bytes ?? this.bytes,
      photoType: photoType ?? this.photoType,
      category: category ?? this.category,
      isFullWidth: isFullWidth ?? this.isFullWidth,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (reportId != null) 'report_id': reportId,
      'local_path': localPath,
      'storage_url': storageUrl,
      'caption': caption,
      'custom_label': customLabel,
      'order_index': orderIndex,
      'photo_type': photoType,
      'category': category,
      'is_full_width': isFullWidth,
    };
  }

  factory ReportPhoto.fromMap(Map<String, dynamic> map) {
    return ReportPhoto(
      id: map['id'],
      reportId: map['report_id'],
      localPath: map['local_path'] ?? '',
      storageUrl: map['storage_url'],
      caption: map['caption'] ?? '',
      customLabel: map['custom_label'] ?? '',
      orderIndex: map['order_index'] ?? 0,
      photoType: map['photo_type'] ?? 'documentation',
      category: map['category'] ?? 'Draught Survey',
      isFullWidth: map['is_full_width'] ?? false,
    );
  }
}
