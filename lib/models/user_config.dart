class UserConfig {
  final int? id;
  final String userName;
  final double dailyLimit;
  final String currency;

  UserConfig({
    this.id,
    required this.userName,
    required this.dailyLimit,
    required this.currency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_name': userName,
      'daily_limit': dailyLimit,
      'currency': currency,
    };
  }

  factory UserConfig.fromMap(Map<String, dynamic> map) {
    return UserConfig(
      id: map['id'],
      userName: map['user_name'],
      dailyLimit: map['daily_limit'],
      currency: map['currency'],
    );
  }

  UserConfig copyWith({
    int? id,
    String? userName,
    double? dailyLimit,
    String? currency,
  }) {
    return UserConfig(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      currency: currency ?? this.currency,
    );
  }
}
