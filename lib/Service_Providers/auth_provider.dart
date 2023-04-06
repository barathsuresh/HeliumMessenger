import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helium_messenger/Constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Models/UserChat.dart';

enum Status{
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateCancelled,
}

class AuthProvider extends ChangeNotifier{
  late final GoogleSignIn googleSignIn;
  late final FirebaseAuth firebaseAuth;
  late final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;
  Status _status = Status.uninitialized;
  Status get status => _status;

  AuthProvider({required this.firebaseAuth,required this.googleSignIn,required this.prefs,required this.firebaseFirestore});

  String? getUserFirebaseId(){
    return prefs.getString(firestore_constants.id);
  }

  Future<bool> isLoggedIn() async{
    bool isLoggedIn = await googleSignIn.isSignedIn();

    if(isLoggedIn && prefs.getString(firestore_constants.id)?.isNotEmpty == true){
      return true;
    }
    else{
      return false;
    }
  }

  Future<bool> handleSignIn() async{
    _status = Status.authenticating;
    notifyListeners();

    GoogleSignInAccount? gUser = await googleSignIn.signIn();

    if(gUser != null){
      print("Checked gUser Not Null");
      GoogleSignInAuthentication googleAuth = await gUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      var temp = await firebaseAuth.signInWithCredential(credential);
      User? firebaseUser = temp.user;

      if(firebaseUser != null){
        final QuerySnapshot res = await firebaseFirestore.collection(firestore_constants.pathUserCollection).where(firestore_constants.id, isEqualTo: firebaseUser.uid).get();
        final List<DocumentSnapshot> document = res.docs;
        if(document.length == 0){
          firebaseFirestore.collection(firestore_constants.pathUserCollection).doc(firebaseUser.uid).set(
              {
                firestore_constants.nickname:firebaseUser.displayName,
                firestore_constants.photoUrl:firebaseUser.photoURL,
                firestore_constants.id:firebaseUser.uid,
                "createdAt":DateTime.now().microsecondsSinceEpoch.toString(),
                firestore_constants.chattingWith:null
              });
          User? currentUser = firebaseUser;
          await prefs.setString(firestore_constants.id,currentUser.uid);
          await prefs.setString(firestore_constants.nickname, currentUser.displayName ?? "");
          await prefs.setString(firestore_constants.photoUrl, currentUser.photoURL ?? "");
          await prefs.setString(firestore_constants.phoneNumber, currentUser.phoneNumber ?? "");
        }
        else{
          DocumentSnapshot snapshot = document[0];
          UserChat userChat = UserChat.fromDocument(snapshot);

          await prefs.setString(firestore_constants.id,userChat.id);
          await prefs.setString(firestore_constants.nickname,userChat.nickname);
          await prefs.setString(firestore_constants.photoUrl,userChat.photoUrl);
          await prefs.setString(firestore_constants.phoneNumber,userChat.phoneNumber);
          await prefs.setString(firestore_constants.aboutMe,userChat.aboutMe);
        }
        _status = Status.authenticated;
        notifyListeners();
        return true;
      }else{
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }
    }else{
      _status = Status.authenticateCancelled;
      notifyListeners();
      return false;
    }
  }

  Future<void> handleSignOut() async{
    _status = Status.uninitialized;
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

  }

}