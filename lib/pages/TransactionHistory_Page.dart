import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Model Data untuk Transaksi
class Transaksi {
  final String judul;
  final String keterangan;
  final num nominal;
  final Timestamp waktu;
  final String tipe;

  Transaksi({
    required this.judul,
    required this.keterangan,
    required this.nominal,
    required this.waktu,
    required this.tipe,
  });
}

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  Future<List<Transaksi>> _fetchAllTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Ambil semua data top-up, diurutkan berdasarkan 'waktu'
    final topupQuery = await userDocRef
        .collection('riwayat_topup')
        .orderBy('waktu', descending: true)
        .get();

    // ===============================================================
    // PERBAIKAN DI SINI: Mengurutkan berdasarkan 'waktu_keluar'
    // ===============================================================
    final parkirQuery = await userDocRef
        .collection('parkir_history')
        .orderBy('waktu_keluar', descending: true)
        .get();

    List<Transaksi> semuaTransaksi = [];

    // Proses data top-up (tidak ada perubahan)
    for (var doc in topupQuery.docs) {
      final data = doc.data();
      if (data.containsKey('waktu') && data['waktu'] is Timestamp) {
        semuaTransaksi.add(Transaksi(
          judul: data['keterangan'] ?? 'Top Up',
          keterangan: DateFormat('d MMM y, HH:mm', 'id_ID')
              .format((data['waktu'] as Timestamp).toDate()),
          nominal: data['nominal'] ?? 0,
          waktu: data['waktu'],
          tipe: 'topup',
        ));
      }
    }

    // ===============================================================
    // PERBAIKAN DI SINI: Membaca dari field yang benar
    // ===============================================================
    for (var doc in parkirQuery.docs) {
      final data = doc.data();
      // Cek field 'waktu_keluar' bukan 'waktu'
      if (data.containsKey('waktu_keluar') &&
          data['waktu_keluar'] is Timestamp) {
        semuaTransaksi.add(Transaksi(
          judul: 'Bayar Parkir',
          keterangan: data['slot_id'] ?? 'Lokasi tidak diketahui',
          nominal: data['biaya'] ?? 0,
          waktu: data['waktu_keluar'], // Gunakan 'waktu_keluar'
          tipe: 'parkir',
        ));
      }
    }

    // Urutkan semua transaksi gabungan berdasarkan waktu
    semuaTransaksi.sort((a, b) => b.waktu.compareTo(a.waktu));

    return semuaTransaksi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
      ),
      body: FutureBuilder<List<Transaksi>>(
        future: _fetchAllTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Gagal memuat riwayat: ${snapshot.error}', textAlign: TextAlign.center),
                ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada riwayat transaksi.'));
          }

          final transactions = snapshot.data!;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final trx = transactions[index];
              final isTopup = trx.tipe == 'topup';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isTopup
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    child: Icon(
                      isTopup ? Icons.wallet : Icons.local_parking,
                      color: isTopup ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(trx.judul,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(trx.keterangan),
                  trailing: Text(
                    '${isTopup ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(trx.nominal)}',
                    style: TextStyle(
                      color: isTopup ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}