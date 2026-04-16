import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/report_model.dart';

class PdfGenerator {
  static Future<File> generateReport(Report report) async {
    final pdf = pw.Document();
    
    // 1. Pre-load and separate photos
    final List<ReportPhoto> formPhotos = [];
    final List<ReportPhoto> documentationPhotos = [];

    final sortedPhotos = List<ReportPhoto>.from(report.photos);
    sortedPhotos.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (final photo in sortedPhotos) {
      final file = File(photo.localPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final loadedPhoto = photo.copyWith(bytes: bytes);
        
        if (photo.photoType == 'form') {
          formPhotos.add(loadedPhoto);
        } else {
          documentationPhotos.add(loadedPhoto);
        }
      }
    }

    // 2. Page 1: COVER
    pdf.addPage(_buildCoverPage(report));

    // 3. Page 2-11: DOCUMENTS (FORM) - Exactly 10 pages
    // One photo per page
    for (int i = 0; i < 10; i++) {
      final photo = i < formPhotos.length ? formPhotos[i] : null;
      pdf.addPage(_buildDocumentPage(photo, i + 2, report));
    }

    // 4. Page 12+: DYNAMIC DOCUMENTATION PAGES
    // We generate exactly the number of pages requested by the user
    int photoIdx = 0;
    int totalDocs = documentationPhotos.length;

    for (int pIdx = 0; pIdx < report.targetPages; pIdx++) {
      final List<_PageRowData> pageRows = [];
      
      // Each page has 4 slots (rows)
      for (int r = 0; r < 4; r++) {
        ReportPhoto? p1;
        ReportPhoto? p2;
        int displayIdx = photoIdx;

        if (photoIdx < totalDocs) {
          p1 = documentationPhotos[photoIdx++];
          // If NOT full width and there's another photo, and that next photo is also NOT full width
          if (!p1.isFullWidth && photoIdx < totalDocs && !documentationPhotos[photoIdx].isFullWidth) {
            p2 = documentationPhotos[photoIdx++];
          }
        }
        
        final label = p1?.customLabel.isNotEmpty == true 
            ? p1!.customLabel 
            : (p1 == null ? 'Lain-lain' : 'Dokumentasi Lapangan');

        pageRows.add(_PageRowData(
          label: label, 
          p1: p1, 
          p2: p2, 
          baseIdx: displayIdx + 1
        ));
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => pw.Column(
            children: [
              pw.Center(child: pw.Text('LAMPIRAN DOKUMENTASI', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text(report.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(110), 
                  1: const pw.FlexColumnWidth(), 
                  2: const pw.FixedColumnWidth(110)
                },
                children: pageRows.map((row) {
                  if (row.p1 != null && row.p1!.isFullWidth) {
                    return pw.TableRow(
                      children: [
                        _buildLabelCell(row.label),
                        _buildSinglePhotoCell(row.p1!, row.baseIdx),
                        _buildKeteranganCell(row.p1),
                      ],
                    );
                  } else {
                    return pw.TableRow(
                      children: [
                        _buildLabelCell(row.label),
                        _buildPhotoPairCell(row.p1, row.p2, row.baseIdx),
                        _buildKeteranganCell(row.p1),
                      ],
                    );
                  }
                }).toList(),
              ),
              
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ID: ${report.referenceId}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('Tgl: ${_formatDate(report.date)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('Halaman ${pIdx + 12}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Save to file
    final outputDir = await getApplicationDocumentsDirectory();
    final sanitizedRef = report.referenceId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final fileName = 'Laporan_${sanitizedRef}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Page _buildCoverPage(Report report) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(50),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(height: 50),
            pw.Text('LAPORAN KEGIATAN PENGAWASAN', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('KUANTITAS DAN KUALITAS BATUBARA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Spacer(),
            
            // Image Placeholder
            pw.Container(
              height: 250,
              width: 350,
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 2)),
              alignment: pw.Alignment.center,
              child: pw.Text('DOKUMENTASI UTAMA', style: const pw.TextStyle(color: PdfColors.grey400)),
            ),
            
            pw.Spacer(),
            
            // Info Table
            pw.Table(
              columnWidths: {0: const pw.FixedColumnWidth(150), 1: const pw.FlexColumnWidth()},
              children: [
                _buildCoverRow('PEMASOK', report.pemasok),
                _buildCoverRow('NAMA KAPAL', report.namaKapal),
                _buildCoverRow('SHIPMENT', report.shipment),
                _buildCoverRow('JOB NO', report.jobNo),
              ],
            ),
            pw.SizedBox(height: 50),
            pw.Divider(),
            pw.Text('Tanggal Laporan: ${_formatDate(report.date)}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _buildCoverRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8), child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8), child: pw.Text(': $value')),
      ],
    );
  }

  static pw.Page _buildDocumentPage(ReportPhoto? photo, int pageNum, Report report) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        children: [
          pw.Text('DOKUMEN PENDUKUNG (Halaman $pageNum)', 
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
          if (photo?.bytes != null)
            pw.Expanded(
              child: pw.Center(
                child: pw.Image(
                  pw.MemoryImage(photo!.bytes!), 
                  fit: pw.BoxFit.contain,
                ),
              ),
            )
          else
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey200, style: pw.BorderStyle.dashed),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text('SLOT DOKUMEN KOSONG', 
                  style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 16)),
              ),
            ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ID: ${report.referenceId}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              pw.Text('Dokumen Pendukung', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLabelCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      height: 165,
      alignment: pw.Alignment.topLeft,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildSinglePhotoCell(ReportPhoto photo, int index) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: _buildPhotoBox(photo, index, isLarge: true),
    );
  }

  static pw.Widget _buildPhotoPairCell(ReportPhoto? p1, ReportPhoto? p2, int baseIdx) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _buildPhotoBox(p1, baseIdx),
          pw.SizedBox(width: 8),
          _buildPhotoBox(p2, baseIdx + 1),
        ],
      ),
    );
  }

  static pw.Widget _buildPhotoBox(ReportPhoto? photo, int index, {bool isLarge = false}) {
    return pw.Container(
      width: isLarge ? 240 : 110,
      height: 145,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
        color: photo?.bytes == null ? PdfColors.grey100 : null,
      ),
      child: photo?.bytes != null
          ? pw.Image(pw.MemoryImage(photo!.bytes!), fit: pw.BoxFit.cover)
          : pw.Center(child: pw.Text('SLOT ${index.toString().padLeft(2, '0')}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400))),
    );
  }

  static pw.Widget _buildKeteranganCell(ReportPhoto? photo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Keterangan', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('................', style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 8),
          pw.Text('................', style: const pw.TextStyle(fontSize: 9)),
          if (photo?.caption.isNotEmpty ?? false)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(photo!.caption, style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _PageRowData {
  final String label;
  final ReportPhoto? p1;
  final ReportPhoto? p2;
  final int baseIdx;

  _PageRowData({required this.label, this.p1, this.p2, required this.baseIdx});
}
