import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/game_widgets.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _tutorialSteps = [
    _TutorialStep(
      icon: Icons.people_rounded,
      title: 'Siapkan 2 Pemain',
      description:
          'KinetiQ adalah game party 2 pemain! Masukkan nama kalian di halaman Setup.',
      color: AppTheme.primaryCyan,
      tips: ['Pilih nama yang unik untuk setiap pemain'],
    ),
    _TutorialStep(
      icon: Icons.image_rounded,
      title: 'Perhatikan Pose Referensi',
      description:
          'Setiap ronde, akan muncul gambar pose yang harus ditiru. Perhatikan bentuk skeleton-nya!',
      color: AppTheme.accentPurple,
      tips: [
        'Lihat posisi tangan, kaki, dan badan',
        'Ada kategori: Huruf, Alam, Yoga, Hewan',
      ],
    ),
    _TutorialStep(
      icon: Icons.timer_rounded,
      title: 'Fase Berpikir',
      description:
          'Kamu akan diberi waktu untuk memikirkan bagaimana cara menirukan pose tersebut.',
      color: AppTheme.accentYellow,
      tips: [
        'Mudah: 10 detik',
        'Sedang: 7 detik',
        'Sulit: 5 detik',
      ],
    ),
    _TutorialStep(
      icon: Icons.accessibility_new_rounded,
      title: 'Fase Pose',
      description:
          'Waktunya berpose! Atur posisi tubuhmu untuk meniru pose referensi sebaik mungkin.',
      color: AppTheme.accentGreen,
      tips: [
        'Pastikan seluruh tubuhmu terlihat di kamera',
        'Skeleton akan muncul real-time di layar',
        'Pose terakhirmu saat waktu habis yang dihitung!',
      ],
    ),
    _TutorialStep(
      icon: Icons.camera_alt_rounded,
      title: '📸 CKREK!',
      description:
          'Pada detik terakhir, kamera akan memfoto posemu secara otomatis. Ini adalah pose yang akan dinilai.',
      color: AppTheme.secondaryPink,
      tips: ['Pastikan kamu sudah dalam pose terbaik saat waktu habis!'],
    ),
    _TutorialStep(
      icon: Icons.analytics_rounded,
      title: 'Analisis Kemiripan',
      description:
          'Sistem akan menganalisis posemu menggunakan teknik Pengolahan Citra Digital.',
      color: AppTheme.primaryCyan,
      tips: [
        'Grayscale → Gaussian Blur → Thresholding',
        'Cosine Similarity untuk membandingkan pose',
        'Skor 0-100% kemiripan',
      ],
    ),
    _TutorialStep(
      icon: Icons.emoji_events_rounded,
      title: 'Menang!',
      description:
          'Pemain dengan skor kemiripan tertinggi memenangkan ronde. Setelah semua ronde, pemenang keseluruhan diumumkan!',
      color: AppTheme.accentYellow,
      tips: [
        '< 30% = Kurang Mirip 🔴',
        '30-60% = Cukup Mirip 🟡',
        '60-85% = Mirip! 🟢',
        '85-100% = Sangat Mirip! 💚',
      ],
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
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppTheme.textPrimary,
                    ),
                    const Expanded(
                      child: Text(
                        'CARA BERMAIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Page indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: List.generate(_tutorialSteps.length, (i) {
                    final isActive = i == _currentPage;
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive
                              ? _tutorialSteps[i].color
                              : AppTheme.bgCardLight,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Tutorial pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  itemCount: _tutorialSteps.length,
                  itemBuilder: (context, index) {
                    return _buildTutorialPage(_tutorialSteps[index], index);
                  },
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('SEBELUMNYA'),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _tutorialSteps.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppTheme.bgDark,
                          ),
                          child: Text(
                            _currentPage < _tutorialSteps.length - 1
                                ? 'LANJUT'
                                : 'SELESAI',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialPage(_TutorialStep step, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.color.withValues(alpha: 0.15),
              border: Border.all(
                color: step.color.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(step.icon, size: 48, color: step.color),
          ),

          const SizedBox(height: 32),

          // Step number
          Text(
            'LANGKAH ${index + 1}',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: step.color,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Tips
          if (step.tips.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: AppTheme.glassDecoration(
                borderColor: step.color.withValues(alpha: 0.2),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: step.tips.map((tip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right_rounded,
                          size: 20,
                          color: step.color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<String> tips;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.tips = const [],
  });
}
