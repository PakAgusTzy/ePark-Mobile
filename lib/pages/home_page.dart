import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Import semua halaman yang akan dituju
import 'help_Page.dart';
import 'Inbox_Page.dart'; // Nama file disesuaikan setelah di-rename
import 'parking_page.dart';
import 'payment_Page.dart';
import 'topup_Page.dart';
import 'TransactionHistory_Page.dart';
import 'user_page.dart';

// Model Data untuk Notifikasi
class Notifikasi {
  final String judul;
  final String pesan;
  final Timestamp waktu;
  Notifikasi({required this.judul, required this.pesan, required this.waktu});
}

// Widget utama HomePage (tidak ada perubahan)
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  static final List<Widget> _pages = <Widget>[
    const HomeContent(),
    const ParkingPage(),
    const UserPage(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_parking_rounded), label: 'Parkir'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: 'Akun'),
        ],
      ),
    );
  }
}

// HomeContent
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Future<List<Notifikasi>> _fetchNotifikasiTerakhir() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final notifQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifikasi')
        .orderBy('waktu', descending: true)
        .limit(3)
        .get();
    List<Notifikasi> semuaNotifikasi = [];
    for (var doc in notifQuery.docs) {
      final data = doc.data();
      if (data.containsKey('waktu') && data['waktu'] is Timestamp) {
        semuaNotifikasi.add(Notifikasi(
          judul: data['judul'] ?? 'Tanpa Judul',
          pesan: data['pesan'] ?? 'Tidak ada pesan.',
          waktu: data['waktu'],
        ));
      }
    }
    return semuaNotifikasi;
  }

  @override
  Widget build(BuildContext context) {
    final userSnapshot = Provider.of<DocumentSnapshot?>(context);
    if (userSnapshot == null || !userSnapshot.exists) {
      return const Center(child: CircularProgressIndicator());
    }
    final userData = userSnapshot.data() as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Container(
              height: 200,
              decoration: BoxDecoration(
                  color: Colors.blue[800],
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30)))),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildWelcomeHeader(userData['user_id'] ?? 'Pengguna'),
                  const SizedBox(height: 20),
                  _buildSaldoCard(context, userData['saldo'] ?? 0),
                  const SizedBox(height: 24),
                  _buildFiturGrid(context),
                  const SizedBox(height: 24),
                  const Text('Notifikasi Terbaru',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildNotifikasiList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaldoCard(BuildContext context, num saldo) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('eParkCash',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                  .format(saldo),
              style:
                  const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.add_card, color: Colors.blue[800]),
                  label: Text('Top Up',
                      style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TopUpPage()));
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.receipt_long, color: Colors.blue[800]),
                  label: Text('Riwayat',
                      style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TransactionHistoryPage()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // FUNGSI INI DIPERBARUI DENGAN NAVIGASI BARU
  // =======================================================================
  Widget _buildFiturGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Tombol Bayar -> ke PaymentPage
        _buildFiturItem(
          icon: Icons.qr_code_scanner,
          label: 'Bayar',
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const PaymentPage()));
          },
        ),
        // Tombol Riwayat -> ke TransactionHistoryPage
        _buildFiturItem(
          icon: Icons.receipt_long,
          label: 'Riwayat',
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TransactionHistoryPage()));
          },
        ),
        // Tombol Bantuan -> ke HelpPage
        _buildFiturItem(
          icon: Icons.support_agent,
          label: 'Bantuan',
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HelpPage()));
          },
        ),
        // Tombol Pesan -> ke InboxPage (pengganti Promo)
        _buildFiturItem(
          icon: Icons.mail_outline, // Ikon diubah
          label: 'Pesan', // Label diubah
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const InboxPage()));
          },
        ),
      ],
    );
  }

  // Sisa helper widget tidak ada perubahan
  Widget _buildNotifikasiList() {
    return FutureBuilder<List<Notifikasi>>(
      future: _fetchNotifikasiTerakhir(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Card(
              child: ListTile(
                  title: Text('Gagal memuat notifikasi: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
              child: ListTile(title: Text('Belum ada notifikasi.')));
        }
        final notifikasi = snapshot.data!;
        return Card(
          elevation: 0,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListView.separated(
            itemCount: notifikasi.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final notif = notifikasi[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.notifications_active_outlined,
                      color: Colors.blue[800]),
                ),
                title: Text(notif.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(notif.pesan),
                trailing: Text(
                    DateFormat('HH:mm').format(notif.waktu.toDate()),
                    style: const TextStyle(color: Colors.grey)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(String nama) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Selamat Datang,\n$nama!',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        const CircleAvatar(
            backgroundColor: Colors.white54,
            child: Icon(Icons.notifications_none, color: Colors.white)),
      ],
    );
  }

  Widget _buildFiturItem(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(icon, size: 28, color: Colors.blue[800]),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}