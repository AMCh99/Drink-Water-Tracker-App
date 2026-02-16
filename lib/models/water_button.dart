import 'package:flutter/material.dart';

class WaterButton {
  final int? id;
  final int milliliters;
  final IconData icon;
  final int order; // kolejność wyświetlania
  final bool isFavorite; // czy ulubiony
  final String? assetPath; // opcjonalna ścieżka do własnej ikony PNG

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
    };
  }

  factory WaterButton.fromMap(Map<String, dynamic> map) {
    return WaterButton(
      id: map['id'] as int?,
      milliliters: map['milliliters'] as int,
      icon: IconData(map['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      order: map['order'] as int,
      isFavorite: (map['isFavorite'] as int?) == 1,
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

  /// Mapowanie ml → asset PNG (jeśli istnieje)
  static String? getAssetForMilliliters(int ml) {
    const assetMap = {300: 'assets/icon/300ml.png'};
    return assetMap[ml];
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

  // Domyślne przyciski
  static List<WaterButton> defaultButtons() {
    return [
      WaterButton(milliliters: 250, icon: getIconForMilliliters(250), order: 1),
      WaterButton(
        milliliters: 300,
        icon: getIconForMilliliters(300),
        order: 2,
        assetPath: getAssetForMilliliters(300),
      ),
      WaterButton(milliliters: 400, icon: getIconForMilliliters(400), order: 3),
      WaterButton(milliliters: 500, icon: getIconForMilliliters(500), order: 4),
      WaterButton(milliliters: 650, icon: getIconForMilliliters(650), order: 5),
      WaterButton(milliliters: 750, icon: getIconForMilliliters(750), order: 6),
      WaterButton(
        milliliters: 1000,
        icon: getIconForMilliliters(1000),
        order: 7,
      ),
    ];
  }
}
