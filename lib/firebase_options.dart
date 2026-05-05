import 'package:firebase_core/firebase_core.dart';
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDKAfqjHpJ22tr4n94y9F5XXVf2NYYEbI0",
    appId: "1:700277316826:web:27062dd0d1d00733a1d9e3",
    messagingSenderId: "700277316826",
    projectId: "flutter-4e0eb",
    authDomain: "flutter-4e0eb.firebaseapp.com",
    storageBucket: "flutter-4e0eb.firebasestorage.app",
  );

static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCFrDCPfAiiY8GHTNFVwtC8pZD9kjEmCq0",
    appId: "1:700277316826:android:bb4d58f8cb7bf987a1d9e3",
    messagingSenderId: "700277316826",
    projectId: "flutter-4e0eb",
    storageBucket: "flutter-4e0eb.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD9aTp-YjrboyXZt5O5kuCE62o3319mxH0',
    appId: '1:700277316826:ios:6d07b61fb02aa71ca1d9e3',
    messagingSenderId: '700277316826',
    projectId: 'flutter-4e0eb',
    storageBucket: 'flutter-4e0eb.firebasestorage.app',
    iosBundleId: 'com.example.myApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD9aTp-YjrboyXZt5O5kuCE62o3319mxH0',
    appId: '1:700277316826:ios:6d07b61fb02aa71ca1d9e3',
    messagingSenderId: '700277316826',
    projectId: 'flutter-4e0eb',
    storageBucket: 'flutter-4e0eb.firebasestorage.app',
    iosBundleId: 'com.example.myApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDKAfqjHpJ22tr4n94y9F5XXVf2NYYEbI0',
    appId: '1:700277316826:web:27062dd0d1d00733a1d9e3',
    messagingSenderId: '700277316826',
    projectId: 'flutter-4e0eb',
    authDomain: 'flutter-4e0eb.firebaseapp.com',
    storageBucket: 'flutter-4e0eb.firebasestorage.app',
    measurementId: 'G-DKXPC4N73B',
  );

}