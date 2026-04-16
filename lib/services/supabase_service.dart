import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // --- REPORTS ---

  static Future<List<Report>> fetchReports() async {
    final response = await client
        .from('reports')
        .select()
        .order('created_at', ascending: false);

    final reports = <Report>[];
    for (final row in response as List) {
      final photosResponse = await client
          .from('report_photos')
          .select()
          .eq('report_id', row['id'])
          .order('order_index');

      final photos = (photosResponse as List)
          .map((p) => ReportPhoto.fromMap(p))
          .toList();

      reports.add(Report.fromMap(row, photos: photos));
    }
    return reports;
  }

  static Future<Report> createReport(Report report) async {
    final response = await client
        .from('reports')
        .insert(report.toMap())
        .select()
        .single();

    return Report.fromMap(response);
  }

  static Future<void> updateReport(Report report) async {
    await client
        .from('reports')
        .update(report.toMap())
        .eq('id', report.id!);
  }

  static Future<void> deleteReport(String reportId) async {
    // Delete photos from storage first
    final photos = await client
        .from('report_photos')
        .select()
        .eq('report_id', reportId);

    for (final photo in photos as List) {
      if (photo['storage_url'] != null) {
        final path = _extractStoragePath(photo['storage_url']);
        if (path != null) {
          await client.storage.from('report-photos').remove([path]);
        }
      }
    }

    // Delete photo records
    await client.from('report_photos').delete().eq('report_id', reportId);

    // Delete report
    await client.from('reports').delete().eq('id', reportId);
  }

  // --- PHOTOS ---

  static Future<ReportPhoto> addPhoto({
    required String reportId,
    required String localPath,
    required String caption,
    required int orderIndex,
    String photoType = 'documentation',
    String category = 'Draught Survey',
    bool isFullWidth = false,
    String customLabel = '',
  }) async {
    // Upload to Supabase Storage
    final file = File(localPath);
    final fileName = '$reportId/${DateTime.now().millisecondsSinceEpoch}_$orderIndex.jpg';

    await client.storage
        .from('report-photos')
        .upload(fileName, file);

    final storageUrl = client.storage
        .from('report-photos')
        .getPublicUrl(fileName);

    // Insert photo record
    final response = await client
        .from('report_photos')
        .insert({
          'report_id': reportId,
          'local_path': localPath,
          'storage_url': storageUrl,
          'caption': caption,
          'custom_label': customLabel,
          'order_index': orderIndex,
          'photo_type': photoType,
          'category': category,
          'is_full_width': isFullWidth,
        })
        .select()
        .single();

    return ReportPhoto.fromMap(response);
  }

  static Future<void> updatePhotoMetadata(String photoId, String photoType, String category, bool isFullWidth, String customLabel) async {
    await client
        .from('report_photos')
        .update({
          'photo_type': photoType,
          'category': category,
          'is_full_width': isFullWidth,
          'custom_label': customLabel,
        })
        .eq('id', photoId);
  }

  static Future<void> updatePhotoCaption(String photoId, String caption) async {
    await client
        .from('report_photos')
        .update({'caption': caption})
        .eq('id', photoId);
  }

  static Future<void> deletePhoto(String photoId, String? storageUrl) async {
    if (storageUrl != null) {
      final path = _extractStoragePath(storageUrl);
      if (path != null) {
        try {
          await client.storage.from('report-photos').remove([path]);
        } catch (_) {
          // Ignore storage errors
        }
      }
    }
    await client.from('report_photos').delete().eq('id', photoId);
  }

  static Future<void> updatePhotoOrder(List<ReportPhoto> photos) async {
    for (final photo in photos) {
      if (photo.id != null) {
        await client
            .from('report_photos')
            .update({'order_index': photo.orderIndex})
            .eq('id', photo.id!);
      }
    }
  }

  // --- HELPERS ---

  static String? _extractStoragePath(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('report-photos');
      if (bucketIndex >= 0 && bucketIndex < segments.length - 1) {
        return segments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
