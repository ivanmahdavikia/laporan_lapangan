import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/report_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Consumer<ReportProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Laporan Pengawasan",
                                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Rekap eviden foto lapangan",
                                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.black45),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F0FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Iconsax.notification_copy, color: Color(0xFF006CFF)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Stats Row
                        Row(
                          children: [
                            _StatChip(
                              label: "Total Laporan",
                              value: "${provider.reports.length}",
                              color: const Color(0xFF006CFF),
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              label: "Draft",
                              value: "${provider.reports.where((r) => r.status == 'draft').length}",
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              label: "Selesai",
                              value: "${provider.reports.where((r) => r.status == 'completed').length}",
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms),
                ),

                // Report List
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.reports.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(onTap: () => Navigator.pushNamed(context, '/create')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final report = provider.reports[index];
                          return _ReportCard(
                            report: report,
                            onTap: () {
                              provider.setCurrentReport(report);
                              Navigator.pushNamed(context, '/manage_photos');
                            },
                            onDelete: () => _confirmDelete(context, provider, report),
                          );
                        },
                        childCount: provider.reports.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create'),
        backgroundColor: const Color(0xFF006CFF),
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add_copy),
        label: Text("Laporan Baru", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 300.ms),
    );
  }

  void _confirmDelete(BuildContext context, ReportProvider provider, Report report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Laporan?"),
        content: Text("Laporan \"${report.title}\" akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              provider.deleteReport(report.id!);
              Navigator.pop(ctx);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReportCard({required this.report, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = report.status == 'completed' ? Colors.green : Colors.orange;
    final statusLabel = report.status == 'completed' ? 'Selesai' : 'Draft';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Iconsax.document_text_copy, color: Color(0xFF006CFF), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${report.location} • ${report.totalPhotos} foto',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Iconsax.trash_copy, color: Colors.red, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: const Color(0xFFE8F0FF), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Iconsax.document_copy, color: Color(0xFF006CFF), size: 48),
          ),
          const SizedBox(height: 24),
          Text("Belum ada laporan", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Mulai buat laporan pengawasan pertama Anda.", style: TextStyle(color: Colors.black45)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006CFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("+ Buat Laporan Baru"),
          ),
        ],
      ),
    );
  }
}
