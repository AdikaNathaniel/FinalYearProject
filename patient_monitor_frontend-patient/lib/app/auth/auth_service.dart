import 'package:patient_monitor/app/models/face_auth_response.dart';
import 'package:patient_monitor/app/utils/http_client.dart';

class AuthService {
  static Future<FaceAuthResponse> verifyFace(List<double> descriptor) async {
    final response = await HttpClient.post('auth/login', {
      'descriptor': descriptor,
    });
    return FaceAuthResponse.fromJson(response);
  }

  static Future<dynamic> registerUser(
    String username,
    String role,
    List<double> descriptor,
  ) async {
    return await HttpClient.post('face-auth', {
      'userId': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'username': username,
      'role': role,
      'faceDescriptor': descriptor,
    });
  }

  static Future<dynamic> getAllUsers() async {
    return await HttpClient.get('face-auth/descriptors');
  }
  
  // Add this method to fix the deleteUser error
  static Future<dynamic> deleteUser(String userId) async {
    return await HttpClient.delete('face-auth/$userId');
  }
}