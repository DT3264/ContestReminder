import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ScaledText extends StatelessWidget{
  final String text;
  final double fontSize;
  ScaledText({this.text, this.fontSize});
  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: AutoSizeText(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
        )
      )
    );
  } 
}

class ScaledTextDate extends StatelessWidget{
  final String text;
  ScaledTextDate({this.text});
  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      softWrap: true,
      style: TextStyle(
        fontSize: 18,
        height: 0.8
      )
    );
  }
}