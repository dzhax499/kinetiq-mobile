import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/ui/rainbow_transition.dart';
import '../games/kesatria/kesatria_page.dart';
// import '../games/tiru_gaya/tiru_gaya_page.dart';
import '../../core/audio/sound_manager.dart';
import '../../core/ui/snow_background.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late PageController _pageController;
  double _currentPageValue = 1.0; // Start at middle item

  final List<Map<String, dynamic>> games = [
    {
      'title': 'Kesatria PCD',
      'icon': 'assets/images/icongame.png', // Replace with correct later
      'route': '/kesatria'
    },
    {
      'title': 'Geol Kicau Mania',
      'icon': 'assets/images/icongame.png',
      'route': '/geol'
    },
    {
      'title': 'Tiru Gaya',
      'icon': 'assets/images/icongame.png',
      'route': '/tiru_gaya'
    },
    {
      'title': 'FORMULA PCD',
      'icon': 'assets/images/icongame.png',
      'route': '/formula'
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.5, initialPage: 1);
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page!;
      });
    });
    SoundManager().playBgm('audio/background_music.mp3');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showDevInfo() {
    SoundManager().playClick();
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1B1B2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logos (Berdampingan di Tengah)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/polban.png', width: 32, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    Image.asset('assets/images/game_logo.png', width: 48, fit: BoxFit.contain),
                  ],
                ),
                const SizedBox(height: 8),
              const Text(
                'DEVELOPED BY',
                style: TextStyle(fontFamily: 'game_font', color: Color(0xFF00BFFF), fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'TIM KINETIQFUN',
                style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'KELAS 2C - KELOMPOK C9',
                style: TextStyle(fontFamily: 'game_font', color: Color(0xFFFFD700), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: [
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.only(bottom: 6.0), child: Text('Dzakir Tsabit Asy Syafiq', style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 13))),
                        const Padding(padding: EdgeInsets.only(left: 24.0, bottom: 6.0), child: Text('(241511071)', style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 13))),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.only(bottom: 6.0), child: Text('Helga Athifa Hidayat', style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 13))),
                        const Padding(padding: EdgeInsets.only(left: 24.0, bottom: 6.0), child: Text('(241511077)', style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 13))),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.only(bottom: 6.0), child: Text('Nike Kustiane', style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 13))),
                        const Padding(padding: EdgeInsets.only(left: 24.0, bottom: 6.0), child: Text('(241511086)', style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 13))),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.only(bottom: 6.0), child: Text('Wyandhanu Maulidan Nugraha', style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 13))),
                        const Padding(padding: EdgeInsets.only(left: 24.0, bottom: 6.0), child: Text('(241511092)', style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 13))),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    SoundManager().playClick();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'TUTUP',
                    style: TextStyle(fontFamily: 'game_font', color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
  );
}

  void _navigateToGame(String route) {
    SoundManager().playClick();
    _showModeSelectionDialog(route);
  }

  void _showModeSelectionDialog(String route) {
    showDialog(
      context: context,
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Kotak Dialog di tengah
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E), // Warna gelap
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.cyanAccent, width: 3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PILIH MODE MAIN',
                          style: TextStyle(
                            fontFamily: 'game_font',
                            fontSize: 28,
                            color: Colors.cyanAccent,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildModeButton('MAIN SENDIRI', () {
                          SoundManager().playClick();
                          Navigator.of(context).pop();
                          _proceedToGame(route, 1);
                        }),
                        const SizedBox(height: 16),
                        _buildModeButton('MAIN BERDUA', () {
                          SoundManager().playClick();
                          Navigator.of(context).pop();
                          _proceedToGame(route, 2);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'game_font',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _proceedToGame(String route, int players) {
    if (route == '/kesatria') {
      SoundManager().stopBgm();
      Navigator.of(context).push(RainbowPageRoute(page: KesatriaPage(playerCount: players)));
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.indigo[900],
          title: const Text('Segera Hadir', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Game ini masih dalam tahap pengembangan oleh tim.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                SoundManager().playClick();
                Navigator.of(context).pop();
              },
              child: const Text('Tutup', style: TextStyle(color: Colors.pinkAccent)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background like Native
      body: Stack(
        children: [
          // Background (SnowBackground)
          Positioned.fill(
            child: SnowBackground(
              child: const SizedBox.expand(),
            ),
          ),
          
          SafeArea(
            child: Stack(
              children: [
                // Top Left Logo
                Positioned(
                  top: 16,
                  left: 16,
                  child: Image.asset(
                    'assets/images/game_logo.png',
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                ),

                // Top Right Info Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: const Color(0xFF03A9F4),
                    borderRadius: BorderRadius.circular(4),
                    elevation: 8,
                    child: InkWell(
                      onTap: _showDevInfo,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: const Text(
                          "!",
                          style: TextStyle(
                            fontFamily: 'game_font',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Title: Select Game
                const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(
                      "Select Game",
                      style: TextStyle(
                        fontFamily: 'game_font',
                        fontSize: 32,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(3, 3))],
                      ),
                    ),
                  ),
                ),

                // Carousel
                Column(
                  children: [
                    const SizedBox(height: 100), // Space for top elements
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final isSelected = (_currentPageValue.round() == index);
                          
                          // Math for tilt and blur
                          double difference = index - _currentPageValue;
                          
                          // Scale: middle is 1.0, edges are 0.8
                          double scale = 1.0 - (difference.abs() * 0.2).clamp(0.0, 0.2);
                          
                          // Tilt: Y-axis rotation based on distance from center
                          double tilt = difference * 0.5; // radians (approx 30 deg at edges)
                          
                          // Blur: 0 at center, max 10 at edges
                          double blurAmount = (difference.abs() * 5.0).clamp(0.0, 10.0);

                          Widget card = GestureDetector(
                            onTap: () {
                              if (isSelected) {
                                _navigateToGame(games[index]['route']);
                              } else {
                                _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              }
                            },
                            child: SizedBox(
                              width: 320,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Cardbox Container
                                  Image.asset('assets/images/cardbox.png', fit: BoxFit.contain, width: 320),
                                  
                                  // Screenshot Placeholder (Ratio 16:9)
                                  Align(
                                    alignment: const Alignment(0, -0.16),
                                    child: FractionallySizedBox(
                                      widthFactor: 0.65,
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Container(
                                          color: Colors.black,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            "TANGKAP LAYAR GAME",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'game_font',
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Judul Game
                                  Positioned(
                                    bottom: 28,
                                    left: 16,
                                    right: 16,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        games[index]['title'].toString().toUpperCase(),
                                        style: const TextStyle(
                                          fontFamily: 'game_font',
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  
                                  // Overlay Efek Gelap (Alpha based on distance)
                                  if (blurAmount > 0.1)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(alpha: (difference.abs() * 0.6).clamp(0.0, 0.6)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );

                          // Apply ImageFilter for Blur (Only applies effectively to non-selected items)
                          if (blurAmount > 0.1) {
                            card = ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                              child: card,
                            );
                          }

                          // Apply Transform
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // perspective
                              ..rotateY(-tilt)
                              ..scaleByDouble(scale, scale, 1.0, 1.0),
                            child: Opacity(
                              opacity: 1.0 - (difference.abs() * 0.3).clamp(0.0, 0.5),
                              child: card,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
