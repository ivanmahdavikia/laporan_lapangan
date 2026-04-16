import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/report_model.dart';

class PdfGenerator {
  static Future<File> generateReport(Report report) async {
    final pdf = pw.Document();
    
    // 1. Pre-load and categorize photos
    final List<ReportPhoto> formPhotos = [];
    final List<ReportPhoto> draughtPhotos = [];
    final List<ReportPhoto> samplingPhotos = [];
    final List<ReportPhoto> preparasiPhotos = [];

    for (final photo in report.photos) {
      final file = File(photo.localPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final loadedPhoto = photo.copyWith(bytes: bytes);
        
        if (photo.photoType == 'form') {
          formPhotos.add(loadedPhoto);
        } else {
          switch (photo.category) {
            case 'Sampling':
              samplingPhotos.add(loadedPhoto);
              break;
            case 'Preparasi':
              preparasiPhotos.add(loadedPhoto);
              break;
            default:
              draughtPhotos.add(loadedPhoto);
          }
        }
      }
    }

    // 2. Page 1: COVER
    pdf.addPage(_buildCoverPage(report));

    // 3. Page 2-11: DOCUMENTS (FORM)
    // Client wants exactly pages 2-11 for documents (up to 10 photos)
    for (int i = 0; i < 10; i++) {
      final photo = i < formPhotos.length ? formPhotos[i] : null;
      pdf.addPage(_buildDocumentPage(photo, i + 2));
    }

    // 4. Page 12+: DOCUMENTATION
    int currentPageNum = 12;

    // LAMPIRAN I: Draught Survey
    final draughtLabels = [
      'Kondisi Vessel / Tongkang (Visual Check)',
      'Kondisi Batubara di Vessel / Tongkang',
      'Kondisi Pembongkaran',
      'Kondisi Pembongkaran',
    ];
    currentPageNum = _addDocumentationPages(
      pdf, 
      draughtPhotos, 
      draughtLabels, 
      'Lampiran I', 
      'Draught Survey & Kondisi Vessel', 
      currentPageNum, 
      report
    );

    // LAMPIRAN II: Sampling
    final samplingLabels = [
      'Pengambilan Sample',
      'Proses Penyegelan Sample',
      'Hasil Proses Sampling',
      'Proses Penurunan Sample',
    ];
    currentPageNum = _addDocumentationPages(
      pdf, 
      samplingPhotos, 
      samplingLabels, 
      'Lampiran II', 
      'Sampling', 
      currentPageNum, 
      report
    );

    // LAMPIRAN III: Preparasi
    final preparasiLabels = [
      'Crushing 4,75 mESH',
      'RSD (Pengambilan 1/8 Sample)',
      'Sample 1/8 Crusher jadi 4,75 mm',
      'Packing 4,75 Basah',
      'Penentuan ADL Awal',
      'Penentuan ADL Akhir',
      'Formulir ADL',
      'Packing 4,75 Kering',
      'RSD dari sample (TM + GA 4kg)',
      'Crusher 0,212 mm (mess 60)',
      'Packing Mess 60',
      'Penentuan RM',
      'Penentuan TM',
      'Segel Umpire Sample',
    ];
    currentPageNum = _addDocumentationPages(
      pdf, 
      preparasiPhotos, 
      preparasiLabels, 
      'Lampiran III', 
      'Preparasi', 
      currentPageNum, 
      report
    );

    // Save to file
    final outputDir = await getApplicationDocumentsDirectory();
    final fileName = 'Laporan_${report.referenceId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  static pw.Page _buildDocumentPage(ReportPhoto? photo, int pageNum) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        children: [
          pw.SizedBox(height: 24),
          pw.Text('DOKUMEN PENDUKUNG', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 24),
          if (photo?.bytes != null)
            pw.Expanded(child: pw.Center(child: pw.Image(pw.MemoryImage(photo!.bytes!), fit: pw.BoxFit.contain)))
          else
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey200, style: pw.BorderStyle.dashed)),
                alignment: pw.Alignment.center,
                child: pw.Text('SLOT DOKUMEN KOSONG', style: const pw.TextStyle(color: PdfColors.grey300)),
              ),
            ),
          pw.SizedBox(height: 24),
          pw.Text('Halaman $pageNum', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          pw.SizedBox(height: 24),
        ],
      ),
    );
  }

  static int _addDocumentationPages(pw.Document pdf, List<ReportPhoto> photos, List<String> labels, String lampiranPrefix, String title, int startPageNum, Report report) {
    int totalPhotos = photos.length;
    int photoCounter = 0;
    int pageIdx = 0;
    
    // Each page has 4 rows, each row has 2 photos = 8 photos per page
    int totalPagesForThisCategory = (labels.length / 4).ceil();
    if (totalPagesForThisCategory == 0) totalPagesForThisCategory = 1;

    for (int pIdx = 0; pIdx < totalPagesForThisCategory; pIdx++) {
      final suffix = totalPagesForThisCategory > 1 ? '-${String.fromCharCode(65 + pIdx)}' : '';
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => pw.Column(
            children: [
              pw.Center(child: pw.Text('$lampiranPrefix$suffix', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Dokumentasi $title', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                columnWidths: {0: const pw.FixedColumnWidth(110), 1: const pw.FlexColumnWidth(), 2: const pw.FixedColumnWidth(110)},
                children: List.generate(4, (rowInPage) {
                  final labelIdx = (pIdx * 4) + rowInPage;
                  final label = labelIdx < labels.length ? labels[labelIdx] : 'Lain-lain';
                  
                  final p1 = photoCounter < totalPhotos ? photos[photoCounter++] : null;
                  final p2 = photoCounter < totalPhotos ? photos[photoCounter++] : null;
                  
                  return pw.TableRow(
                    children: [
                      _buildLabelCell(label),
                      _buildPhotoPairCell(p1, p2, photoCounter - 1),
                      _buildKeteranganCell(p1),
                    ],
                  );
                }),
              ),
              
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ID: ${report.referenceId}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('Tgl: ${_formatDate(report.date)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text('Halaman ${startPageNum + pageIdx}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ),
      );
      pageIdx++;
    }

    return startPageNum + pageIdx;
  }

  static pw.Widget _buildLabelCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      height: 165,
      alignment: pw.Alignment.topLeft,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
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

  static pw.Widget _buildPhotoBox(ReportPhoto? photo, int index) {
    return pw.Container(
      width: 110,
      height: 145,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
        color: photo?.bytes == null ? PdfColors.grey100 : null,
      ),
      child: photo?.bytes != null
          ? pw.Image(pw.MemoryImage(photo!.bytes!), fit: pw.BoxFit.cover)
          : pw.Center(child: pw.Text('GAMBAR $index', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400))),
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
