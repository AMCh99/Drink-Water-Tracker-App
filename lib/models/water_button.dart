import 'package:flutter/material.dart';

class WaterButton {
  final int? id;
  final int milliliters;
  final IconData icon;
  final int order; // kolejność wyświetlania
  final bool isFavorite; // czy ulubiony
  final String? assetPath; // opcjonalna ścieżka do ikony SVG

  WaterButton({
    this.id,
    required this.milliliters,
    required this.icon,
    required this.order,
    this.isFavorite = false,
    this.assetPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'milliliters': milliliters,
      'iconCodePoint': icon.codePoint,
      'order': order,
      'isFavorite': isFavorite ? 1 : 0,
      'iconAsset': assetPath,
    };
  }

  factory WaterButton.fromMap(Map<String, dynamic> map) {
    return WaterButton(
      id: map['id'] as int?,
      milliliters: map['milliliters'] as int,
      icon: IconData(map['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      order: map['order'] as int,
      isFavorite: (map['isFavorite'] as int?) == 1,
      assetPath: map['iconAsset'] as String?,
    );
  }

  WaterButton copyWith({
    int? id,
    int? milliliters,
    IconData? icon,
    int? order,
    bool? isFavorite,
    String? assetPath,
  }) {
    return WaterButton(
      id: id ?? this.id,
      milliliters: milliliters ?? this.milliliters,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isFavorite: isFavorite ?? this.isFavorite,
      assetPath: assetPath ?? this.assetPath,
    );
  }

  static const List<int> iconMlSizes = [
    100,
    150,
    250,
    300,
    330,
    500,
    650,
    750,
    1000,
    1500,
  ];

  /// Lista dostępnych assetów SVG dla wyboru ikony.
  static List<String> getIconAssets() {
    return iconMlSizes
        .map((ml) => 'assets/icons/${ml}ml.svg')
        .toList(growable: false);
  }

  /// Mapowanie ml → asset SVG ikony.
  static String? getAssetForMilliliters(int ml) {
    if (!iconMlSizes.contains(ml)) return null;
    return 'assets/icons/${ml}ml.svg';
  }

  /// Dla niestandardowych ilości — znajdź najbliższy SVG
  static String? getClosestAsset(int ml) {
    final exact = getAssetForMilliliters(ml);
    if (exact != null) return exact;

    // Znajdź najbliższą ikonę
    int closest = iconMlSizes.first;
    int minDiff = (ml - closest).abs();
    for (final s in iconMlSizes) {
      final diff = (ml - s).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = s;
      }
    }
    return getAssetForMilliliters(closest);
  }

  // Sugerowane ikony na podstawie pojemności
  static IconData getIconForMilliliters(int ml) {
    if (ml <= 250) {
      return Icons.local_cafe; // mała filiżanka
    } else if (ml <= 400) {
      return Icons.local_drink; // szklanka
    } else if (ml <= 600) {
      return Icons.sports_bar; // większa szklanka
    } else if (ml <= 800) {
      return Icons.local_bar; // butelka
    } else {
      return Icons.water_drop; // duża butelka
    }
  }

  // Domyślne przyciski — 10 rozmiarów z ikonami SVG
  static List<WaterButton> defaultButtons() {
    return [
      for (int i = 0; i < iconMlSizes.length; i++)
        WaterButton(
          milliliters: iconMlSizes[i],
          icon: getIconForMilliliters(iconMlSizes[i]),
          order: i + 1,
          assetPath: getAssetForMilliliters(iconMlSizes[i]),
        ),
    ];
  }
}
