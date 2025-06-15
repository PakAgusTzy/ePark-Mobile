import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// WIDGET KHUSUS UNTUK TIMER AGAR TIDAK KEDIP-KEDIP
class DurasiTimer extends StatefulWidget {
  final Timestamp waktuMasuk;
  const DurasiTimer({super.key, required this.waktuMasuk});

  @override
  State<DurasiTimer> createState() => _DurasiTimerState();
}

class _DurasiTimerState extends State<DurasiTimer> {
  Timer? _timer;
  Duration _durasi = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final masuk = widget.waktuMasuk.toDate();
      setState(() {
        _durasi = now.difference(masuk);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String durasiStr =
        '${_durasi.inHours.toString().padLeft(2, '0')}:${(_durasi.inMinutes % 60).toString().padLeft(2, '0')}:${(_durasi.inSeconds % 60).toString().padLeft(2, '0')}';
    return Text(durasiStr,
        style: const TextStyle(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold));
  }
}

// HALAMAN UTAMA PARKING PAGE
class ParkingPage extends StatelessWidget {
  const ParkingPage({super.key});

  // =======================================================================
  // FUNGSI INI DIPERBARUI DENGAN LOGIKA PEMBUATAN NOTIFIKASI
  // =======================================================================
  Future<void> _selesaikanParkir(
      BuildContext context, String slotId, DocumentSnapshot slotSnapshot) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dataSlot = slotSnapshot.data() as Map<String, dynamic>;
    final num biaya = 2000;
    final Timestamp waktuMasuk = dataSlot['waktu_masuk'] ?? Timestamp.now();

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final slotRef = FirebaseFirestore.instance.collection('slots').doc(slotId);
    final historyRef = userRef.collection('parkir_history').doc();
    
    // Referensi untuk membuat notifikasi baru
    final notifRef = userRef.collection('notifikasi').doc();

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Kurangi saldo pengguna
      batch.update(userRef, {'saldo': FieldValue.increment(-biaya)});
      
      // 2. Buat dokumen riwayat baru
      batch.set(historyRef, {
        'biaya': biaya,
        'slot_id': slotId,
        'status': 'selesai',
        'waktu_masuk': waktuMasuk,
        'waktu_keluar': FieldValue.serverTimestamp(),
      });

      // 3. Reset slot parkir
      batch.update(slotRef, {
        'tersedia': true,
        'uid_terisi': '',
        'waktu_masuk': null,
      });

      // 4. TAMBAHKAN NOTIFIKASI BARU
      batch.set(notifRef, {
        'judul': 'Parkir Selesai',
        'pesan': 'Anda telah menyelesaikan parkir di slot ${slotId.toUpperCase().replaceAll('_', '-')}. Saldo terpotong Rp$biaya.',
        'dibaca': false,
        'waktu': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Parkir telah selesai.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyelesaikan parkir: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Silakan login terlebih dahulu.")));
    }

    final stream = FirebaseFirestore.instance
        .collection('slots')
        .where('uid_terisi', isEqualTo: user.uid)
        .limit(1)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        }
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final slotSnapshot = snapshot.data!.docs.first;
          return _buildTampilanParkir(context, slotSnapshot);
        } else {
          return _buildTampilanTidakParkir();
        }
      },
    );
  }

  // Sisa kode di bawah ini tidak ada perubahan
  Widget _buildTampilanTidakParkir() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Parkir'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green[600], size: 100),
            const SizedBox(height: 20),
            const Text(
              'Anda Sedang Tidak Parkir',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Untuk memulai, silakan tap kartu di gerbang masuk.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTampilanParkir(BuildContext context, DocumentSnapshot slotSnapshot) {
    final data = slotSnapshot.data() as Map<String, dynamic>;
    final String slotId = slotSnapshot.id;
    final Timestamp waktuMasuk = data['waktu_masuk'] ?? Timestamp.now();

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Status Parkir Anda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.directions_car, color: Colors.blue[800], size: 120),
            const SizedBox(height: 24),
            Text(
              'ANDA SEDANG PARKIR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              slotId.toUpperCase().replaceAll('_', '-'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Durasi: ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                DurasiTimer(waktuMasuk: waktuMasuk),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _selesaikanParkir(context, slotId, slotSnapshot),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Selesaikan Parkir & Bayar', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}