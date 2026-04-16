import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _inspectorCtrl = TextEditingController();
  final _refIdCtrl = TextEditingController();
  
  // New Controllers
  final _pemasokCtrl = TextEditingController();
  final _kapalCtrl = TextEditingController();
  final _shipmentCtrl = TextEditingController();
  final _jobNoCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int _photosPerPage = 8;
  int _targetPages = 12;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _inspectorCtrl.dispose();
    _refIdCtrl.dispose();
    _pemasokCtrl.dispose();
    _kapalCtrl.dispose();
    _shipmentCtrl.dispose();
    _jobNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ReportProvider>();
    final success = await provider.createReport(
      title: _titleCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      date: _selectedDate,
      inspectorName: _inspectorCtrl.text.trim(),
      referenceId: _refIdCtrl.text.trim(),
      pemasok: _pemasokCtrl.text.trim(),
      namaKapal: _kapalCtrl.text.trim(),
      shipment: _shipmentCtrl.text.trim(),
      jobNo: _jobNoCtrl.text.trim(),
      photosPerPage: _photosPerPage,
      targetPages: _targetPages,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/manage_photos');
    } else if (mounted) {
      final errMsg = provider.error ?? 'Terjadi kesalahan saat membuat laporan.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
      );
    }
  }

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
        title: Text("Buat Laporan Baru", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F6FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("LANGKAH 1 DARI 3", style: GoogleFonts.outfit(color: const Color(0xFF006CFF), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              Text("Detail Laporan", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text("Berikan informasi utama proyek pengawasan.", style: TextStyle(color: Colors.black54, fontSize: 14)),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 32),

                        _buildField("JUDUL LAPORAN", _titleCtrl, "misalnya: Audit Integritas Struktural Q3"),
                        const SizedBox(height: 20),
                        _buildField("LOKASI PROYEK", _locationCtrl, "misalnya: Jl. Merdeka No. 10, Jakarta"),
                        const SizedBox(height: 20),

                        _buildField("PEMASOK/SUPPLIER", _pemasokCtrl, "misalnya: PT. BUKIT ASAM"),
                        const SizedBox(height: 20),
                        _buildField("NAMA KAPAL / TONGKANG", _kapalCtrl, "misalnya: TB: SAMUDRA SAKTI"),
                        const SizedBox(height: 20),
                        _buildField("SHIPMENT / NOMOR MUATAN", _shipmentCtrl, "misalnya: 040"),
                        const SizedBox(height: 20),
                        _buildField("JOB NO / NOMOR PEKERJAAN", _jobNoCtrl, "misalnya: PJB 3779"),
                        const SizedBox(height: 20),

                        // Date Picker
                        Text("TANGGAL INSPEKSI", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFFF0F3FF), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: const TextStyle(fontSize: 14)),
                                const Icon(Iconsax.calendar_copy, size: 20, color: Colors.black38),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildField("NAMA PETUGAS", _inspectorCtrl, "Nama penanggung jawab inspeksi"),
                        const SizedBox(height: 20),
                        _buildField("ID REFERENSI", _refIdCtrl, "REF-2023-001"),
                        const SizedBox(height: 20),

                        const SizedBox(height: 20),
                        
                        // Target Pages
                        Text("JUMLAH HALAMAN DOKUMENTASI", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [4, 8, 12, 18].map((n) {
                            final isSelected = _targetPages == n;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _targetPages = n),
                                child: Container(
                                  margin: EdgeInsets.only(right: n < 18 ? 12 : 0),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF006CFF) : const Color(0xFFF0F3FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$n hal",
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black45,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        const Text("Jumlah halaman yang akan dipersiapkan untuk dokumentasi.", style: TextStyle(color: Colors.black38, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),

              // Submit Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006CFF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.arrow_right_copy, size: 20),
                            const SizedBox(width: 8),
                            Text("Lanjut ke Foto", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF0F3FF), borderRadius: BorderRadius.circular(12)),
          child: TextFormField(
            controller: ctrl,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
