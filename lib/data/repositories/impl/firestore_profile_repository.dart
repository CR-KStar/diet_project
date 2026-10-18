import 'package:diet_project/domain/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diet_project/data/repositories/profile_codec.dart';
import 'package:diet_project/domain/repositories/profile_repository.dart';
import 'package:diet_project/config/firestore_collections.dart';

/// Firestore의 `users/{uid}` 문서에 프로필을 저장하는 저장소.
class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(FirestoreCollections.users).doc(uid);

  @override
  Future<SavedProfile?> load(String uid) async {
    final data = (await _doc(uid).get()).data();
    return data == null ? null : ProfileCodec.fromMap(data, userId: uid);
  }

  @override
  Future<void> save(String uid, SavedProfile profile) {
    return _doc(uid).set({
      ...ProfileCodec.toMap(profile),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String uid) => _doc(uid).delete();
}
