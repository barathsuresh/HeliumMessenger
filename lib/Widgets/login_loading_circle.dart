import 'package:helium_messenger/main.dart';
import 'package:flutter/material.dart';
import 'package:helium_messenger/Constants/color_constants.dart';

class LoaderLoginCircle extends StatelessWidget {
  const LoaderLoginCircle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: CircularProgressIndicator(
          color: color_constants.primaryColor,
        ),
      ),
    );
  }
}