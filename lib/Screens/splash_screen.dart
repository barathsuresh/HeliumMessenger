import 'package:flutter/material.dart';
import 'package:helium_messenger/Constants/constants.dart';
import 'package:helium_messenger/Screens/home_screen.dart';
import 'package:helium_messenger/Screens/login_screen.dart';
import 'package:helium_messenger/Service_Providers/auth_provider.dart';
import 'package:provider/provider.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Shows the splash screen for 4 seconds and call the function checkSignedIn()
    Future.delayed(Duration(seconds: 2),(){
      checkSignedIn();
    });
  }

  void checkSignedIn() async{
    AuthProvider authProvider = context.read<AuthProvider>();
    bool isLoggedIn = await authProvider.isLoggedIn();
    if(isLoggedIn){
      Navigator.push(context,MaterialPageRoute(builder: (context) => HomeScreen()));
      return;
    }
    Navigator.push(context,MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: "logo",
              child: ImageIcon(AssetImage("icons/heliumicon.png"),size: 300,color: Colors.black),
            ),
            SizedBox(height: 20,),
            SizedBox(height: 20,),
            Container(
              width: 20,
              height: 20,
              color: Colors.white,
              child: CircularProgressIndicator(color: Colors.black,),
            )
          ],
        ),
      ),
    );
  }
}
