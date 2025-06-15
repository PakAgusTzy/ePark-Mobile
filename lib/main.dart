// Salin semua kode di bawah ini untuk menggantikan isi file main.dart Anda

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- 1. TAMBAHKAN IMPORT INI
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/admin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 2. TAMBAHKAN BARIS INISIALISASI DI SINI
  await initializeDateFormatting('id_ID', null); 
  
  runApp(const MyApp());
}

// Sisa kode di bawah ini tidak perlu diubah...
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<DocumentSnapshot?>.value(
      initialData: null,
      value: FirebaseAuth.instance.authStateChanges().switchMap((user) {
        if (user != null) {
          return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
        }
        return Stream.value(null);
      }),
      child: MaterialApp(
        title: 'ePark',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const HomePage(),
          '/admin': (context) => const AdminPage(),
        },
      ),
    );
  }
}