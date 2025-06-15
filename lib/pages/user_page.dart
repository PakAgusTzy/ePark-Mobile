import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Model Data untuk Transaksi Top Up
class Transaksi {
  final String keterangan;
  final num nominal;
  final Timestamp waktu;

  Transaksi(
      {required this.keterangan, required this.nominal, required this.waktu});
}

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final bool? shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout')),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<List<Transaksi>> _fetchRiwayatTopUp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('riwayat_topup') // Sesuai pilihan Anda
        .orderBy('waktu', descending: true)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return Transaksi(
        keterangan: data['keterangan'] ?? 'Top-up',
        nominal: data['nominal'] ?? 0,
        waktu: data['waktu'] ?? Timestamp.now(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userSnapshot = Provider.of<DocumentSnapshot?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Riwayat'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout), onPressed: () => _logout(context))
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Builder(
        builder: (context) {
          if (userSnapshot == null || !userSnapshot.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = userSnapshot.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildInfoCard(
                title: 'Informasi Akun',
                children: [
                  _buildInfoTile(
                      icon: Icons.person_outline,
                      label: 'Nama',
                      value: userData['user_id'] ?? '...'),
                  _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: userData['email'] ?? '...'),
                  _buildInfoTile(
                      icon: Icons.credit_card,
                      label: 'Nomor Kartu (RFID)',
                      value: userData['uid'] ?? '...'),
                ],
              ),
              const SizedBox(height: 24),
              _buildRiwayatTopUpList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRiwayatTopUpList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Top Up',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Transaksi>>(
          future: _fetchRiwayatTopUp(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
             if (snapshot.hasError) {
              return Card(child: ListTile(title: Text('Gagal memuat riwayat: ${snapshot.error}')));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Card(
                  child: ListTile(title: Text('Belum ada riwayat top up.')));
            }

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final trx = snapshot.data![index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.wallet)),
                    title: Text(trx.keterangan),
                    subtitle: Text(DateFormat('d MMM y, HH:mm', 'id_ID')
                        .format(trx.waktu.toDate())),
                    trailing: Text(
                      '+${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(trx.nominal)}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      {required IconData icon,
      required String label,
      required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}