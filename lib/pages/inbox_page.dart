  import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Model Data Notifikasi
class Notifikasi {
  final String judul;
  final String pesan;
  final Timestamp waktu;
  Notifikasi({required this.judul, required this.pesan, required this.waktu});
}

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  Future<List<Notifikasi>> _fetchAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifikasi')
        .orderBy('waktu', descending: true)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return Notifikasi(
        judul: data['judul'] ?? 'Tanpa Judul',
        pesan: data['pesan'] ?? '',
        waktu: data['waktu'] ?? Timestamp.now(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan Masuk'),
      ),
      body: FutureBuilder<List<Notifikasi>>(
        future: _fetchAllNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada pesan masuk.'));
          }

          final notifications = snapshot.data!;
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.notifications)),
                title: Text(notif.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(notif.pesan),
                trailing: Text(DateFormat('d/M/y').format(notif.waktu.toDate())),
              );
            },
          );
        },
      ),
    );
  }
}