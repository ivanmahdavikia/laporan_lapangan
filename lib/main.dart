import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/report_provider.dart';
import 'screens/home_screen.dart';
import 'screens/create_report_screen.dart';
import 'screens/manage_photos_screen.dart';
import 'screens/preview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- SUPABASE INIT ---
  // TODO: Ganti dengan URL dan Anon Key dari project Supabase Anda
  // Jika belum dikonfigurasi, aplikasi akan berjalan dalam mode offline
  try {
    await Supabase.initialize(
      url: 'https://dhkvzskizlgszhlmvudu.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRoa3Z6c2tpemxnc3pobG12dWR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MDk2NTQsImV4cCI6MjA5MTQ4NTY1NH0.40Kui9YPVVWvaTLJ3RGWOwWYs0Myot7e78lI8ZeXh8A',
    );
  } catch (e) {
    debugPrint('Supabase init gagal, berjalan dalam mode offline: $e');
  }

  runApp(const ReportApp());
}

class ReportApp extends StatelessWidget {
  const ReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Laporan Pengawasan',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8FAFF),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006CFF),
            primary: const Color(0xFF006CFF),
            surface: Colors.white,
          ),
          textTheme: GoogleFonts.outfitTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF8FAFF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/create': (context) => const CreateReportScreen(),
          '/manage_photos': (context) => const ManagePhotosScreen(),
          '/preview': (context) => const PreviewScreen(),
        },
      ),
    );
  }
}
