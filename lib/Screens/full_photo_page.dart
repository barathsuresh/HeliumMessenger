import 'package:flutter/material.dart';
import 'package:helium_messenger/Constants/constants.dart';
import 'package:helium_messenger/Constants/in_app_constants.dart';
import 'package:helium_messenger/Models/encrypt_decrypt.dart';
import 'package:photo_view/photo_view.dart';

import '../main.dart';

class FullPhotoPage extends StatelessWidget {
  String url;
  FullPhotoPage({required this.url});
  @override
  Widget build(BuildContext context) {
    url = EncryptionDecryption.decryptMessage(url);
    return Scaffold(
      backgroundColor: islightMode ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: islightMode ? Colors.white : Colors.black,
        iconTheme: IconThemeData(
          color: color_constants.primaryColor,
        ),
        title: Text(
          in_app_constants.fullImgTitle,
          style: TextStyle(
            color: color_constants.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        child: Hero(
          tag: url,
          child: PhotoView(
            imageProvider: NetworkImage(url),
          ),
        ),
      ),
    );
  }
}
