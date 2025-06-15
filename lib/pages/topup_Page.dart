import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _customAmountController = TextEditingController();
  final _paymentNumberController = TextEditingController();

  int? _selectedAmount;
  String? _selectedMethod;
  bool _isLoading = false;

  final List<int> _presetAmounts = [10000, 25000, 50000, 100000];
  final List<Map<String, String>> _paymentMethods = [
    {'name': 'DANA', 'logo': 'assets/logos/dana.png'},
    {'name': 'GoPay', 'logo': 'assets/logos/gopay.png'},
    {'name': 'OVO', 'logo': 'assets/logos/ovo.png'},
    {'name': 'Bank Transfer', 'logo': 'assets/logos/bank.png'},
  ];

  @override
  void dispose() {
    _customAmountController.dispose();
    _paymentNumberController.dispose();
    super.dispose();
  }

  Future<void> _prosesTopUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAmount == null && _customAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih atau isi nominal top up.')));
      return;
    }
     if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih metode pembayaran.')));
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle jika user tidak login
      setState(() => _isLoading = false);
      return;
    }

    // Tentukan jumlah top up
    final int amount = _selectedAmount ?? int.parse(_customAmountController.text);
    
    try {
      // Update saldo pengguna
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'saldo': FieldValue.increment(amount),
      });

      // Tambahkan ke riwayat top up
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('riwayat_topup').add({
        'nominal': amount,
        'keterangan': 'Top-up via $_selectedMethod',
        'waktu': FieldValue.serverTimestamp(),
      });
      
      if(mounted) {
        await showDialog(context: context, builder: (context) => AlertDialog(
          title: const Text('Top Up Berhasil'),
          content: Text('Saldo Anda telah berhasil ditambah sebesar Rp$amount.'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        ));
        Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
      }

    } catch (e) {
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
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
        title: const Text('Top Up eParkCash'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Bagian Pilih Nominal
            _buildSectionTitle('Pilih Nominal Top Up'),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _presetAmounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return ChoiceChip(
                  label: Text('Rp${NumberFormat.decimalPattern('id_ID').format(amount)}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedAmount = selected ? amount : null;
                      if(selected) _customAmountController.clear();
                    });
                  },
                  selectedColor: Colors.blue[100],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customAmountController,
              decoration: const InputDecoration(
                labelText: 'Atau masukkan nominal lain',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onTap: () => setState(() => _selectedAmount = null),
              validator: (value) {
                if (_selectedAmount == null && (value == null || value.isEmpty)) {
                  return 'Nominal tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Bagian Metode Pembayaran
            _buildSectionTitle('Pilih Metode Pembayaran'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paymentMethods.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                final isSelected = _selectedMethod == method['name'];
                return InkWell(
                  onTap: () => setState(() => _selectedMethod = method['name']),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(method['logo']!, fit: BoxFit.contain),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            if (_selectedMethod != null)
              TextFormField(
                controller: _paymentNumberController,
                decoration: InputDecoration(
                  labelText: _selectedMethod == 'Bank Transfer' ? 'Nomor Rekening Tujuan' : 'Nomor Handphone',
                  border: const OutlineInputBorder(),
                ),
                 keyboardType: TextInputType.phone,
                 validator: (value) => (value == null || value.isEmpty) ? 'Nomor tidak boleh kosong' : null,
              ),
            
            const SizedBox(height: 32),

            // Tombol Konfirmasi
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _prosesTopUp,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Konfirmasi Top Up'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}