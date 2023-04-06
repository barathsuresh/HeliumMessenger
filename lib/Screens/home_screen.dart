import 'dart:async';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helium_messenger/Constants/constants.dart';
import 'package:helium_messenger/Models/UserChat.dart';
import 'package:helium_messenger/Screens/login_screen.dart';
import 'package:helium_messenger/Screens/setting_page.dart';
import 'package:helium_messenger/Service_Providers/auth_provider.dart';
import 'package:helium_messenger/Service_Providers/settings_provider.dart';
import 'package:helium_messenger/Widgets/NavigationDrawer.dart';
import 'package:helium_messenger/Widgets/loading_circle_view.dart';
import 'package:helium_messenger/main.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:scroll_loop_auto_scroll/scroll_loop_auto_scroll.dart';

import '../Models/popup_choices.dart';
import '../Service_Providers/home_provider.dart';
import '../Utilities/Debouncer.dart';
import '../Utilities/Utilites.dart';
import 'chat_page.dart';
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();
  Debouncer serachDebouncer = Debouncer(milliseconds: 300);
  StreamController<bool> btnClearController = StreamController<bool>();
  TextEditingController searchBarTech = TextEditingController();
  FocusNode searchFocus = FocusNode();

  int _limit=20;
  int _limitIncrement=20;
  String _textSearch = "";
  bool isLoading = false;

  late String currentUserId;
  late AuthProvider authProvider;
  late HomeProvider homeProvider;
  late SettingsProvider settingsProvider; //todo maybe delete

  String? id; //todo maybe delete
  String? nickname; //todo maybe delete
  String? aboutMe; //todo maybe delete
  String? photoUrl; //todo maybe delete
  String? phoneNumber; //todo maybe delete

  List<PopupChoices> choices= <PopupChoices>[
    PopupChoices(title: "Settings", icon: Icons.settings),
    PopupChoices(title: "Sign Out", icon: Icons.exit_to_app)
  ];

  void scrollListener(){
    if(listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange){
      setState(() {
        _limit+=_limitIncrement;
      });
    }
  }

  void readLocal(){ //todo changes readLocal for getting prefs
    setState(() {
      id = settingsProvider.getPrefs(firestore_constants.id) ?? "";
      nickname = settingsProvider.getPrefs(firestore_constants.nickname) ?? "";
      aboutMe = settingsProvider.getPrefs(firestore_constants.aboutMe) ?? "";
      photoUrl = settingsProvider.getPrefs(firestore_constants.photoUrl) ?? "";
      phoneNumber = settingsProvider.getPrefs(firestore_constants.phoneNumber) ?? "";
    });
  }

  Future<void> handleSignOut() async{
    authProvider.handleSignOut();
    Navigator.push(context,MaterialPageRoute(builder: (context)=>LoginScreen()));
  }

  void onItemMenuPress(PopupChoices choice){
    if(choice.title == "Sign Out"){
      handleSignOut();
    }else{
      Navigator.push(context, MaterialPageRoute(builder: (context)=>SettingsPage()));
    }
  }

  Widget buildPopUpMenu(){
    return PopupMenuButton<PopupChoices>(
      icon: Icon(Icons.more_vert,color: islightMode ? Colors.black :Colors.white,),
        onSelected: onItemMenuPress,
        itemBuilder: (BuildContext context){
          return choices.map((PopupChoices choice){
            return PopupMenuItem(
                value: choice,
                child: Row(
                  children: [
                    Icon(
                      choice.icon,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 10,),
                    Container(
                      width: 100,
                      child: Text(
                        choice.title,
                        style: TextStyle(
                          color: Colors.grey
                        ),
                      ),
                    )
                  ],
                )
            );
          }).toList();
        }
    );
  }

  Widget buildSearchBar(){
    return Container(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search,color: color_constants.greyColor,size: 30,),
          SizedBox(width: 5,),
          Expanded(
              child: TextFormField(
                textInputAction: TextInputAction.search,
                controller: searchBarTech,
                onChanged: (value){
                  if(value.isNotEmpty){
                    btnClearController.add(true);
                    setState(() {
                      _textSearch = value;
                    });
                  }else{
                    btnClearController.add(false);
                    setState(() {
                      _textSearch = "";
                    });
                  }
                },
                decoration: InputDecoration.collapsed(
                  hintText: "Search...",
                  hintStyle: TextStyle(fontSize: 13,color: color_constants.greyColor),
                ),
                focusNode: searchFocus,
              )
          ),
          StreamBuilder(
            stream: btnClearController.stream,
              builder: (context,snapshot){
                return snapshot.data == true
                    ? GestureDetector(
                        onTap: (){
                          searchBarTech.clear();
                          btnClearController.add(false);
                          setState(() {
                            _textSearch="";
                          });
                        },
                      child: Icon(Icons.search,color: color_constants.greyColor,size: 20,),
                ): SizedBox.shrink();
              }
          )
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color_constants.greyColor2,
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
    );
  }

  Future<bool> onBackPress(){
    openDialog();
    return Future.value(false);
  }

  Future<void> openDialog() async{
    switch(await showDialog(
        context: context,
        builder: (BuildContext context){
          return SimpleDialog(
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            children: <Widget>[
              Container(
                color: color_constants.themeColor,
                padding: EdgeInsets.only(top: 10,bottom: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      child: Icon(Icons.exit_to_app,size: 30,color: Colors.white,),
                      margin: EdgeInsets.only(bottom: 10),
                    ),
                    Text(
                      "Exit app",
                      style: TextStyle(color: Colors.white,fontSize: 18,fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Are You sure to exit app?",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: (){
                  Navigator.pop(context,0);
                },
                child: Row(
                  children: [
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: color_constants.primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10),
                    ),
                    Text(
                      "Cancel",
                      style: TextStyle(
                        color: color_constants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: (){
                  Navigator.pop(context,1);
                },
                child: Row(
                  children: [
                    Container(
                      child: Icon(
                        Icons.check_circle ,
                        color: color_constants.primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10),
                    ),
                    Text(
                      "Yes",
                      style: TextStyle(
                        color: color_constants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              )
            ],
          );
        }
        )){
      case 0 :
        break;
      case 1:
        exit(0);
    }
  }

  Widget BuildItem(BuildContext context,DocumentSnapshot? document){
    if(document != null){
      UserChat userChat = UserChat.fromDocument(document);
      if(userChat.id == currentUserId){
        return SizedBox.shrink();
      }else{
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            color: islightMode ? color_constants.chatListLightMode : color_constants.chatListDarkMode,
          ),
          child: TextButton(
            child: Row(
              children: [
                Hero(
                  tag: userChat.photoUrl,
                  child: Material(
                    child: userChat.photoUrl.isNotEmpty
                    ? Image.network(
                      userChat.photoUrl,
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
                Flexible(
                    child:Container(
                      child: Column(
                        children: [
                          Container(
                            child: Text(
                              userChat.nickname,
                              maxLines: 1,
                              style: TextStyle(color: islightMode ? color_constants.chatListTextLightMode:color_constants.chatListTextDarkMode, fontSize: 18,fontWeight: FontWeight.bold),
                            ),
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 5),
                          ),
                          Container(
                            child: Text(
                              userChat.aboutMe,
                              maxLines: 1,
                              style: TextStyle(color: islightMode ? color_constants.chatListTextLightMode:Colors.grey[400],),
                            ),
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(left: 20),
                    )
                )
              ],
            ),
            onPressed: (){
              if(Utilities.isKeyboardShowing()){
                Utilities.closeKeyboard(context);
                searchFocus.unfocus();
                setState(() {

                });
              }
              Navigator.push(context,MaterialPageRoute(builder: (context) => ChatPage(
                peerId: userChat.id,
                peerAvatar: userChat.photoUrl,
                peerNickname: userChat.nickname,
                peerPhoneNumber: userChat.phoneNumber,
              )
              )
              );
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.grey.withOpacity(.2)),
              shape: MaterialStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20),),
                )
              )
            ),
          ),
          margin: EdgeInsets.only(bottom: 10,left: 5,right: 5),
        );
      }
    }
    return SizedBox.shrink();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    btnClearController.close();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();
    settingsProvider = context.read<SettingsProvider>();
    if(authProvider.getUserFirebaseId()?.isNotEmpty == true){
      currentUserId = authProvider.getUserFirebaseId()!;
    }else{
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
      );
    }
    readLocal();
    registerNotification();
    configureLocalNotification();
    listScrollController.addListener(scrollListener);
  }

  void registerNotification(){
    firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if(message.notification != null){
        // TODO show notification (requires billing in firebase)
        showNotification(message.notification!);
      }
      return;
    });

    firebaseMessaging.getToken().then((token){
      if (token != null){
        homeProvider.updateDataFirestore(firestore_constants.pathUserCollection,currentUserId,{'pushToken':token});
      }
    }).catchError((err){
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  void configureLocalNotification(){
    AndroidInitializationSettings initializationAndroidSettings = AndroidInitializationSettings("helium");
    InitializationSettings initializationSettings = InitializationSettings(android: initializationAndroidSettings);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(RemoteNotification notification) async{
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails("com.helium.helium_messenger","Helium Messenger",
    playSound: true,
    enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(0,notification.title,notification.body,notificationDetails,payload: null);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SafeArea( //todo copy to NavigationDrawer Widget
        child: Drawer(
          backgroundColor: islightMode ? Colors.white : Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20,),
              Row(
                children: [
                  SizedBox(width: 10,),
                  ImageIcon(AssetImage("icons/heliumicon.png"),size: 50,color: islightMode ? Colors.black : Colors.white,),
                  Text(
                    " Messenger ",
                    style: GoogleFonts.sourceCodePro(
                      color: islightMode ? Colors.black :Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold
                    )
                  ),
                  Icon(
                    Icons.send,
                    color:islightMode ? Colors.black : Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 20,),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  width: 125,
                  height: 125,
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
                ),
              ),
              SizedBox(height: 30,),
              ListTile(
                title: Text("Username"),
                tileColor: color_constants.greyColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                subtitle: Text(
                  textAlign: TextAlign.left,
                  "@"+nickname!,
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                onLongPress: (){
                  Navigator.push(context,MaterialPageRoute(builder: (_)=>SettingsPage()));
                },
              ),
              SizedBox(height: 8,),
              ListTile(
                title: Text("Bio"),
                tileColor: color_constants.greyColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                subtitle: Text(
                  textAlign: TextAlign.left,
                  aboutMe!,
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                onLongPress: (){
                  Navigator.push(context,MaterialPageRoute(builder: (_)=>SettingsPage()));
                },
              ),
              SizedBox(height: 8,),
              ListTile(
                title: Text("Phone"),
                tileColor: color_constants.greyColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                subtitle: Text(
                  textAlign: TextAlign.left,
                  phoneNumber!,
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                onLongPress: (){
                  Navigator.push(context,MaterialPageRoute(builder: (_)=>SettingsPage()));
                },
              ),
              SizedBox(height: 8,),
              ListTile(
                title: Text("Sync"),
                tileColor: color_constants.greyColor,
                trailing: Icon(
                  Icons.sync
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                subtitle: Text(
                  textAlign: TextAlign.left,
                  "To apply changes",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                onTap: (){
                  readLocal();
                },
              ),
              SizedBox(height: 8,),
              ListTile(
                title: Text("Theme"),
                tileColor: color_constants.greyColor,
                trailing: IconButton(
                  icon: CupertinoSwitch(
                    value: islightMode,
                    onChanged: (value){
                      setState(() {
                        islightMode=value;
                        print(islightMode);
                      });
                    },
                    thumbColor: islightMode ? Colors.black : Colors.white,
                    // activeTrackColor: Colors.grey,
                    activeColor: islightMode ? Colors.white : Colors.black,
                    trackColor: Colors.grey[900],
                    // inactiveTrackColor: Colors.grey,
                    // inactiveThumbColor: Colors.grey,
                  ),
                  onPressed: ()=>"",
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                subtitle: Text(
                  textAlign: TextAlign.left,
                  "Dark/Light",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                onTap: (){
                  islightMode = !islightMode;
                  setState(() {

                  });
                },
              ),
              SizedBox(height: 30,),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Developed with",style: GoogleFonts.oswald(fontSize: 20,color: islightMode ? Colors.black :Colors.white),),
                      SizedBox(width: 1,),
                      Row(
                        children: [
                          AnimatedTextKit(
                            repeatForever: true,
                            isRepeatingAnimation: true,
                            animatedTexts: [
                              FlickerAnimatedText("❤",textStyle: GoogleFonts.oswald(fontSize: 20,color: islightMode ? Colors.black :Colors.white),),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 80,),
                      Text("~Barath Suresh",style: GoogleFonts.poppins(fontSize: 13,color: islightMode ? Colors.black :Colors.white)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      backgroundColor: islightMode ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: islightMode ? Colors.white : Colors.black,
        title: SingleChildScrollView(
          child: Row(
            children: [
              Hero(
                  child: ImageIcon(AssetImage("icons/heliumicon.png"),size: 35,color: islightMode ? Colors.black : Colors.white,),
                tag: "logo",
              ),
              Expanded(
                child: Container(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AnimatedTextKit(
                          pause: Duration(seconds: 2),
                          repeatForever: true,
                            animatedTexts:[
                              ColorizeAnimatedText(
                                " Welcome, ${nickname} ",
                                textStyle: GoogleFonts.sourceCodePro(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.1,
                                    color: islightMode ? Colors.black :Colors.white
                                ),
                                colors: [
                                  islightMode ? Colors.black :Colors.white,
                                  Colors.red,
                                  Colors.green,
                                  Colors.blue,
                                  Colors.yellow,
                                  Colors.purple,
                                ]
                              ),
                            ]
                        ),
                        Icon(
                          Icons.send,
                          color:islightMode ? Colors.black : Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        leading: IconMenuWidget(searchFocus: searchFocus,),
        actions: [
          buildPopUpMenu()
        ],
      ),
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10,),
                Row(
                  children: [
                    SizedBox(width: 11,),
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          "Chats",
                          cursor: '_',
                          textStyle: GoogleFonts.sourceCodePro(
                            fontSize: 45,
                            color: islightMode ? Colors.black :Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          speed: Duration(milliseconds: 400),
                        ),
                      ],
                      repeatForever: true,
                    ),
                  ],
                ),
                buildSearchBar(),
                SizedBox(height: 10,),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: homeProvider.getStreamFireStore(firestore_constants.pathUserCollection, _limit, _textSearch),
                    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                      if(snapshot.hasData){
                        if((snapshot.data?.docs.length ?? 0)>0){
                          return ListView.builder(
                            itemBuilder: (context,index) => BuildItem(context, snapshot.data?.docs[index]),
                            itemCount: snapshot.data?.docs.length,
                            controller: listScrollController,
                          );
                        }else{
                          return Center(
                            child: Text("No User Found...",style: TextStyle(color: Colors.grey),),
                          );
                        }
                      }else{
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.grey,
                          ),
                        );
                      }
                    },
                  ),
                )
              ],
            ),
            Positioned(
                child: isLoading ? LoaderCircle() : SizedBox.shrink(),
            )
          ],
        ),
      ),
    );
  }
}

class IconMenuWidget extends StatefulWidget {
  FocusNode? searchFocus;
  IconMenuWidget({this.searchFocus});

  @override
  State<IconMenuWidget> createState() => _IconMenuWidgetState();
}

class _IconMenuWidgetState extends State<IconMenuWidget> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Iconsax.menu_1,
        color: islightMode ? Colors.black : Colors.white,
      ),
      onPressed: (){
        widget.searchFocus?.unfocus();
        setState(() {});
        Scaffold.of(context).openDrawer();
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }
}
