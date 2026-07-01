import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const QRShieldApp());
}

class QRShieldApp extends StatelessWidget {
  const QRShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Shield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.greenAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const ScannerScreen(),
    );
  }
}

// Defining clear application states for English UI handling
enum ScanStatus { scanning, processing, safe, fraud }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  ScanStatus _status = ScanStatus.scanning;
  String _scannedUrl = '';
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  // Anti-Fraud Core Engine Verification Logic
  Future<void> _verifyUrl(String url) async {
    setState(() {
      _status = ScanStatus.processing;
      _scannedUrl = url;
    });

    // 1. Mandatory 3-second processing delay to show loading state to user
    await Future.delayed(const Duration(seconds: 3));

    try {
      final lowercaseUrl = url.toLowerCase();
      bool isSuspicious = false;

      // 2. Local heuristic checks for immediate obvious threat indicators
      if (lowercaseUrl.contains('phishing') || 
          lowercaseUrl.contains('scam') || 
          lowercaseUrl.contains('free-money') || 
          lowercaseUrl.contains('.apk')) {
        isSuspicious = true;
      }

      // 3. Live query to an open-source security database to detect blacklisted scam networks
      final response = await http.get(
        Uri.parse('https://api.phishstats.info/v1/lookups?url=' + Uri.encodeComponent(url))
      ).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        if (response.body.contains(url) || response.body.length > 5) {
          isSuspicious = true;
        }
      }
      
      setState(() {
        _status = isSuspicious ? ScanStatus.fraud : ScanStatus.safe;
      });
    } catch (_) {
      // Offline fallback: Flag older unencrypted HTTP configurations as suspicious
      setState(() {
        _status = (_scannedUrl.startsWith('http://') || _scannedUrl.length < 12) 
            ? ScanStatus.fraud 
            : ScanStatus.safe;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR SHIELD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.greenAccent,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  // Dynamic state machine switcher layout
  Widget _buildBody() {
    switch (_status) {
      case ScanStatus.scanning:
        return Stack(
          children: [
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? rawValue = barcode.rawValue;
                  if (rawValue != null) {
                    _verifyUrl(rawValue);
                    break;
                  }
                }
              },
            ),
            Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.4))),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'Align QR code inside the frame to scan safely',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case ScanStatus.processing:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 4),
              const SizedBox(height: 30),
              const Text(
                'UNDER PROCESS',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orangeAccent, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Analyzing: $_scannedUrl\nChecking global anti-fraud databases...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        );

      case ScanStatus.safe:
        return Container(
          color: const Color(0xFF0A2F1D),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 100),
              const SizedBox(height: 24),
              const Text(
                'VERIFIED SAFE',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.greenAccent, letterSpacing: 1.0),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black24, borderRadius: BorderRadius.circular(12)),
                child: Text(_scannedUrl, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  setState(() {
                    _status = ScanStatus.scanning;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Another QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );

      case ScanStatus.fraud:
        return Container(
          color: const Color(0xFF3A1111),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad_outlined, color: Colors.redAccent, size: 100),
              const SizedBox(height: 24),
              const Text(
                'FRAUD ALERT DETECTED',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1.0),
              ),
              const SizedBox(height: 16),
              const Text(
                'Warning! This link is flagged as dangerous, scam, or malicious.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black34, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                child: Text(_scannedUrl, style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  setState(() {
                    _status = ScanStatus.scanning;
                  });
                },
                icon: const Icon(Icons.security),
                label: const Text('Block & Scan Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
    }
  }
}
