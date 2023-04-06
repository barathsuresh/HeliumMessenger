import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider{
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  SettingsProvider({
    required this.prefs,
    required this.firebaseFirestore,
    required this.firebaseStorage
  });

  String? getPrefs(String key){
    return prefs.getString(key);
  }

  Future<bool> setPref(String key, String value) async{
    return await prefs.setString(key, value);
  }

  UploadTask uploadFile(File image, String fileName){
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadT = reference.putFile(image);
    print("Upload completed");
    return uploadT;
  }

  Future<void> updateDataFireStore(String collectionPath,String path,Map<String,String> dataNeedUpdate){
    return firebaseFirestore.collection(collectionPath).doc(path).update(dataNeedUpdate);
  }
}