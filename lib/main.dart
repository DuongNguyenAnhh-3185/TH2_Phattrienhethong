import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'core/supabase_client.dart';
import 'database/database.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/document_storage_service.dart';
import 'state/cloud_document_provider.dart';
import 'state/document_provider.dart';
import 'state/subject_provider.dart';
import 'utils/app_theme.dart';
import 'views/auth/login_screen.dart';
import 'views/cloud_dashboard/document_dashboard_screen.dart';

// Biến gọi nhanh client ở mọi nơi trong app
final supabase = Supabase.instance.client;

Future<void> main() async {
  // 1. Đảm bảo toàn bộ binding engine của Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi tạo Supabase
  await Supabase.initialize(
    url: 'https://mfqnhwzpgoavfvayogib.supabase.co',
    // ignore: deprecated_member_use
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mcW5od3pwZ29hdmZ2YXlvZ2liIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NzU0NjAsImV4cCI6MjEwNzE1MTQ2MH0.cbp_qGhYHVmxEXOLI09B9hIYMPSq2ek5oxJJor67THs',
  );

  // 3. Khởi tạo dịch vụ Firebase đa nền tảng
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp Info: $e');
  }

  // 4. Khởi tạo cấu hình Supabase Client (gắn header x-firebase-uid)
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('SupabaseConfig.initialize Info: $e');
  }

  // 5. Khởi tạo các Service tầng Clean Architecture
  final authService = AuthService();
  final storageService = DocumentStorageService();
  final database = AppDatabase(); // Hỗ trợ Local-first SQLite Drift

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<DocumentStorageService>.value(value: storageService),
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<CloudDocumentProvider>(
          create: (_) => CloudDocumentProvider(storageService),
        ),
        ChangeNotifierProvider<DocumentProvider>(
          create: (_) => DocumentProvider(database),
        ),
        ChangeNotifierProvider<SubjectProvider>(
          create: (_) => SubjectProvider(database),
        ),
      ],
      child: const CloudDmsApp(),
    ),
  );
}

class CloudDmsApp extends StatelessWidget {
  const CloudDmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hệ thống Quản lý Tài liệu Cloud DMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

/// Widget điều hướng tự động dựa trên Stream authStateChanges của Firebase Auth
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService =
        Provider.of<DocumentStorageService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Trạng thái đang kiểm tra phiên đăng nhập
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Đang kiểm tra phiên đăng nhập...',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        // Nếu đã đăng nhập thành công với Google
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          // Gắn header định danh và đồng bộ hồ sơ lên Supabase
          SupabaseConfig.setFirebaseUidHeader(user.uid);
          authService.syncUserProfileToSupabase(user);

          return DocumentDashboardScreen(
            authService: authService,
            storageService: storageService,
          );
        }

        // Nếu chưa đăng nhập hoặc đã đăng xuất
        return LoginScreen(authService: authService);
      },
    );
  }
}
