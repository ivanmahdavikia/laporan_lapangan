import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/report_model.dart';

class ManagePhotosScreen extends StatelessWidget {
  const ManagePhotosScreen({super.key});

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
        title: Text("Media Laporan", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          final photos = provider.currentPhotos;
          final report = provider.currentReport;
          if (report == null) return const Center(child: Text("Tidak ada laporan aktif."));

          final docPhotos = photos.where((p) => p.photoType == 'form').toList();
          final fieldPhotos = photos.where((p) => p.photoType == 'documentation').toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProgressSection(
                        current: photos.length,
                        max: report.maxPhotos,
                        photosPerPage: report.photosPerPage,
                      ),
                      const SizedBox(height: 32),

                      // --- SECTION 1: DOKUMEN ---
                      _SectionHeader(
                        title: "DOKUMEN PENDUKUNG",
                        subtitle: "Halaman 2-11 • Maks 10 Dokumen",
                        icon: Iconsax.document_text_1_copy,
                        onAddCamera: () => provider.pickPhotoFromCamera(photoType: 'form'),
                        onAddGallery: () => provider.pickPhotosFromGallery(photoType: 'form'),
                      ),
                      const SizedBox(height: 16),
                      if (docPhotos.isEmpty)
                        _EmptyState(message: "Belum ada dokumen pendukung.")
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docPhotos.length,
                          itemBuilder: (context, index) {
                            final photo = docPhotos[index];
                            final globalIndex = photos.indexOf(photo);
                            return _DocumentCard(
                              photo: photo,
                              onDelete: () => provider.removePhoto(globalIndex),
                            );
                          },
                        ),

                      const SizedBox(height: 48),

                      // --- SECTION 2: LAPANGAN ---
                      _SectionHeader(
                        title: "DOKUMENTASI LAPANGAN",
                        subtitle: "Halaman 12+ • Format Tabel 3-Kolom",
                        icon: Iconsax.camera_copy,
                        onAddCamera: () => provider.pickPhotoFromCamera(photoType: 'documentation'),
                        onAddGallery: () => provider.pickPhotosFromGallery(photoType: 'documentation'),
                      ),
                      const SizedBox(height: 16),
                      if (fieldPhotos.isEmpty)
                        _EmptyState(message: "Belum ada dokumentasi lapangan.")
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: fieldPhotos.length,
                          itemBuilder: (context, index) {
                            final photo = fieldPhotos[index];
                            final globalIndex = photos.indexOf(photo);
                            return _FieldPhotoCard(
                              photo: photo,
                              index: index,
                              onMetadataChanged: (type, cat, isFull, lbl) => 
                                provider.updatePhotoMetadata(globalIndex, type, cat, isFull, lbl),
                              onCaptionChanged: (caption) => provider.updateCaption(globalIndex, caption),
                              onDelete: () => provider.removePhoto(globalIndex),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Generate PDF
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.black12)),
                ),
                child: ElevatedButton.icon(
                  onPressed: photos.isEmpty || provider.isLoading
                      ? null
                      : () async {
                          final pdf = await provider.generatePdf();
                          if (pdf != null && context.mounted) {
                            Navigator.pushNamed(context, '/preview');
                          } else if (provider.error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(provider.error!), backgroundColor: Colors.redAccent),
                            );
                            provider.clearError();
                          }
                        },
                  icon: const Icon(Iconsax.document_copy, size: 20),
                  label: Text("Pratinjau PDF (${photos.length} Media)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006CFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onAddCamera;
  final VoidCallback onAddGallery;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onAddCamera,
    required this.onAddGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF006CFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: const Color(0xFF006CFF), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black38)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MiniButton(icon: Iconsax.camera_copy, label: "Kamera", onTap: onAddCamera),
            const SizedBox(width: 8),
            _MiniButton(icon: Iconsax.gallery_copy, label: "Galeri", onTap: onAddGallery),
          ],
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.black54),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final ReportPhoto photo;
  final VoidCallback onDelete;

  const _DocumentCard({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final file = File(photo.localPath);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: file.existsSync() 
              ? Image.file(file, width: 60, height: 60, fit: BoxFit.cover)
              : Container(width: 60, height: 60, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported, size: 20)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text("Halaman Full (P2-11)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
          ),
          IconButton(onPressed: onDelete, icon: const Icon(Iconsax.trash_copy, color: Colors.redAccent, size: 18)),
        ],
      ),
    ).animate().slideX();
  }
}

class _FieldPhotoCard extends StatefulWidget {
  final ReportPhoto photo;
  final int index;
  final Function(String, String, bool, String) onMetadataChanged;
  final Function(String) onCaptionChanged;
  final VoidCallback onDelete;

  const _FieldPhotoCard({
    required this.photo,
    required this.index,
    required this.onMetadataChanged,
    required this.onCaptionChanged,
    required this.onDelete,
  });

  @override
  State<_FieldPhotoCard> createState() => _FieldPhotoCardState();
}

class _FieldPhotoCardState extends State<_FieldPhotoCard> {
  late TextEditingController _captionCtrl;
  late TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.photo.caption);
    _labelCtrl = TextEditingController(text: widget.photo.customLabel);
  }

  @override
  void didUpdateWidget(covariant _FieldPhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.id != widget.photo.id) {
      _captionCtrl.text = widget.photo.caption;
      _labelCtrl.text = widget.photo.customLabel;
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.photo.localPath);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF0F6FF), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: file.existsSync()
                    ? Image.file(file, width: 100, height: 100, fit: BoxFit.cover)
                    : Container(width: 100, height: 100, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.photo.category,
                          isExpanded: true,
                          onChanged: (val) => widget.onMetadataChanged(widget.photo.photoType, val!, widget.photo.isFullWidth, widget.photo.customLabel),
                          items: ['Draught Survey', 'Sampling', 'Preparasi'].map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12)));
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Full Width", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch.adaptive(
                              value: widget.photo.isFullWidth,
                              onChanged: (val) => widget.onMetadataChanged(widget.photo.photoType, widget.photo.category, val, widget.photo.customLabel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("LABEL KIRI", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: _labelCtrl,
              onChanged: (val) => widget.onMetadataChanged(widget.photo.photoType, widget.photo.category, widget.photo.isFullWidth, val),
              decoration: const InputDecoration(
                hintText: "Contoh: Kondisi Vessel...",
                hintStyle: TextStyle(fontSize: 12, color: Colors.black26),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Text("KETERANGAN KANAN", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: _captionCtrl,
                    onChanged: widget.onCaptionChanged,
                    decoration: const InputDecoration(
                      hintText: "Tambah Keterangan...",
                      hintStyle: TextStyle(fontSize: 12, color: Colors.black26),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: widget.onDelete, icon: const Icon(Iconsax.trash_copy, color: Colors.redAccent, size: 20)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05), style: BorderStyle.solid),
      ),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.black26, fontSize: 13))),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final int current;
  final int max;
  final int photosPerPage;

  const _ProgressSection({required this.current, required this.max, required this.photosPerPage});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (current / max * 100).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PROGRES LAPORAN", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text("$current Media", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("dari maksimum $max slot tersedia", style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: max > 0 ? current / max : 0,
              backgroundColor: Colors.white10,
              color: const Color(0xFF006CFF),
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}
