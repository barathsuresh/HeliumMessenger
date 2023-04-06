import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helium_messenger/Constants/constants.dart';
import 'package:helium_messenger/Models/encrypt_decrypt.dart';
import 'package:helium_messenger/Models/message_chat.dart';
import 'package:helium_messenger/Screens/full_photo_page.dart';
import 'package:helium_messenger/Screens/login_screen.dart';
import 'package:helium_messenger/Service_Providers/auth_provider.dart';
import 'package:helium_messenger/Service_Providers/chat_provider.dart';
import 'package:helium_messenger/Service_Providers/settings_provider.dart';
import 'package:helium_messenger/Widgets/loading_circle_view.dart';
import 'package:helium_messenger/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as Urllauncher;

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;
  //todo make change
  final String peerPhoneNumber;
  ChatPage({required this.peerId,required this.peerAvatar,required this.peerNickname,required this.peerPhoneNumber});

  @override
  State createState() => ChatPageState(
    peerId: this.peerId,
    peerAvatar: this.peerAvatar,
    peerNickname: this.peerNickname,
    peerPhonenumber: this.peerPhoneNumber
  );
}

class ChatPageState extends State<ChatPage> {

  ChatPageState({Key? key,required this.peerId,required this.peerAvatar,required this.peerNickname,required this.peerPhonenumber});

  String peerId;
  String peerAvatar;
  String peerNickname;
  //todo make changes
  String peerPhonenumber;
  late String currentUserId;

  List<QueryDocumentSnapshot> listMessage = new List.from([]);

