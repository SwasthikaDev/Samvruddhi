// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveFarmData(Map<String, dynamic> farmData) async {
    try {
      String userId = _auth.currentUser!.uid;

      // Convert any remaining LatLng objects (if any) to a saveable format
      farmData = _convertLatLng(farmData);

      await _db.collection('farms').doc(userId).set(farmData);
    } catch (e) {
      print('Error saving farm data: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _convertLatLng(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is LatLng) {
        return MapEntry(key, {'latitude': value.latitude, 'longitude': value.longitude});
      } else if (value is List) {
        return MapEntry(key, value.map((item) {
          if (item is LatLng) {
            return {'latitude': item.latitude, 'longitude': item.longitude};
          }
          return item;
        }).toList());
      } else if (value is Map) {
        return MapEntry(key, _convertLatLng(value as Map<String, dynamic>));
      }
      return MapEntry(key, value);
    });
  }

  Future<Map<String, dynamic>?> getFarmData() async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentSnapshot doc = await _db.collection('farms').doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error getting farm data: $e');
      rethrow;
    }
  }

  // Add this new method
  Stream<DocumentSnapshot> getFarmStream() {
    String userId = _auth.currentUser!.uid;
    return _db.collection('farms').doc(userId).snapshots();
  }
}