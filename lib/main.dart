import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';


import 'package:flutter_maps2/firstPage.dart';
import 'package:flutter_maps2/map&nav.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Google Maps Demo',
      initialRoute: '1stPage',
      routes: {
        //'start': (context)=>,
        '1stPage':  (context)=>FirstPage(),

        'map&nav':  (context)=>MapView(false,false),
      },
    );
  }
}

