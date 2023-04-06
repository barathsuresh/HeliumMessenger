import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt; //todo remove
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helium_messenger/Models/encrypt_decrypt.dart'; // todo remove
import 'package:helium_messenger/Screens/splash_screen.dart';
import 'package:helium_messenger/Service_Providers/auth_provider.dart';
import 'package:helium_messenger/Service_Providers/chat_provider.dart';
import 'package:helium_messenger/Service_Providers/home_provider.dart';
import 'package:helium_messenger/Service_Providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

bool islightMode = false;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences pref = await SharedPreferences.getInstance();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) => runApp(MyApp(prefs: pref)));

  // runApp(MyApp(prefs: pref));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseStore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  
  MyApp({required this.prefs});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider(firebaseAuth: FirebaseAuth.instance, googleSignIn: GoogleSignIn(), prefs: this.prefs, firebaseFirestore: this.firebaseStore)
        ),
        Provider<SettingsProvider>(
            create: (_) => SettingsProvider(prefs: this.prefs, firebaseFirestore: this.firebaseStore, firebaseStorage: this.firebaseStorage)
        ),
        Provider<HomeProvider>(
            create: (_) => HomeProvider(firebaseFirestore: firebaseStore)
        ),
        Provider<ChatProvider>(
          create: (_) => ChatProvider(prefs: this.prefs, firebaseStorage: this.firebaseStorage, firebaseFirestore: this.firebaseStore),
        )
      ],
      child: MaterialApp(
        title: "Helium Messenger",
        theme: ThemeData(
          primaryColor: Colors.black,
        ),
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

