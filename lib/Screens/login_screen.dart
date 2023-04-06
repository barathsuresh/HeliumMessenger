import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:helium_messenger/Screens/home_screen.dart';
import 'package:helium_messenger/Service_Providers/auth_provider.dart';
import 'package:helium_messenger/Widgets/login_loading_circle.dart';
import 'package:provider/provider.dart';

import '../Widgets/loading_circle_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch(authProvider.status){
      case Status.authenticateError: Fluttertoast.showToast(msg: "Sign in failed");
      break;
      case Status.authenticateCancelled: Fluttertoast.showToast(msg: "Sign in cancelled");
      break;
      case Status.authenticated: Fluttertoast.showToast(msg: "Signed in ");
      break;
      default:
        break;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Hero(
                tag: "logo",
                child: ImageIcon(AssetImage("icons/heliumicon.png"),size: 100,color: Colors.black),
              ),
            ),
            SizedBox(height: 20,),
            SizedBox(
              width: double.infinity,
              child: TextLiquidFill(
                text: "Helium Messenger",
                waveColor: Colors.black,
                boxBackgroundColor: Colors.white,
                textStyle: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                ),
                boxHeight: 100,
              ),
            ),
            Padding(
                padding: EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () async{
                  bool isSuccess = await authProvider.handleSignIn();
                  if(isSuccess){
                    Navigator.push(context,MaterialPageRoute(builder: (context) => HomeScreen()));
                  }
                },
                child: Image.asset(
                    "images/gsignin.png",
                  height: 100,
                  width: 200,
                ),
              ),
            ),
            // Positioned(
            //       child: authProvider.status == Status.authenticating ? LoaderLoginCircle() : SizedBox.shrink(),
            // )
          ],
        ),
      ),
    );
  }
}
