import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../services/supabase_service.dart';
import '../services/pdf_generator.dart';

class ReportProvider extends ChangeNotifier {
  List<Report> _reports = [];
  Report? _currentReport;
  List<ReportPhoto> _currentPhotos = [];
  bool _isLoading = false;
  String? _error;
  File? _generatedPdf;
  double _pdfProgress = 0;
  bool _isOffline = false;

  // Getters
  List<Report> get reports => _reports;
  Report? get currentReport => _currentReport;
  List<ReportPhoto> get currentPhotos => _currentPhotos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get generatedPdf => _generatedPdf;
  double get pdfProgress => _pdfProgress;
  bool get isOffline => _isOffline;

  int get totalPhotos => _currentPhotos.length;
  int get photosPerPage => _currentReport?.photosPerPage ?? 8;
  int get totalPages => totalPhotos > 0 ? (totalPhotos / photosPerPage).ceil() : 0;
  int get maxPhotos => 18 * photosPerPage;
  double get progress => maxPhotos > 0 ? totalPhotos / maxPhotos : 0;

  // --- FETCHING ---

  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await SupabaseService.fetchReports();
      _isOffline = false;
    } catch (e) {
      // Supabase not configured or offline — work locally
      _isOffline = true;
      debugPrint('Mode offline: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- REPORT CRUD ---

  Future<bool> createReport({
    required String title,
    required String location,
    required DateTime date,
    required String inspectorName,
    required String referenceId,
    String pemasok = '',
    String namaKapal = '',
    String shipment = '',
    String jobNo = '',
    int photosPerPage = 8,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final report = Report(
        title: title,
        location: location,
        date: date,
        inspectorName: inspectorName,
        referenceId: referenceId,
        photosPerPage: photosPerPage,
        pemasok: pemasok,
        namaKapal: namaKapal,
        shipment: shipment,
        jobNo: jobNo,
      );

      // Try Supabase first, fallback to local
      try {
        _currentReport = await SupabaseService.createReport(report);
        _isOffline = false;
      } catch (_) {
        // Supabase failed — create locally with UUID
        _isOffline = true;
        final localId = const Uuid().v4();
        _currentReport = report.copyWith(id: localId);
      }

      _currentPhotos = [];
      _reports.insert(0, _currentReport!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal membuat laporan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setCurrentReport(Report report) {
    _currentReport = report;
    _currentPhotos = List.from(report.photos);
    _generatedPdf = null;
    notifyListeners();
  }

  Future<void> updatePhotoMetadata(int index, String type, String category) async {
    if (index < _currentPhotos.length) {
      _currentPhotos[index] = _currentPhotos[index].copyWith(
        photoType: type,
        category: category,
      );
      notifyListeners();

      if (!_isOffline) {
        final photoId = _currentPhotos[index].id;
        if (photoId != null) {
          try {
            await SupabaseService.updatePhotoMetadata(photoId, type, category);
          } catch (_) {}
        }
      }
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      if (!_isOffline) {
        await SupabaseService.deleteReport(reportId);
      }
      _reports.removeWhere((r) => r.id == reportId);
      if (_currentReport?.id == reportId) {
        _currentReport = null;
        _currentPhotos = [];
      }
      notifyListeners();
    } catch (e) {
      // Even if Supabase fails, delete locally
      _reports.removeWhere((r) => r.id == reportId);
      notifyListeners();
    }
  }

  // --- PHOTOS ---

  Future<void> pickPhotosFromGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 85);

    if (images.isNotEmpty && _currentReport != null) {
      _isLoading = true;
      notifyListeners();

      for (final image in images) {
        if (totalPhotos >= maxPhotos) break;

        try {
          ReportPhoto photo;
          if (!_isOffline) {
            photo = await SupabaseService.addPhoto(
              reportId: _currentReport!.id!,
              localPath: image.path,
              caption: '',
              orderIndex: _currentPhotos.length,
            );
          } else {
            // Local mode
            photo = ReportPhoto(
              id: const Uuid().v4(),
              reportId: _currentReport!.id,
              localPath: image.path,
              caption: '',
              orderIndex: _currentPhotos.length,
            );
          }
          _currentPhotos.add(photo);
        } catch (e) {
          // Fallback to local if Supabase upload fails
          final photo = ReportPhoto(
            id: const Uuid().v4(),
            reportId: _currentReport!.id,
            localPath: image.path,
            caption: '',
            orderIndex: _currentPhotos.length,
          );
          _currentPhotos.add(photo);
        }
      }

      _updateReportPhotos();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickPhotoFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);

    if (image != null && _currentReport != null) {
      _isLoading = true;
      notifyListeners();

      try {
        ReportPhoto photo;
        if (!_isOffline) {
          photo = await SupabaseService.addPhoto(
            reportId: _currentReport!.id!,
            localPath: image.path,
            caption: '',
            orderIndex: _currentPhotos.length,
          );
        } else {
          photo = ReportPhoto(
            id: const Uuid().v4(),
            reportId: _currentReport!.id,
            localPath: image.path,
            caption: '',
            orderIndex: _currentPhotos.length,
          );
        }
        _currentPhotos.add(photo);
        _updateReportPhotos();
      } catch (e) {
        // Fallback to local
        final photo = ReportPhoto(
          id: const Uuid().v4(),
          reportId: _currentReport!.id,
          localPath: image.path,
          caption: '',
          orderIndex: _currentPhotos.length,
        );
        _currentPhotos.add(photo);
        _updateReportPhotos();
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCaption(int index, String caption) async {
    if (index < _currentPhotos.length) {
      _currentPhotos[index] = _currentPhotos[index].copyWith(caption: caption);
      notifyListeners();

      if (!_isOffline) {
        final photoId = _currentPhotos[index].id;
        if (photoId != null) {
          try {
            await SupabaseService.updatePhotoCaption(photoId, caption);
          } catch (_) {}
        }
      }
    }
  }

  Future<void> removePhoto(int index) async {
    if (index < _currentPhotos.length) {
      final photo = _currentPhotos[index];
      _currentPhotos.removeAt(index);

      // Re-index all photos
      for (int i = 0; i < _currentPhotos.length; i++) {
        _currentPhotos[i] = _currentPhotos[i].copyWith(orderIndex: i);
      }

      _updateReportPhotos();
      notifyListeners();

      if (!_isOffline && photo.id != null) {
        try {
          await SupabaseService.deletePhoto(photo.id!, photo.storageUrl);
          await SupabaseService.updatePhotoOrder(_currentPhotos);
        } catch (_) {}
      }
    }
  }

  void setPhotosPerPage(int count) {
    if (_currentReport != null) {
      _currentReport = _currentReport!.copyWith(photosPerPage: count);
      notifyListeners();
    }
  }

  void _updateReportPhotos() {
    if (_currentReport != null) {
      _currentReport = _currentReport!.copyWith(photos: List.from(_currentPhotos));
      final idx = _reports.indexWhere((r) => r.id == _currentReport!.id);
      if (idx >= 0) {
        _reports[idx] = _currentReport!;
      }
    }
  }

  // --- PDF GENERATION ---

  Future<File?> generatePdf() async {
    if (_currentReport == null || _currentPhotos.isEmpty) return null;

    _isLoading = true;
    _pdfProgress = 0;
    notifyListeners();

    try {
      final report = _currentReport!.copyWith(photos: List.from(_currentPhotos));
      _generatedPdf = await PdfGenerator.generateReport(report);

      // Update status to completed
      _currentReport = _currentReport!.copyWith(status: 'completed');
      if (!_isOffline) {
        try {
          await SupabaseService.updateReport(_currentReport!);
        } catch (_) {}
      }
      _updateReportPhotos();

      _isLoading = false;
      notifyListeners();
      return _generatedPdf;
    } catch (e) {
      _error = 'Gagal generate PDF: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
