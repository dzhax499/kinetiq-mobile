import 'package:flutter/material.dart';
import '../utils/constants.dart';

class Potion {
  final int id;
  final String name;
  final String emoji;
  final Color color;
  final Color glowColor;
  final String description;

  const Potion({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.glowColor,
    required this.description,
  });

  static const List<Potion> allPotions = [
    Potion(
      id: 0,
      name: 'Api Merah',
      emoji: '🔥',
      color: AppColors.potionRed,
      glowColor: AppColors.potionRed,
      description: 'Esensi api yang membakar',
    ),
    Potion(
      id: 1,
      name: 'Air Biru',
      emoji: '💧',
      color: AppColors.potionBlue,
      glowColor: AppColors.potionBlue,
      description: 'Tetesan air murni',
    ),
    Potion(
      id: 2,
      name: 'Daun Hijau',
      emoji: '🌿',
      color: AppColors.potionGreen,
      glowColor: AppColors.potionGreen,
      description: 'Daun herbal segar',
    ),
    Potion(
      id: 3,
      name: 'Kristal Ungu',
      emoji: '💎',
      color: AppColors.potionPurple,
      glowColor: AppColors.potionPurple,
      description: 'Kristal mistis berkilau',
    ),
    Potion(
      id: 4,
      name: 'Madu Emas',
      emoji: '🍯',
      color: AppColors.potionOrange,
      glowColor: AppColors.potionOrange,
      description: 'Madu langka nan manis',
    ),
    Potion(
      id: 5,
      name: 'Es Cyan',
      emoji: '❄️',
      color: AppColors.potionCyan,
      glowColor: AppColors.potionCyan,
      description: 'Pecahan es abadi',
    ),
    Potion(
      id: 6,
      name: 'Bunga Sakura',
      emoji: '🌸',
      color: AppColors.potionPink,
      glowColor: AppColors.potionPink,
      description: 'Kelopak bunga ajaib',
    ),
    Potion(
      id: 7,
      name: 'Bintang Kuning',
      emoji: '⭐',
      color: AppColors.potionYellow,
      glowColor: AppColors.potionYellow,
      description: 'Debu bintang langit',
    ),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Potion && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
