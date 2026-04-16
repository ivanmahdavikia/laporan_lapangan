import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/report_provider.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFF),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Pratinjau Laporan", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.share_copy),
            onPressed: () => _sharePdf(context),
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          final report = provider.currentReport;
          final pdf = provider.generatedPdf;

          if (report == null) return const Center(child: Text("Tidak ada laporan."));

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Report Preview Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Branding
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: const Color(0xFFE8F0FF), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Iconsax.ruler_copy, color: Color(0xFF006CFF), size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Laporan Pengawasan", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text("REKAP EVIDEN LAPANGAN", style: GoogleFonts.outfit(fontSize: 8, color: Colors.black45, letterSpacing: 0.5)),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(report.referenceId, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11)),
                                    Text(_formatDate(report.date), style: const TextStyle(fontSize: 10, color: Colors.black45)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Title
                            Text(report.title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                            const SizedBox(height: 12),
                            Text(report.location, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 20),

                            // Stats
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFFF0F6FF), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _InfoItem("Foto", "${report.totalPhotos}"),
                                  Container(width: 1, height: 30, color: Colors.black12),
                                  _InfoItem("Halaman", "${report.totalPages + 1}"),
                                  Container(width: 1, height: 30, color: Colors.black12),
                                  _InfoItem("Petugas", report.inspectorName),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 700.ms).scale(begin: const Offset(0.95, 0.95)),
                      const SizedBox(height: 24),

                      // File Status
                      if (pdf != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8F5E9)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFFFFECEC), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pdf.path.split('/').last, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    FutureBuilder<int>(
                                      future: pdf.length(),
                                      builder: (_, snap) {
                                        final mb = (snap.data ?? 0) / 1024 / 1024;
                                        return Text("${mb.toStringAsFixed(1)} MB • Baru saja dibuat", style: const TextStyle(color: Colors.black38, fontSize: 11));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                                child: Text("SIAP\nEKSPOR", textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, height: 1.1)),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 32),

                      // Action Buttons
                      ElevatedButton.icon(
                        onPressed: () => _previewPdf(context),
                        icon: const Icon(Iconsax.eye_copy),
                        label: Text("Lihat PDF Lengkap", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006CFF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: () => _sharePdf(context),
                        icon: const Icon(Iconsax.share_copy),
                        label: Text("Bagikan PDF", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0F3FF),
                          foregroundColor: const Color(0xFF006CFF),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Iconsax.edit_copy, size: 18),
                        label: const Text("Kembali ke Editor"),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Nav
              const _BottomNav(),
            ],
          );
        },
      ),
    );
  }

  void _previewPdf(BuildContext context) {
    final pdf = context.read<ReportProvider>().generatedPdf;
    if (pdf == null) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("PDF Viewer")),
        body: PdfPreview(
          build: (_) => pdf.readAsBytesSync(),
          canChangePageFormat: false,
          canChangeOrientation: false,
        ),
      ),
    ));
  }

  void _sharePdf(BuildContext context) {
    final pdf = context.read<ReportProvider>().generatedPdf;
    if (pdf == null) return;

    SharePlus.instance.share(
      ShareParams(
        files: [XFile(pdf.path)],
        text: 'Laporan Pengawasan',
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF006CFF))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(icon: Iconsax.document_copy, label: "LAPORAN", isActive: true, onTap: () => Navigator.popUntil(context, (r) => r.isFirst)),
          _NavItem(icon: Iconsax.edit_2_copy, label: "DRAF", isActive: false, onTap: () {}),
          _NavItem(icon: Iconsax.scan_barcode_copy, label: "PINDAI", isActive: false, onTap: () {}),
          _NavItem(icon: Iconsax.setting_2_copy, label: "PENGATURAN", isActive: false, onTap: () {}),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF006CFF) : Colors.black38;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
