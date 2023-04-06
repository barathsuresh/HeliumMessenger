import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../main.dart';

class NavigationDrawer extends StatefulWidget {
  const NavigationDrawer({Key? key}) : super(key: key);

  @override
  State<NavigationDrawer> createState() => _NavigationDrawerState();
}

class _NavigationDrawerState extends State<NavigationDrawer> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20,),
            Center(
              child: Text(
                "HELIUM MESSENGER",
                style: TextStyle(
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "Dark/Light Theme",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                SizedBox(width: 50,),
                IconButton(
                  icon: Switch(
                    value: islightMode,
                    onChanged: (value){
                      setState(() {
                        islightMode=value;
                        print(islightMode);
                      });
                    },
                    activeTrackColor: Colors.grey,
                    activeColor: Colors.white,
                    inactiveTrackColor: Colors.grey,
                    inactiveThumbColor: Colors.grey,
                  ),
                  onPressed: ()=>"",
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
