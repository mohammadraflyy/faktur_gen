import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class FirestoreService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> userDoc(String path) {
    return _db.collection('users').doc(AuthService.uid).collection('profile').doc(path);
  }

  static CollectionReference<Map<String, dynamic>> userCollection(String name) {
    return _db.collection('users').doc(AuthService.uid).collection(name);
  }

  static DocumentReference<Map<String, dynamic>> metaDoc(String name) {
    return _db.collection('users').doc(AuthService.uid).collection('meta').doc(name);
  }
}
