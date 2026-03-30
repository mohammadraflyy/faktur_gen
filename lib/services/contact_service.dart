import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class ContactService {
  static const _kContacts = 's_contacts';

  static Future<List<ContactModel>> loadAll() async {
    if (AuthService.isLoggedIn) {
      try {
        final snapshot = await FirestoreService.userCollection('contacts').get();
        final contacts = snapshot.docs
            .map((d) => ContactModel.fromMap(d.data()))
            .toList();
        contacts.sort(
            (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
        await _persistLocal(contacts);
        return contacts;
      } catch (_) {
        // Fall through to local
      }
    }
    return _loadLocal();
  }

  static Future<void> save(ContactModel contact) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('contacts')
          .doc(contact.id)
          .set(contact.toMap());
    }
    final contacts = await _loadLocal();
    final idx = contacts.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) {
      contacts[idx] = contact;
    } else {
      contacts.add(contact);
    }
    await _persistLocal(contacts);
  }

  /// Simpan otomatis jika nama belum ada di daftar kontak.
  /// Return true jika kontak baru disimpan.
  static Future<bool> saveIfNotExists({
    required String nama,
    required String npwp,
    required String alamat,
    String telepon = '',
  }) async {
    if (nama.trim().isEmpty) return false;
    final contacts = await loadAll();
    final exists = contacts.any((c) => c.matchesName(nama));
    if (exists) return false;
    final contact = ContactModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama.trim(),
      npwp: npwp.trim(),
      alamat: alamat.trim(),
      telepon: telepon.trim(),
    );
    await save(contact);
    return true;
  }

  static Future<void> delete(String id) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('contacts').doc(id).delete();
    }
    final contacts = await _loadLocal();
    contacts.removeWhere((c) => c.id == id);
    await _persistLocal(contacts);
  }

  static Future<List<ContactModel>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kContacts);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    final contacts = list.map((e) => ContactModel.fromMap(e)).toList();
    contacts.sort(
        (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return contacts;
  }

  static Future<void> _persistLocal(List<ContactModel> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(contacts.map((c) => c.toMap()).toList());
    await prefs.setString(_kContacts, json);
  }
}
