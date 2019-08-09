import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

Widget scaledText(String text, double fontSize){
  return Padding(
    padding: EdgeInsets.only(bottom: 5),
    child: AutoSizeText(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
      fontSize: fontSize
      )
    )
  );
}
Widget scaledTextDate(String text){
  return AutoSizeText(
    text,
    softWrap: true,
    style: TextStyle(
      fontSize: 18,
      height: 0.8
    )
  );
}