import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helium_messenger/Constants/constants.dart';

class UserChat{
  String id;
  String photoUrl;
  String phoneNumber;
  String aboutMe;
  String nickname;

  UserChat({required this.id,required this.nickname,required this.photoUrl,required this.phoneNumber,required this.aboutMe});

  Map<String,String> toJSON(){
    return{
      firestore_constants.nickname : nickname,
      firestore_constants.aboutMe : aboutMe,
      firestore_constants.photoUrl : photoUrl,
      firestore_constants.phoneNumber : phoneNumber
    };
  }

  factory UserChat.fromDocument(DocumentSnapshot doc){
    String aboutMe="";
    String photoUrl="";
    String nickname="";
    String phoneNumber="";

    try{
      aboutMe = doc.get(firestore_constants.aboutMe);
    }catch(e){}

    try{
      photoUrl = doc.get(firestore_constants.photoUrl);
    }catch(e){}

    try{
      nickname = doc.get(firestore_constants.nickname);
    }catch(e){}

    try{
      phoneNumber = doc.get(firestore_constants.phoneNumber);
    }catch(e){}

    return UserChat(id: doc.id, nickname: nickname, photoUrl: photoUrl, phoneNumber: phoneNumber, aboutMe: aboutMe);
  }

}