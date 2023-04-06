import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:helium_messenger/Constants/constants.dart';
import 'package:helium_messenger/Constants/in_app_constants.dart';
import 'package:helium_messenger/Models/UserChat.dart';
import 'package:helium_messenger/Screens/home_screen.dart';
import 'package:helium_messenger/Service_Providers/settings_provider.dart';
import 'package:helium_messenger/Widgets/loading_circle_view.dart';
import 'package:helium_messenger/main.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: islightMode ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: islightMode ? Colors.white : Colors.black,
        iconTheme: IconThemeData(
            color: islightMode ? Colors.black :Colors.white
        ),
        title: Text(
          in_app_constants.settingTitle,
          style: TextStyle(
            color: islightMode ? Colors.black :Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SettingsPageState(),
    );
  }
}

class SettingsPageState extends StatefulWidget {
  const SettingsPageState({Key? key}) : super(key: key);

  @override
  State<SettingsPageState> createState() => _SettingsPageStateState();
}

class _SettingsPageStateState extends State<SettingsPageState> {
  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;
  TextEditingController? controllerPhoneNum;

  String dialCodeDigits="00";
  final TextEditingController _controller = TextEditingController();

  String id="";
  String nickname="";
  String aboutMe="";
  String photoUrl="";
  String phoneNumber="";

