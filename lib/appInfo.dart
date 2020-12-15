
import 'package:flutter/material.dart';


class AppInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("App Information"),
      ),
      body: Center(
        child: Column(
            children: <Widget>[ RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children:  [
                TextSpan(
                  text: "Creator: Dimitris Dimitrakopoulos\n",
                  style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 18,decoration: TextDecoration.none,),
                ),
                TextSpan(
                  text: "App Version 1.0.0\n",
                  style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 18,decoration: TextDecoration.none,),
                ),
                TextSpan(
                  text: "You are a very beatiful and important person!!\n",
                  style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 18,decoration: TextDecoration.none,),
                ),
                TextSpan(
                  text: "I am a handsome electric and computer engineer\n",
                  style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 18,decoration: TextDecoration.none,),
                ),
              ],
            ),
          ),
        ]),
        ),

    );
  }
}