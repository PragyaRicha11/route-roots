import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://zlqfcvssghaulumymtgn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpscWZjdnNzZ2hhdWx1bXltdGduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY2NjY5MzUsImV4cCI6MjA4MjI0MjkzNX0.sO5WyYBfrVMM6lDO9kgMsLu2ad03MfAPtH5baVyA-lc',
  );

  runApp(const MaterialApp(home: LoginPage())); 
}