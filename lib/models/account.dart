import 'dart:convert';

class Account {
  const Account({
    required this.name,
    required this.phone,
    this.referralCode,
    this.isVerified = false,
  });

  final String name;
  final String phone;
  final String? referralCode;
  final bool isVerified;

  Account copyWith({
    String? name,
    String? phone,
    String? referralCode,
    bool? isVerified,
  }) {
    return Account(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      referralCode: referralCode ?? this.referralCode,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'referralCode': referralCode,
        'isVerified': isVerified,
      };

  static Account fromJson(Map<String, dynamic> json) {
    return Account(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      referralCode: json['referralCode'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  static List<Account> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    final decoded = json.decode(jsonString);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Account.fromJson)
        .toList();
  }

  static String listToJson(List<Account> accounts) {
    return json.encode(accounts.map((e) => e.toJson()).toList());
  }
}
