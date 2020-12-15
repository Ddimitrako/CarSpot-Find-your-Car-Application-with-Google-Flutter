import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_maps2/appInfo.dart';
import 'package:flutter_maps2/map&nav.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_maps2/settings.dart';
class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  bool saveParkingSpotPressed = false;
  bool showParkingSpotPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        appBar: AppBar(
          title: Text(" Find your Car Application"),
          actions: <Widget>[
            PopupMenuButton(
              icon: Icon(Icons.menu),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text("Car Icon"),
                  value: 0,
                ),

                PopupMenuItem(
                  child: Text("App Info"),
                  value: 1,
                ),
              ],
              onSelected: (result) {
                if (result == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Settings()),
                  );
                }
                else{Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppInfo()),
                );}
              },),
          ],
        ),
        body: SafeArea(
      child: Stack(
        children: [
          //Image.asset('assets/car_icon1.jpg',height: 100,width: 140,),
          //Image.asset('assets/Location_icon_black.jpg',height: 100,width: 140,),
          Image.asset(
            'assets/black_bgr.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
          ),

          Column(

            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                child: ClipRRect(
                child: Image.asset(
                  'assets/earth.jpg',
                  height: 360,
                ),
                borderRadius: BorderRadius.circular(262),
            ),
              ),
              SizedBox(height: 20),
              FlatButton.icon(
                onPressed: () {
                  //edw na bei mia if pou na elegxei an uparxei sosmenei topothesia
                  showParkingSpotPressed = true;
                  showAlertDialog(context,showParkingSpotPressed);

                  //Navigator.pushNamed(context, 'map&nav');
                },
                icon: Icon(Icons.directions_car),
                color: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.blue)),
                label: Text("Find Car",style:TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
              ),
              SizedBox(height: 20),
              FlatButton.icon(
                onPressed: () {
                  saveParkingSpotPressed = true;
                  showParkingSpotPressed = false;
                  Navigator.push(context,MaterialPageRoute(builder: (context) =>
                      MapView(saveParkingSpotPressed, showParkingSpotPressed)));
                },
                icon: Icon(Icons.add_location),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.blue)),
                color: Colors.blue,
                label: Text("Save New Location",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
              ),
          ],),
         /* SafeArea(
            child: Container(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 180),
                child:
              ),
            ),
          ),*/
         /*Container(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: FlatButton.icon(
                onPressed: () {
                  saveParkingSpotPressed = true;
                  showParkingSpotPressed = false;
                  Navigator.push(context,MaterialPageRoute(builder: (context) =>
                              MapView(saveParkingSpotPressed, showParkingSpotPressed)));
                },
                icon: Icon(Icons.add_location),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.blue)),
                color: Colors.blue,
                label: Text("Save New Location",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
              ),
            ),
          )*/
        ],
      ),
    ));
  }
}

showAlertDialog(BuildContext context,showParkingSpotPressed) async{
  // set up the buttons
  final prefs = await SharedPreferences.getInstance();
  final value1 = prefs.getDouble('longtitude') ?? 0;
  final value2 = prefs.getDouble('langtitude') ?? 0;
  if(value1==null && value2==null) {
    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = FlatButton(
      child: Text("Continue"),
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.push(context, MaterialPageRoute(builder: (context) =>
            MapView(true, true)));
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Please Note!"),
      content: Text(
          "There is no saved parking spot.Would you like to continue with saving a new location?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
  else{Navigator.push(context, MaterialPageRoute(builder: (context) =>
      MapView(true, true)));}
}
