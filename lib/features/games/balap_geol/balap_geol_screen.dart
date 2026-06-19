import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'balap_geol_logic.dart';
import '../../../core/audio/sound_manager.dart';

class BalapGeolScreen extends StatefulWidget {
  const BalapGeolScreen({Key? key}) : super(key: key);

  @override
  State<BalapGeolScreen> createState() => _BalapGeolScreenState();
}

class _BalapGeolScreenState extends State<BalapGeolScreen> with SingleTickerProviderStateMixin {
  final BalapGeolLogic _gameLogic = BalapGeolLogic();
  late AnimationController _gameTicker;
  
  // Posisi mobil pemain (X axis, range: -1.0 to 1.0)
  double _carPositionX = 0.0;
  
  // Posisi rintangan (X, Y)
  double _obstacleX = 0.0;
  double _obstacleY = -1.0;
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _startGameLoop();
    _listenToSensors();
  }

  void _startGameLoop() {
    _gameTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Tick interval
    )..addListener(() {
        if (!_gameLogic.isGameOver) {
          _updateObstaclePosition();
        }
      });
    _gameTicker.repeat();
  }

  void _listenToSensors() {
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_gameLogic.isGameOver) return;
      
      setState(() {
        // Karena app menggunakan Landscape Mode, kita ambil sumbu Y untuk deteksi miring Kiri/Kanan
        // Sesuaikan dengan orientasi aslimu nanti
        _carPositionX -= (event.y * 0.05);
        // Batasi pergerakan agar tidak keluar layar
        if (_carPositionX < -1.0) _carPositionX = -1.0;
        if (_carPositionX > 1.0) _carPositionX = 1.0;
      });
    });
  }

  void _updateObstaclePosition() {
    setState(() {
      _obstacleY += 0.02; // Kecepatan turun rintangan
      
      // Deteksi tabrakan
      if (_obstacleY > 0.8 && (_carPositionX - _obstacleX).abs() < 0.2) {
        _gameLogic.setGameOver();
        SoundManager().playAction(); // Mainkan efek suara tabrakan
      }

      // Jika rintangan lewat, skor bertambah dan rintangan di-reset
      if (_obstacleY > 1.2) {
        _obstacleY = -1.0;
        // Rintangan muncul di posisi acak X
        _obstacleX = (DateTime.now().millisecond % 200) / 100 - 1.0; 
        _gameLogic.updateScore(10);
      }
    });
  }

  @override
  void dispose() {
    _gameTicker.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Warna aspal
      body: Stack(
        children: [
          // Garis jalan (Dekorasi)
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 10,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          
          // Rintangan (Kotak Merah Sementara)
          Align(
            alignment: Alignment(_obstacleX, _obstacleY),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.white),
            ),
          ),

          // Mobil Pemain (Kotak Biru Sementara)
          Align(
            alignment: Alignment(_carPositionX, 0.8),
            child: Container(
              width: 60,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: const Icon(Icons.directions_car, color: Colors.white, size: 40),
            ),
          ),

          // Skor UI
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              'Skor: ${_gameLogic.score}',
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Game Over Overlay
          if (_gameLogic.isGameOver)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TABRAKAN!',
                      style: TextStyle(color: Colors.redAccent, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Skor Akhir: ${_gameLogic.score}',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _gameLogic.resetGame();
                          _obstacleY = -1.0;
                        });
                      },
                      child: const Text('Main Lagi'),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
