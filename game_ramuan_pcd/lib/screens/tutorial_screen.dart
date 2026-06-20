import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialStep> _steps = [
    _TutorialStep(
      emoji: '⚗️',
      title: 'Selamat Datang!',
      description: 'Game Ramuan PCD menggabungkan kemampuan memori '
          'dan pengetahuan pengolahan citra digital (PCD) '
          'dalam pengalaman bermain yang seru!',
      color: AppColors.accent,
    ),
    _TutorialStep(
      emoji: '🧠',
      title: 'Fase 1: Hafal Ramuan',
      description: 'Di awal setiap level, kamu akan melihat urutan ramuan '
          'selama beberapa detik. Hafal urutan bahan-bahan tersebut '
          'dengan baik!',
      color: AppColors.potionPurple,
    ),
    _TutorialStep(
      emoji: '🔀',
      title: 'Fase 2: Susun Ulang',
      description: 'Setelah waktu menghafal habis, ramuan akan diacak. '
          'Tugas kamu adalah menyusunnya kembali ke urutan semula '
          'dengan tap untuk menukar posisi!',
      color: AppColors.potionBlue,
    ),
    _TutorialStep(
      emoji: '🖼️',
      title: 'Fase 3: Filter PCD',
      description: 'Sebuah gambar blur akan muncul. Kamu harus menerapkan '
          'filter pengolahan citra digital (Grayscale, Sharpen, '
          'Edge Detection, dll) secara berurutan sesuai petunjuk!',
      color: AppColors.potionGreen,
    ),
    _TutorialStep(
      emoji: '⭐',
      title: 'Skor & Level',
      description: 'Dapatkan skor berdasarkan kecepatan dan akurasi. '
          'Ada 10 level dengan tingkat kesulitan yang meningkat. '
          'Kamu punya 3 nyawa — selamat bermain!',
      color: AppColors.potionOrange,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgDarkTop,
              AppColors.bgDarkMid,
              AppColors.bgDarkBot,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Tutorial',
                      style: GoogleFonts.cinzel(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Lewati',
                        style: GoogleFonts.poppins(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return _buildPage(step, index);
                  },
                ),
              ),
              // Dots indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingLg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isActive
                            ? _steps[_currentPage].color
                            : AppColors.cardBorder,
                      ),
                    );
                  }),
                ),
              ),
              // Navigation
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSizes.paddingXl,
                  right: AppSizes.paddingXl,
                  bottom: AppSizes.paddingXl,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _steps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _steps[_currentPage].color,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusLg),
                      ),
                    ),
                    child: Text(
                      _currentPage < _steps.length - 1
                          ? 'Selanjutnya'
                          : 'Mulai Bermain!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_TutorialStep step, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji with glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.color.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: step.color.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                step.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            step.title,
            style: GoogleFonts.cinzel(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: step.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            step.description,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Step number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: step.color.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${index + 1} / ${_steps.length}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: step.color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialStep {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _TutorialStep({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}
