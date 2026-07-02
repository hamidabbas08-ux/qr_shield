import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const QrShieldApp());
}

class QrShieldApp extends StatelessWidget {
  const QrShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const QrScannerScreen(),
    );
  }
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  String? scanResult;
  bool isVerified = false;
  bool isScanning = true;
  bool isPlayStoreLink = false;

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _processQrCode(String code) {
    setState(() {
      scanResult = code;
      isScanning = false;

      if (code.contains("play.google.com") || code.contains("market://")) {
        isPlayStoreLink = true;
        isVerified = true;
        _openLink(code);
      }
      else if (code.contains("Taxi No:") && code.contains("Driver ID:")) {
        isVerified = true;
        isPlayStoreLink = false;
      }
      else {
        isVerified = false;
        isPlayStoreLink = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR SHIELD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
        centerTitle: true,
        backgroundColor: Colors.black87,
      ),
      body: isScanning
          ? Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      _processQrCode(barcodes.first.rawValue!);
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Align QR code inside the frame to scan safely",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              ],
            )
          : _buildResultScreen(),
    );
  }

  Widget _buildResultScreen() {
    return Container(
      color: isVerified ? Colors.green.shade900.withOpacity(0.2) : Colors.red.shade900.withOpacity(0.2),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVerified ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isVerified ? Colors.greenAccent : Colors.redAccent,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              isVerified 
                  ? (isPlayStoreLink ? "REDIRECTING TO PLAY STORE" : "VERIFIED SAFE")
                  : "FRAUD / INVALID ALERT",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: isVerified ? Colors.greenAccent : Colors.redAccent
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isVerified ? Colors.green : Colors.red),
              ),
              child: Text(
                scanResult ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            if (isVerified) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.copy),
                label: const Text("Copy Data"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: scanResult ?? ""));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Data copied to clipboard!")),
                  );
                },
              ),
              const SizedBox(height: 10),
              if (scanResult!.startsWith("http")) 
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text("Open Link"),
                  onPressed: () => _openLink(scanResult!),
                ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
              onPressed: () {
                setState(() {
                  isScanning = true;
                  scanResult = null;
                });
              },
              child: const Text("Scan Another QR"),
            )
          ],
        ),
      ),
    );
  }
}
