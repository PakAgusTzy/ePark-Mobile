import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();      
  final _emailController = TextEditingController();
  final _uidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();   
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _register() async {
  if (_formKey.currentState!.validate()) {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak sama')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid);

      // Buat data user
      await userDoc.set({
        'user_id': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'uid': _uidController.text.trim(),
        'role': 'user',
        'saldo': 10000, // top up awal
        'created_at': FieldValue.serverTimestamp(),
      });

      await userDoc.collection('notifikasi').add({
        'judul': 'Akun Berhasil Dibuat',
        'pesan': 'Selamat datang di ePark! Akun kamu berhasil dibuat.',
        'nominal': 0,
        'waktu': FieldValue.serverTimestamp(),
        'dibaca': false,
        'tipe': 'akun',
      });

      await userDoc.collection('riwayat_topup').add({
        'nominal': 10000,
        'waktu': FieldValue.serverTimestamp(),
        'keterangan': 'Top-up awal saat pendaftaran',
      });

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Gagal registrasi')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/gambar/ePark.png', width: 200),
                    const SizedBox(height: 24),
                    const Text("Daftar Akun", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      validator: (value) =>
                          value != null && value.isNotEmpty ? null : 'Nama tidak boleh kosong',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value != null && value.contains('@') ? null : 'Email tidak valid',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _uidController,
                      decoration: const InputDecoration(labelText: 'Nomor Kartu (UID RFID)'),
                      validator: (value) =>
                          value != null && value.isNotEmpty ? null : 'Nomor kartu tidak boleh kosong',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) =>
                          value != null && value.length >= 6 ? null : 'Minimal 6 karakter',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      decoration: const InputDecoration(labelText: 'Konfirmasi Password'),
                      obscureText: true,
                      validator: (value) => value == _passwordController.text
                          ? null
                          : 'Konfirmasi password tidak cocok',
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _register,
                            child: const Text("Daftar"),
                          ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text("Sudah punya akun? Login"),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
