import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isScanCompleted = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
  
  void closeScreen() {
    // Reset status scan saat layar ditutup
    setState(() {
      isScanCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          // ===============================================================
          // PERUBAHAN DI SINI: Tombol senter disederhanakan
          // ===============================================================
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flash_on), // Menggunakan satu ikon statis
            iconSize: 32.0,
            tooltip: 'Nyalakan/Matikan Flash',
            onPressed: () => cameraController.toggleTorch(),
          ),
          // Tombol untuk mengganti kamera depan/belakang (tetap sama)
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flip_camera_ios),
            iconSize: 32.0,
            tooltip: 'Ganti Kamera',
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if(!isScanCompleted) {
                setState(() {
                  isScanCompleted = true;
                });
                
                final String code = capture.barcodes.first.rawValue ?? "Data tidak ditemukan";

                showDialog(
                  context: context,
                  barrierDismissible: false, // Mencegah dialog ditutup dengan tap di luar
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("QR Code Terdeteksi!"),
                      content: Text("Data: $code"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Tutup dialog
                            Navigator.of(context).pop(); // Kembali ke HomePage
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  },
                ).then((_) => closeScreen()); // Panggil closeScreen setelah dialog ditutup
              }
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.7), width: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: const Text(
                    'Arahkan kamera ke QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          )
        ],
      ),
    );
  }
} 