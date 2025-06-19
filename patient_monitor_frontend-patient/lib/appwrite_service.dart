import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class AppwriteService extends ChangeNotifier {
  // Appwrite constants
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = '682d4f730001443567d3'; // Replace with your project ID
  
  // Appwrite client
  late final Client client;
  late final Account account;
  
  // User state
  Map<String, dynamic>? currentUser;
  
  AppwriteService() {
    _initAppwrite();
  }
  
  void _initAppwrite() {
    client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setSelfSigned(status: true); // For development only
    
    account = Account(client);
  }
  
  // Future<Session> login(String password) async {
  //   try {
  //     // Create a new session 
  //     // final session = await account.createSession(
  //     //   email: email,
  //     //   password: password,
  //     // );

  //     final session = await account.createAnonymousSession();

  //     // Get user data
  //     currentUser = await _getUserData();
  //     notifyListeners();
      
  //     return session;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }


  Future<Session> login() async {
  try {
    final session = await account.createAnonymousSession();

    currentUser = await _getUserData();
    notifyListeners();
    return session;
  } catch (e) {
    rethrow;
  }
}

  
  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
      currentUser = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      currentUser = await _getUserData();
      return currentUser;
    } catch (e) {
      currentUser = null;
      return null;
    }
  }
  
  Future<Map<String, dynamic>> _getUserData() async {
    try {
      final userData = await account.get();
      return userData.toMap();
    } catch (e) {
      rethrow;
    }
  }
}