  int _limit = 20;
  int _limitIncrement = 20;
  String groupChatId = "";

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController =ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    chatProvider=context.read<ChatProvider>();
    authProvider=context.read<AuthProvider>();
    
    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);

    readLocal();
  }

  _scrollListener(){
    if(listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange){
      setState(() {
        _limit+=_limitIncrement;
      });
    }
  }

  void onFocusChange(){
    if(focusNode.hasFocus){
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void readLocal(){
    if(authProvider.getUserFirebaseId()?.isNotEmpty == true){
      currentUserId = authProvider.getUserFirebaseId()!;
    }else{
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false);
    }
    if(currentUserId.hashCode <= peerId.hashCode){
      groupChatId = '$currentUserId-$peerId';
    }else{
      groupChatId = "$peerId-$currentUserId";
    }
    
    chatProvider.updateDataFirestore(firestore_constants.pathUserCollection, currentUserId, {firestore_constants.chattingWith:peerId});
  }

  Future getImage() async{
    ImagePicker imagePicker = ImagePicker();
    PickedFile? pickedFile;
    pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    if(pickedFile!=null){
      imageFile = File(pickedFile.path);
      if(imageFile != null){
        setState(() {
          isLoading = true;
        });
        uploadFile();
      }
    }
  }

  Future uploadFile() async{
    String fileName = DateTime.now().microsecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!, fileName);
    try{
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl,TypeMessage.image);
      });
    } on FirebaseException catch (e){
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void onSendMessage(String content,int type){
    if(content.trim().isNotEmpty){
      textEditingController.clear();
      chatProvider.sendMessage(content, type, groupChatId, currentUserId, peerId);
      listScrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    }else{
      Fluttertoast.showToast(msg: "Nothing to Send", backgroundColor: color_constants.greyColor);
    }
  }

  bool isLastMessageLeft(int index){
    if((index > 0 && listMessage[index-1].get(firestore_constants.idFrom)==currentUserId) || index==0){
      return true;
    }else{
      return false;
    }
  }

  bool isLastMessageRight(int index){
    if((index > 0 && listMessage[index-1].get(firestore_constants.idFrom)!=currentUserId) || index==0){
      return true;
    }else{
      return false;
    }
  }

  void getSticker(){
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future<bool> onBackPress(){
    if(isShowSticker){
      setState(() {
        isShowSticker = false;
      });
    }else{
      chatProvider.updateDataFirestore(firestore_constants.pathUserCollection, currentUserId, {firestore_constants.chattingWith:null});
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  void _callPhoneNumber(String callPhoneNumber) async{
    if(callPhoneNumber.length<10){
      Fluttertoast.showToast(msg: "Number Not Valid");
      return;
    }
    Urllauncher.launch("tel://${callPhoneNumber}");
  }

  Widget buildInput(){
    return Container(
      child: Row(
        children: [
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: Icon(Icons.camera_enhance),
                onPressed: getImage,
                color: color_constants.primaryColor,
              ),
            ),
            color: Colors.white,
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: Icon(Icons.face_retouching_natural),
                onPressed: getSticker,
                color: color_constants.primaryColor,
              ),
            ),
            color: Colors.white,
          ),
          Flexible(
            child: Container(
              child: TextField(
                onSubmitted: (value){
                  onSendMessage(textEditingController.text,TypeMessage.text);
                },
                style: TextStyle(color: color_constants.primaryColor,fontSize: 15),
                controller: textEditingController,
                decoration: InputDecoration(
                  hintText: "Message",
                  hintStyle: TextStyle(color: color_constants.greyColor)
                ),
                focusNode: focusNode,
              ),
            ),
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: Icon(
                  Icons.send,
                ),
                onPressed: () => onSendMessage(textEditingController.text,TypeMessage.text),
                color: color_constants.primaryColor,
              ),
            ),
          )
        ],
      ),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: color_constants.greyColor2,width: 0.5)),
        color: Colors.white,
      ),
    );
  }

  Widget buildStickers(){
    return Expanded(
      child: Container(
        child: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => onSendMessage("mimi1",TypeMessage.sticker),
                  child: Image.asset(
                    "images/mimi1.gif",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage("mimi2",TypeMessage.sticker),
                  child: Image.asset(
                    "images/mimi2.gif",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage("mimi3",TypeMessage.sticker),
                  child: Image.asset(
                    "images/mimi3.gif",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => onSendMessage("mimi4",TypeMessage.sticker),
                  child: Image.asset(
                    "images/mimi4.gif",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage("mimi5",TypeMessage.sticker),
                  child: Image.asset(
                    "images/mimi5.gif",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage("mimi6",TypeMessage.sticker),
                  child: Image.asset(
                    "images/mimi6.gif",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => onSendMessage("mimi7",TypeMessage.sticker),
                  child: Image.asset(
                    "images/mimi7.gif",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage("mimi8",TypeMessage.sticker),
                  child: Image.asset(
                    "images/mimi8.gif",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage("mimi9",TypeMessage.sticker),
                  child: Image.asset(
                    "images/mimi9.gif",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            )
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color_constants.greyColor2,width: 0.5,),
          ),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(5),
        height: 180,
      ),
    );
  }

  Widget buildLoading(){
    return Positioned(
        child: isLoading ? LoaderCircle() : SizedBox.shrink()
    );
  }

  Widget buildItem(int index, DocumentSnapshot? document){
    if(document != null){
      MessageChat messageChat = MessageChat.fromDocument(document);
      if(messageChat.idFrom==currentUserId){
        return Row(
          children: [
            messageChat.type == TypeMessage.text
            ? Container(
              child: Text(
                EncryptionDecryption.decryptMessage(messageChat.content).toString(), //todo decrypt
                style: TextStyle(color: Colors.white),
              ),
              padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
              width: 200,
              decoration: BoxDecoration(color: color_constants.chatTheme,borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10,right: 10),
            ) : messageChat.type == TypeMessage.image
            ? Container(
              width: 200,
              height: 300,
              child: OutlinedButton(
                child: Material(
                  child: Hero(
                    tag: EncryptionDecryption.decryptMessage(messageChat.content).toString(),
                    child: Image.network(
                      EncryptionDecryption.decryptMessage(messageChat.content).toString(),
                      loadingBuilder: (BuildContext context,Widget child,ImageChunkEvent? loadingProgress){
                        if(loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            color: color_constants.chatTheme,
                            borderRadius: BorderRadius.all(Radius.circular(8))
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: color_constants.themeColor,
                              value: loadingProgress.expectedTotalBytes != null &&
                              loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context,object,stackTrace){
                        return Material(
                          child: Image.asset(
                              "images/img_not_available.jpeg",
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ),
                          clipBehavior: Clip.hardEdge,
                        );
                      },
                    ),
                  ),
                ),
                onPressed: (){
                  Navigator.push(context,MaterialPageRoute(builder: (context) => FullPhotoPage(url: messageChat.content)));
                },
                style: ButtonStyle(padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(0))),
              ),
              margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10,right: 10 ),
            ) : Container( // sender send sticker
              child: Image.asset(
                "images/${EncryptionDecryption.decryptMessage(messageChat.content).toString()}.gif",
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
            )
          ],
          mainAxisAlignment: MainAxisAlignment.end,
        );
      }else{
        return Container(
          child: Column(
            children: [
              Row(
                children: [
                  isLastMessageLeft(index)
                  ? Material(
                    child: Image.network(
                      peerAvatar,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                        if(loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: color_constants.themeColor,
                            value: loadingProgress.expectedTotalBytes != null &&
                                loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                          ),
                        );
                      },
                      errorBuilder: (context, object, stackTrace){
                        return Icon(
                          Icons.account_circle,
                          size: 35,
                          color: color_constants.greyColor,
                        );
                      },
                      width: 35,
                      height: 35,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    clipBehavior: Clip.hardEdge,
                  ) : Container(
                    width: 35,
                  ),
                  messageChat.type == TypeMessage.text
                  ? Container(
                    child: Text(
                      EncryptionDecryption.decryptMessage(messageChat.content).toString(),
                      style: TextStyle(color: Colors.black),
                    ),
                    padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                    width: 200,
                    decoration: BoxDecoration(color: color_constants.greyColor2,borderRadius: BorderRadius.circular(8)),
                    margin: EdgeInsets.only(left: 10,bottom: isLastMessageLeft(index) ? 20 : 10),
                  ) : messageChat.type == TypeMessage.image
                  ? Container(
                    width: 200,
                    height: 300,
                    child: OutlinedButton(
                      child: Material(
                        child: Hero(
                          tag: EncryptionDecryption.decryptMessage(messageChat.content).toString(),
                          child: Image.network(
                            EncryptionDecryption.decryptMessage(messageChat.content).toString(),
                            loadingBuilder: (BuildContext context,Widget child,ImageChunkEvent? loadingProgress){
                              if(loadingProgress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                    color: color_constants.greyColor2,
                                    borderRadius: BorderRadius.all(Radius.circular(8))
                                ),
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: color_constants.themeColor,
                                    value: loadingProgress.expectedTotalBytes != null &&
                                        loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context,object,stackTrace){
                              return Material(
                                child: Image.asset(
                                  "images/img_not_available.jpeg",
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                clipBehavior: Clip.hardEdge,
                              );
                            },
                          ),
                        ),
                      ),
                      onPressed: (){
                        Navigator.push(context,MaterialPageRoute(builder: (context) => FullPhotoPage(url: messageChat.content)));
                      },
                      style: ButtonStyle(padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(0))),
                    ),
                    margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10,right: 10 ),
                  ) : Container(
                    child: Image.asset(
                        "images/${EncryptionDecryption.decryptMessage(messageChat.content).toString()}.gif",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
                  )
                ],
              ),

              isLastMessageLeft(index)
              ? Container(
                child: Text(
                  DateFormat("dd/MM/yyyy hh:mm a").format(DateTime.fromMicrosecondsSinceEpoch(int.parse(messageChat.timestamp))),
                  style: TextStyle(color: color_constants.greyColor,fontSize: 12, fontStyle: FontStyle.italic),
                ),
                margin: EdgeInsets.only(left: 50,bottom: 5),
              ) : SizedBox.shrink()
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        );
      }
    }else{
      return SizedBox.shrink();
    }
  }

  Widget buildListMessage(){
    return Flexible(
      child: groupChatId.isNotEmpty
      ? StreamBuilder<QuerySnapshot>(
        stream: chatProvider.getChatStream(groupChatId,_limit),
        builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot){
          if(snapshot.hasData){
            listMessage.addAll(snapshot.data!.docs);
            print(listMessage.length);
            return ListView.builder(
              itemBuilder: (context,index) => buildItem(index,snapshot.data?.docs[index]),
              itemCount: snapshot.data?.docs.length,
              reverse: true,
              controller: listScrollController,
            );
          }else{
            return Center(
              child: CircularProgressIndicator(
                color: color_constants.themeColor,
              ),
            );
          }
        },
      ) :Center(
        child: CircularProgressIndicator(
          color: color_constants.themeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: islightMode ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: islightMode ? Colors.white: Colors.grey[900],
        iconTheme: IconThemeData(
          color: islightMode ? Colors.black :Colors.white,
        ),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Hero(
                tag: peerAvatar,
                child: Material(
                  child: peerAvatar.isNotEmpty
                      ? Image.network(
                    peerAvatar,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                    loadingBuilder: (BuildContext context,Widget child,ImageChunkEvent? loadingProgress){
                      if(loadingProgress == null) return child;
                      return Container(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: color_constants.greyColor,
                          value: loadingProgress.expectedTotalBytes != null &&
                              loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                        ),
                      );
                    },
                    errorBuilder: (context,object,stackTrace){
                      return Icon(
                        Icons.account_circle_rounded,
                        size: 50,
                        color: color_constants.greyColor,
                      );
                    },
                  )
                      : Icon(
                    Icons.account_circle_rounded,
                    size: 50,
                    color: color_constants.greyColor,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  clipBehavior: Clip.hardEdge,
                ),
              ),
              SizedBox(width: 10,),
              Text(
                this.peerNickname,
                style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold,color: islightMode ? Colors.black :Colors.white,fontSize: 20),
              ),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.phone,
              size: 30,
              color: islightMode ? Colors.black :Colors.white,
            ),
            onPressed: (){
              SettingsProvider settingProvider;
              settingProvider = context.read<SettingsProvider>();
              _callPhoneNumber(peerPhonenumber);
            },
          )
        ],
      ),
      body: WillPopScope(
        child: Stack(
          children: [
            Column(
              children: [
                buildListMessage(),

                isShowSticker ? buildStickers() : SizedBox.shrink(),

                buildInput(),

              ],
            ),
            buildLoading()
          ],
        ),
        onWillPop: onBackPress ,
      ),
    );
  }
}
