import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:helium_messenger/Constants/constants.dart';
import 'package:helium_messenger/Models/encrypt_decrypt.dart';
import 'package:helium_messenger/Models/message_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider{
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  //TODO my work



  ChatProvider({required this.prefs,required this.firebaseStorage,required this.firebaseFirestore});

  UploadTask uploadFile(File image,String filename){
    Reference reference = firebaseStorage.ref().child(filename);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, dynamic> dataNeedUpdate){
    return firebaseFirestore.collection(collectionPath).doc(docPath).update(dataNeedUpdate);
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit){
    print("chat stream");
    return firebaseFirestore
        .collection(firestore_constants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(firestore_constants.timestamp,descending: true)
        .limit(limit)
        .snapshots();
  }

  void sendMessage(String content,int type,String groupChatId,String currentUserId,String peerId){
    DocumentReference documentReference = firebaseFirestore
        .collection(firestore_constants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(DateTime.now().microsecondsSinceEpoch.toString());

    content = EncryptionDecryption.encryptMessage(content); //todo encrypt

    MessageChat messageChat = MessageChat(idFrom: currentUserId, idTo: peerId, timestamp: DateTime.now().microsecondsSinceEpoch.toString(), content: content, type: type);

    firebaseFirestore.runTransaction((transaction) async{
      transaction.set(documentReference,messageChat.toJSON());
      print("completed");
    });
  }
}

class TypeMessage{
  static const text=0;
  static const image=1;
  static const sticker=2;
}