import 'package:flutter/material.dart';
import 'package:helium_messenger/Constants/constants.dart';
import 'package:helium_messenger/main.dart';

class LoaderCircle extends StatelessWidget {
  const LoaderCircle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: islightMode ? Colors.white : Colors.black,
      child: Center(
        child: CircularProgressIndicator(
          color: color_constants.primaryColor,
        ),
      ),
    );
  }
}
