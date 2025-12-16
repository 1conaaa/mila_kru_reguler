import 'package:mila_kru_reguler/models/user.dart';

class ApiResponseUser {
  final int success;
  final String token;
  final User user;

  ApiResponseUser({
    required this.success,
    required this.token,
    required this.user,
  });

  factory ApiResponseUser.fromJson(Map<String, dynamic> json) {
    return ApiResponseUser(
      success: json['success'] is int
          ? json['success']
          : int.tryParse(json['success']?.toString() ?? '0') ?? 0,
      token: json['token']?.toString() ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}
