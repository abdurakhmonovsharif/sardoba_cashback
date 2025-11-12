class LoyaltySummary {
  const LoyaltySummary({
    this.level,
    this.currentPoints,
    this.currentLevelMin,
    this.currentLevelMax,
    this.currentLevelPoints,
    this.nextLevel,
    this.nextLevelPoints,
    this.pointsToNext,
    this.isMaxLevel = false,
  });

  final String? level;
  final double? currentPoints;
  final double? currentLevelMin;
  final double? currentLevelMax;
  final double? currentLevelPoints;
  final String? nextLevel;
  final double? nextLevelPoints;
  final double? pointsToNext;
  final bool isMaxLevel;

  factory LoyaltySummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LoyaltySummary();
    return LoyaltySummary(
      level: json['level'] as String?,
      currentPoints: _toDouble(json['current_points']),
      currentLevelMin: _toDouble(json['current_level_min']),
      currentLevelMax: _toDouble(json['current_level_max']),
      currentLevelPoints: _toDouble(json['current_level_points']),
      nextLevel: json['next_level'] as String?,
      nextLevelPoints: _toDouble(json['next_level_points']),
      pointsToNext: _toDouble(json['points_to_next']),
      isMaxLevel: json['is_max_level'] as bool? ?? false,
    );
  }

  LoyaltySummary copyWith({
    String? level,
    double? currentPoints,
    double? currentLevelMin,
    double? currentLevelMax,
    double? currentLevelPoints,
    String? nextLevel,
    double? nextLevelPoints,
    double? pointsToNext,
    bool? isMaxLevel,
  }) {
    return LoyaltySummary(
      level: level ?? this.level,
      currentPoints: currentPoints ?? this.currentPoints,
      currentLevelMin: currentLevelMin ?? this.currentLevelMin,
      currentLevelMax: currentLevelMax ?? this.currentLevelMax,
      currentLevelPoints: currentLevelPoints ?? this.currentLevelPoints,
      nextLevel: nextLevel ?? this.nextLevel,
      nextLevelPoints: nextLevelPoints ?? this.nextLevelPoints,
      pointsToNext: pointsToNext ?? this.pointsToNext,
      isMaxLevel: isMaxLevel ?? this.isMaxLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'current_points': currentPoints,
      'current_level_min': currentLevelMin,
      'current_level_max': currentLevelMax,
      'current_level_points': currentLevelPoints,
      'next_level': nextLevel,
      'next_level_points': nextLevelPoints,
      'points_to_next': pointsToNext,
      'is_max_level': isMaxLevel,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
