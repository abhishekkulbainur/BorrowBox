// File generated for BorrowBox Firebase initialization.
// Replace placeholder values with credentials from your Firebase Console
// or generate automatically using: `flutterfire configure`

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web Configuration (from Firebase Console -> Project Settings -> General -> Your Apps -> Web)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'borrowbox-app',
    authDomain: 'borrowbox-app.firebaseapp.com',
    storageBucket: 'borrowbox-app.appspot.com',
  );

  // Android Configuration (from google-services.json)

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQLDgqGaHbP8uIpouCf0j9utW63mmvXJQ',
    appId: '1:432506983215:android:6bae4e268c33a6d3c547da',
    messagingSenderId: '432506983215',
    projectId: 'borrowbox-app-78b81',
    storageBucket: 'borrowbox-app-78b81.firebasestorage.app',
  );
  // iOS Configuration (from GoogleService-Info.plist)

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAG3i6eeq3PdrfM9J82S-8rA4J_hckniv0',
    appId: '1:432506983215:ios:07805459d6f1f20dc547da',
    messagingSenderId: '432506983215',
    projectId: 'borrowbox-app-78b81',
    storageBucket: 'borrowbox-app-78b81.firebasestorage.app',
    iosBundleId: 'de.oppahansi.lendnborrow',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'borrowbox-app',
    storageBucket: 'borrowbox-app.appspot.com',
    iosBundleId: 'de.oppahansi.lendnborrow',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'borrowbox-app',
    authDomain: 'borrowbox-app.firebaseapp.com',
    storageBucket: 'borrowbox-app.appspot.com',
  );
}
