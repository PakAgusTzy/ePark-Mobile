import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _formKey = GlobalKey<FormState>();
  final _complaintController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Masalah Top Up',
    'Aplikasi Error',
    'Masalah Parkir',
    'Saran & Masukan',
    'Lainnya',
  ];

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _kirimPengaduan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Ambil data user dari Provider untuk efisiensi
    final userSnapshot = Provider.of<DocumentSnapshot?>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || userSnapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendapatkan data pengguna.')));
      setState(() => _isLoading = false);
      return;
    }
    
    final userData = userSnapshot.data() as Map<String, dynamic>;

    try {
      // Simpan pengaduan ke koleksi baru 'pengaduan'
      await FirebaseFirestore.instance.collection('pengaduan').add({
        'userId': user.uid,
        'namaPengguna': userData['user_id'] ?? 'Tidak diketahui',
        'emailPengguna': userData['email'] ?? 'Tidak diketahui',
        'kategori': _selectedCategory,
        'isiPengaduan': _complaintController.text,
        'waktu': FieldValue.serverTimestamp(),
        'status': 'Baru', // Status awal pengaduan
      });

      if(mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pengaduan Terkirim'),
            content: const Text('Terima kasih atas masukan Anda. Tim kami akan segera menindaklanjutinya.'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
          ),
        );
        // Reset form setelah berhasil
        _formKey.currentState?.reset();
        _complaintController.clear();
        setState(() {
          _selectedCategory = null;
        });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim pengaduan: $e')));
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Kirim Keluhan atau Masukan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kami siap membantu Anda. Silakan isi form di bawah ini untuk melaporkan masalah atau memberikan saran.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Dropdown untuk Kategori
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Pilih Kategori',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              validator: (value) => value == null ? 'Kategori harus dipilih' : null,
            ),
            const SizedBox(height: 16),
            // Text field untuk isi pengaduan
            TextFormField(
              controller: _complaintController,
              decoration: const InputDecoration(
                labelText: 'Jelaskan masalah Anda di sini',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Isi pengaduan tidak boleh kosong' : null,
            ),
            const SizedBox(height: 24),
            // Tombol Kirim
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _kirimPengaduan,
                    icon: const Icon(Icons.send),
                    label: const Text('Kirim Pengaduan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}