  bool isLoading = false;
  File? avatarImageFile;
  late SettingsProvider settingsProvider;

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    settingsProvider =  context.read<SettingsProvider>();
    readLocal();
  }

  void readLocal(){
    setState(() {
      id = settingsProvider.getPrefs(firestore_constants.id) ?? "";
      nickname = settingsProvider.getPrefs(firestore_constants.nickname) ?? "";
      aboutMe = settingsProvider.getPrefs(firestore_constants.aboutMe) ?? "";
      photoUrl = settingsProvider.getPrefs(firestore_constants.photoUrl) ?? "";
      phoneNumber = settingsProvider.getPrefs(firestore_constants.phoneNumber) ?? "";
    });

    controllerNickname = TextEditingController(text: nickname);
    controllerAboutMe = TextEditingController(text: aboutMe);
  }

  Future getImage() async{
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = (await imagePicker.pickImage(source: ImageSource.gallery).catchError((err){
      Fluttertoast.showToast(msg: err.toString());
    }));
    File? image;
    if(pickedFile != null){
      print("file picked");
      image = File(pickedFile.path);
    }
    if(image != null){
      print("Image not null");
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async{
    String fileName = id;
    UploadTask uploadTask = settingsProvider.uploadFile(avatarImageFile!,fileName);
    try{
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();

      UserChat updateInfo = UserChat(id: id, nickname: nickname, photoUrl: photoUrl, phoneNumber: phoneNumber, aboutMe: aboutMe);
      settingsProvider.updateDataFireStore(firestore_constants.pathUserCollection,id,updateInfo.toJSON())
      .then((data) async{
        await settingsProvider.setPref(firestore_constants.photoUrl,photoUrl);
        setState(() {
          isLoading = false;
        });
      }).catchError((err){
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (err){
      setState(() {
        isLoading=false;
      });
      Fluttertoast.showToast(msg: err.message ?? err.toString());
    }
  }

  void handleUpdateData(){
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
      if(dialCodeDigits != "+00" && _controller.text != null){
        phoneNumber = dialCodeDigits + _controller.text.toString();
      }
    });
    UserChat updateInfo = UserChat(id: id, nickname: nickname, photoUrl: photoUrl, phoneNumber: phoneNumber, aboutMe: aboutMe);
    settingsProvider.updateDataFireStore(firestore_constants.pathUserCollection,id,updateInfo.toJSON())
    .then((data) async{
      await settingsProvider.setPref(firestore_constants.nickname,nickname);
      await settingsProvider.setPref(firestore_constants.aboutMe,aboutMe);
      await settingsProvider.setPref(firestore_constants.photoUrl,photoUrl);
      await settingsProvider.setPref(firestore_constants.phoneNumber,phoneNumber);

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: "Updated Successfully");
    }).catchError((err){
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
    setState(() {});
    Navigator.push(context,MaterialPageRoute(builder: (context)=>HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(left: 15,right: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                  onPressed: getImage,
                child: Container(
                  margin: EdgeInsets.all(20),
                  child: avatarImageFile == null
                      ? photoUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                            errorBuilder: (context,object,stackTrace){
                              return Icon(
                                Icons.account_circle_rounded,
                                size: 90,
                                color: Colors.grey,
                              );
                            },
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress){
                              if(loadingProgress == null) return child;
                              else return Container(
                                width: 90,
                                height: 90,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.grey,
                                    value: loadingProgress.expectedTotalBytes != null &&
                                            loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                  ),
                                ),
                              );
                            },
                    ),
                  ): Icon(
                    Icons.account_circle_rounded,
                    size: 90,
                    color: Colors.grey,
                  )
                  :ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Image.file(
                      avatarImageFile!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: islightMode ? Colors.black :Colors.white,
                      ),
                    ),
                    margin: EdgeInsets.only(bottom: 5,top: 10),
                  ),
                  SizedBox(height: 8,),
                  Container(
                    margin: EdgeInsets.only(left: 30,right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: color_constants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color_constants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color_constants.primaryColor),
                          ),
                          hintText: "Write Your Name...",
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: color_constants.greyColor),
                        ),
                        controller: controllerNickname,
                        onChanged: (value){
                          nickname = value;
                        },
                        focusNode: focusNodeNickname,
                      ),
                    ),
                  ),
                  SizedBox(height: 8,),
                  Container(
                    child: Text(
                      "About Me",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: islightMode ? Colors.black :Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 8,),
                  Container(
                    margin: EdgeInsets.only(left: 30,right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: color_constants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color_constants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color_constants.primaryColor),
                          ),
                          hintText: "About You",
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: color_constants.greyColor),
                        ),
                        controller: controllerAboutMe,
                        onChanged: (value){
                          aboutMe = value;
                        },
                        focusNode: focusNodeAboutMe,
                      ),
                    ),
                  ),
                  SizedBox(height: 8,),
                  Container(
                    child: Text(
                      "Phone Number",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: islightMode ? Colors.black :Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 8,),
                  Container(
                    margin: EdgeInsets.only(left: 30,right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: color_constants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color_constants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color_constants.primaryColor),
                          ),
                          hintText: phoneNumber,
                          enabled: false,
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: color_constants.greyColor),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8,),
                  Container(
                    margin: EdgeInsets.only(left: 10,top: 30,bottom: 5),
                    child: SizedBox(
                      width: 400,
                      height: 60,
                      child: CountryCodePicker(
                        onChanged: (country){
                          setState(() {
                            dialCodeDigits = country.dialCode!;
                          });
                          },
                        textStyle: TextStyle(color: islightMode ? Colors.black :Colors.white),
                        initialSelection: "IT",
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        favorite: ["+1","US","IND","+91"],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30,right: 30),
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: color_constants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color_constants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color_constants.primaryColor),
                          ),
                          hintText: "Phone Number",
                          hintStyle: TextStyle(color: color_constants.greyColor),
                          prefix: Padding(
                            padding: EdgeInsets.all(4),
                            child: Text(dialCodeDigits, style: TextStyle(color: Colors.grey),),
                          )
                        ),
                        controller: _controller,
                        //TODO-change
                        onChanged: (value){
                          phoneNumber = value;
                        },
                        maxLength: 10,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ),

                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 50,bottom: 50),
                child: TextButton(
                  onPressed: handleUpdateData,
                  child: Text(
                    "Update Now",
                    style: TextStyle(
                        fontSize: 16,
                        color: islightMode ? Colors.white :Colors.black
                    ),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(islightMode ? Colors.black :Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.fromLTRB(30, 10, 30, 10)
                    ),

                  ),
                ),
              )
            ],
          ),
        ),
        
        Positioned(child: isLoading ? LoaderCircle() : SizedBox.shrink()),
      ],
    );
  }
}

