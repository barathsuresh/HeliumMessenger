import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helium_messenger/Constants/constants.dart';

class MessageChat{
  String idFrom;
  String idTo;
  String timestamp;
  String content;
  int type;

  MessageChat({required this.idFrom,required this.idTo,required this.timestamp,required this.content,required this.type});

  Map<String,dynamic> toJSON(){
    return{
      firestore_constants.idFrom:this.idFrom,
      firestore_constants.idTo:this.idTo,
      firestore_constants.timestamp:this.timestamp,
      firestore_constants.content:this.content,
      firestore_constants.type:this.type,
    };
  }

  factory MessageChat.fromDocument(DocumentSnapshot doc){
    String idFrom = doc.get(firestore_constants.idFrom);
    String idTo = doc.get(firestore_constants.idTo);
    String timestamp = doc.get(firestore_constants.timestamp);
    String content = doc.get(firestore_constants.content);
    int type = doc.get(firestore_constants.type);

    return MessageChat(idFrom: idFrom, idTo: idTo, timestamp: timestamp, content: content, type: type);
  }
}