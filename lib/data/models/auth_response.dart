import 'user.dart';

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['access_token'] as String,
    tokenType: json['token_type'] as String? ?? 'bearer',
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );
}
