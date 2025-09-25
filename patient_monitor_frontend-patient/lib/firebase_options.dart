import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyB9nik0iTDHuxpAPfiVqmm4hMqbtzqWGLc',
      authDomain: 'pregmonitor.firebaseapp.com',
      projectId: 'pregmonitor',
      storageBucket: 'pregmonitor.firebasestorage.app',
      messagingSenderId: '962894089311',
      appId: '1:962894089311:web:01cce8039c9629dc85dfea',
      measurementId: 'G-5NBVYPFCKR',
    );
  }
}