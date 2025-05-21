import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbQ6Etnfs4HNb9yDkMz9ZxkwFYhnPmZPY',
    appId: '1:956844075381:android:8c0f75ba14625dad764b3c',
    messagingSenderId: '956844075381',
    projectId: 'edaapp-581a3',
    storageBucket: 'edaapp-581a3.firebasestorage.app',
  );
}
