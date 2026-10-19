class AppConstants {
  static const String supabaseUrl =
      'https://mfqnhwzpgoavfvayogib.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mcW5od3pwZ29hdmZ2YXlvZ2liIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NzU0NjAsImV4cCI6MjEwNzE1MTQ2MH0.cbp_qGhYHVmxEXOLI09B9hIYMPSq2ek5oxJJor67THs';

  /// Bucket lưu trữ tài liệu nhị phân trên Supabase Storage
  static const String storageBucket = 'documents';

  /// Dung lượng tệp tối đa cho phép tải lên (25 MB)
  static const int maxUploadSizeBytes = 25 * 1024 * 1024;
}
