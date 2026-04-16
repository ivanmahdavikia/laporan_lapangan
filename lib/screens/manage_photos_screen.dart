import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';

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
        title: Text("Gambar Laporan", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          final photos = provider.currentPhotos;
          final report = provider.currentReport;
          if (report == null) return const Center(child: Text("Tidak ada laporan aktif."));

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Section
                      _ProgressSection(
                        current: photos.length,
                        max: report.maxPhotos,
                        photosPerPage: report.photosPerPage,
                      ),
                      const SizedBox(height: 24),

                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("ASET YANG DIUNGGAH", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                            child: const Text("Sinkronisasi Cloud", style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (photos.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          decoration: BoxDecoration(color: const Color(0xFFF0F6FF), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              const Icon(Iconsax.gallery_add_copy, color: Color(0xFF006CFF), size: 48),
                              const SizedBox(height: 16),
                              Text("Belum ada foto", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              const Text("Ambil foto atau pilih dari galeri.", style: TextStyle(color: Colors.black38, fontSize: 13)),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            return _PhotoCard(
                              photo: photo,
                              index: index,
                              photosPerPage: report.photosPerPage,
                              onMetadataChanged: (type, cat) => provider.updatePhotoMetadata(index, type, cat),
                              onCaptionChanged: (caption) => provider.updateCaption(index, caption),
                              onDelete: () => provider.removePhoto(index),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.black12)),
                ),
                child: Column(
                  children: [
                    // Add Photo Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: provider.isLoading ? null : () => provider.pickPhotoFromCamera(),
                            icon: const Icon(Iconsax.camera_copy, size: 18),
                            label: const Text("Kamera"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF0F3FF),
                              foregroundColor: const Color(0xFF1E1E2E),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: provider.isLoading ? null : () => provider.pickPhotosFromGallery(),
                            icon: const Icon(Iconsax.gallery_copy, size: 18),
                            label: const Text("Galeri"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF0F3FF),
                              foregroundColor: const Color(0xFF1E1E2E),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Generate PDF
                    ElevatedButton.icon(
                      onPressed: photos.isEmpty || provider.isLoading
                          ? null
                          : () async {
                              final pdf = await provider.generatePdf();
                              if (pdf != null && context.mounted) {
                                Navigator.pushNamed(context, '/preview');
                              }
                            },
                      icon: const Icon(Iconsax.document_copy, size: 18),
                      label: Text("Pratinjau PDF (${photos.length} foto)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006CFF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
    final pages = current > 0 ? (current / photosPerPage).ceil() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PROGRES MEDIA", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38)),
                const SizedBox(height: 4),
                Text("$current dari $max Slot", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("$pages halaman • $photosPerPage foto/halaman", style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: max > 0 ? current / max : 0,
                  strokeWidth: 8,
                  backgroundColor: Colors.black.withValues(alpha: 0.05),
                  color: const Color(0xFF006CFF),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text("$pct%", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF006CFF))),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _PhotoCard extends StatefulWidget {
  final dynamic photo;
  final int index;
  final int photosPerPage;
  final Function(String, String) onMetadataChanged;
  final Function(String) onCaptionChanged;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.photo,
    required this.index,
    required this.photosPerPage,
    required this.onMetadataChanged,
    required this.onCaptionChanged,
    required this.onDelete,
  });

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard> {
  late TextEditingController _captionCtrl;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.photo.caption);
  }

  @override
  void didUpdateWidget(covariant _PhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.id != widget.photo.id) {
      _captionCtrl.text = widget.photo.caption;
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.photo.localPath);
    final isForm = widget.photo.photoType == 'form';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: file.existsSync()
                ? Image.file(file, width: double.infinity, height: 200, fit: BoxFit.cover)
                : Container(height: 180, color: Colors.grey.shade200, alignment: Alignment.center, child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey)),
          ),
          const SizedBox(height: 16),

          // Type Selector (Toggle)
          Row(
            children: [
              _buildTypeTab("Dokumen (Hal 2-11)", !isForm, () => widget.onMetadataChanged('form', widget.photo.category)),
              const SizedBox(width: 8),
              _buildTypeTab("Foto Lapangan (Hal 12+)", isForm, () => widget.onMetadataChanged('documentation', widget.photo.category)),
            ],
          ),
          const SizedBox(height: 12),

          // Category Selector (If Documentation)
          if (!isForm)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.photo.category,
                  isExpanded: true,
                  onChanged: (val) => widget.onMetadataChanged(widget.photo.photoType, val!),
                  items: ['Draught Survey', 'Sampling', 'Preparasi'].map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Caption
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: _captionCtrl,
                    onChanged: widget.onCaptionChanged,
                    decoration: const InputDecoration(
                      hintText: "Tambah Keterangan (Opsional)...",
                      hintStyle: TextStyle(color: Colors.black26, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFFECEC), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Iconsax.trash_copy, color: Colors.red, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTypeTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF006CFF) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
