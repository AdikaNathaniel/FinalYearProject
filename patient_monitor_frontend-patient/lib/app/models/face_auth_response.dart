import 'package:patient_monitor/app/models/user_model.dart';

class FaceAuthResponse {
  final bool success;
  final String? accessToken;
  final User? user;
  final double? distance;
  final String? message;

  FaceAuthResponse({
    required this.success,
    this.accessToken,
    this.user,
    this.distance,
    this.message,
  });

  factory FaceAuthResponse.fromJson(Map<String, dynamic> json) {
    return FaceAuthResponse(
      success: json['success'],
      accessToken: json['access_token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      distance: json['distance']?.toDouble(),
      message: json['message'],
    );
  }
}