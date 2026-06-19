import 'package:flutter/material.dart';
import '../../../core/audio/sound_manager.dart';
import 'balap_geol_screen.dart';

class BalapGeolLoadingScreen extends StatefulWidget {
  const BalapGeolLoadingScreen({Key? key}) : super(key: key);

  @override
  State<BalapGeolLoadingScreen> createState() => _BalapGeolLoadingScreenState();
}

class _BalapGeolLoadingScreenState extends State<BalapGeolLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    // Memutar background music dari SoundManager
    try {
      await SoundManager().playBgm('audio/balap_geol_bgm_placeholder.txt');
    } catch (e) {
      debugPrint("Gagal memutar audio: $e");
    }

    // Simulasi loading 3 detik sebelum masuk game
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BalapGeolScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(
              color: Colors.blueAccent,
              strokeWidth: 6.0,
            ),
            SizedBox(height: 30),
            Text(
              'Memuat Balap Geol... Mohon Tunggu',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
