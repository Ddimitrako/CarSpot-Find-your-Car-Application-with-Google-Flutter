/*<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />*/
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart' as loc;

import 'package:firebase_admob/firebase_admob.dart';
import 'package:admob_flutter/admob_flutter.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize without device test ids.
  //FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-3095340973940268~3673479564');
  //Correct AppID:'ca-app-pub-3095340973940268~3673479564'
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapView(true, true),
    );
  }
}

class MapView extends StatefulWidget {
  bool saveParkingSpotPressed;
  bool showParkingSpotPressed;
  //if you have multiple values add here
  MapView(this.saveParkingSpotPressed, this.showParkingSpotPressed, {Key key})
      : super(key: key); //add also..example this.abc,this...
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  static GoogleMapController mapController;
  MapType mapType = MapType.hybrid;
  final Geolocator _geolocator = Geolocator();
  static var showHideRouteVar = true;
  Position _currentPosition;
  String _currentAddress;
  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  String _startAddress = '';
  String _destinationAddress = '';
  String _placeDistance;

  Set<Marker> markers = {};

  BannerAd _bannerAd;
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: 'ca-app-pub-3095340973940268/2699626472',
      size: AdSize.banner,
      listener: (MobileAdEvent event) {
        print("BannerAd event $event");
      },
    );
  }

  PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  loc.Location location =
      loc.Location(); //explicit reference to the Location class

  checkGPS() async {
    if (!await location.serviceEnabled()) {
      location.requestService();
    }
  }

  Widget _textField({
    TextEditingController controller,
    String label,
    String hint,
    String initialValue,
    double width,
    Icon prefixIcon,
    Widget suffixIcon,
    Function(String) locationCallback,
  }) {
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        // initialValue: initialValue,
        decoration: new InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey[400],
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue[300],
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  // Method for retrieving the current location
  _getCurrentLocation() async {
    await _geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  // Method for retrieving the address
  _getAddress() async {
    try {
      List<Placemark> p = await _geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print('_getAdress Exception:' + e);
    }
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance() async {
    try {
      // Retrieving placemarks from addresses
      List<Placemark> startPlacemark =
          await _geolocator.placemarkFromAddress(_startAddress);
      List<Placemark> destinationPlacemark =
          await _geolocator.placemarkFromAddress(_destinationAddress);

      if (startPlacemark != null && destinationPlacemark != null) {
        // Use the retrieved coordinates of the current position,
        // instead of the address if the start position is user's
        // current position, as it results in better accuracy.
        Position startCoordinates = _startAddress == _currentAddress
            ? Position(
                latitude: _currentPosition.latitude,
                longitude: _currentPosition.longitude)
            : startPlacemark[0].position;
        Position destinationCoordinates = destinationPlacemark[0].position;

        // Start Location Marker
        Marker startMarker = Marker(
          markerId: MarkerId('$startCoordinates'),
          position: LatLng(
            startCoordinates.latitude,
            startCoordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Start',
            snippet: _startAddress,
          ),
          icon: BitmapDescriptor.defaultMarker,
        );

        // Destination Location Marker
        Marker destinationMarker = Marker(
          markerId: MarkerId('$destinationCoordinates'),
          position: LatLng(
            destinationCoordinates.latitude,
            destinationCoordinates.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationAddress,
          ),
          icon: BitmapDescriptor.defaultMarker,
        );

        // Adding the markers to the list
        markers.add(startMarker);
        markers.add(destinationMarker);

        print('START COORDINATES: $startCoordinates');
        print('DESTINATION COORDINATES: $destinationCoordinates');

        Position _northeastCoordinates;
        Position _southwestCoordinates;

        // Calculating to check that
        // southwest coordinate <= northeast coordinate
        if (startCoordinates.latitude <= destinationCoordinates.latitude) {
          _southwestCoordinates = startCoordinates;
          _northeastCoordinates = destinationCoordinates;
        } else {
          _southwestCoordinates = destinationCoordinates;
          _northeastCoordinates = startCoordinates;
        }

        // Accomodate the two locations within the
        // camera view of the map
        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              northeast: LatLng(
                _northeastCoordinates.latitude,
                _northeastCoordinates.longitude,
              ),
              southwest: LatLng(
                _southwestCoordinates.latitude,
                _southwestCoordinates.longitude,
              ),
            ),
            100.0,
          ),
        );

        // Calculating the distance between the start and the end positions
        // with a straight path, without considering any route
        // double distanceInMeters = await Geolocator().bearingBetween(
        //   startCoordinates.latitude,
        //   startCoordinates.longitude,
        //   destinationCoordinates.latitude,
        //   destinationCoordinates.longitude,
        // );

        await _createPolylines(startCoordinates, destinationCoordinates);

        double totalDistance = 0.0;

        // Calculating the total distance by adding the distance
        // between small segments
        for (int i = 0; i < polylineCoordinates.length - 1; i++) {
          totalDistance += _coordinateDistance(
            polylineCoordinates[i].latitude,
            polylineCoordinates[i].longitude,
            polylineCoordinates[i + 1].latitude,
            polylineCoordinates[i + 1].longitude,
          );
        }

        setState(() {
          _placeDistance = totalDistance.toStringAsFixed(2);
          print('DISTANCE: $_placeDistance km');
        });

        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  // Formula for calculating distance between two coordinates
  // https://stackoverflow.com/a/54138876/11910277
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Create the polylines for showing the route between two places
  _createPolylines(Position start, Position destination) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyDmtKTKLGnoJ33N0V_eCCvKj5PJKIkaYEQ', // Google Maps API Key
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.transit,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }

  @override
  void initState() {
    super.initState();
    Admob.initialize(testDeviceIds: ['ca-app-pub-3095340973940268/5160022870']);
    _read();
    _getCurrentLocation();
    checkGPS();
    print(widget.showParkingSpotPressed);
    print(widget.saveParkingSpotPressed);
    //FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-3095340973940268~3673479564');
    _bannerAd = createBannerAd()..load();
    _bannerAd ??= createBannerAd();
    _bannerAd
      ..load()
      ..show(anchorOffset: 30.0,
        // Positions the banner ad 10 pixels from the center of the screen to the right
        horizontalCenterOffset: 10.0,
        // Banner Position
        anchorType: AnchorType.top);

  }
   void dispose() {
   // _bannerAd?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      width: width,
      child: Scaffold(
        
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
          SafeArea(
            child:
            GoogleMap(
              markers: markers != null ? Set<Marker>.from(markers) : null,
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: mapType,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              onTap: _saveParkingSpot,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            )),

            SafeArea(child: Align(child: AdmobBanner(adUnitId: 'ca-app-pub-3095340973940268/2699626472',adSize: AdmobBannerSize.BANNER),alignment: Alignment.topCenter,)),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Offstage(
                    offstage: showHideRouteVar == true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                      ),
                      width: width * 0.9,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Places',
                              style: TextStyle(fontSize: 20.0),
                            ),
                            SizedBox(height: 10),
                            _textField(
                                label: 'Start',
                                hint: 'Choose starting point',
                                initialValue: _currentAddress,
                                prefixIcon: Icon(Icons.looks_one),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.my_location),
                                  onPressed: () {
                                    startAddressController.text =
                                        _currentAddress;
                                    _startAddress = _currentAddress;
                                  },
                                ),
                                controller: startAddressController,
                                width: width,
                                locationCallback: (String value) {
                                  setState(() {
                                    _startAddress = value;
                                  });
                                }),
                            SizedBox(height: 10),
                            _textField(
                                label: 'Destination',
                                hint: 'Choose destination',
                                initialValue: '',
                                prefixIcon: Icon(Icons.looks_two),
                                controller: destinationAddressController,
                                width: width,
                                locationCallback: (String value) {
                                  setState(() {
                                    _destinationAddress = value;
                                  });
                                }),
                            SizedBox(height: 10),
                            Text(
                              'DISTANCE: $_placeDistance km',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            RaisedButton(
                              onPressed: (_startAddress != '' &&
                                      _destinationAddress != '')
                                  ? () async {
                                      setState(() {
                                        if (markers.isNotEmpty) markers.clear();
                                        if (polylines.isNotEmpty)
                                          polylines.clear();
                                        if (polylineCoordinates.isNotEmpty)
                                          polylineCoordinates.clear();
                                        _placeDistance = null;
                                      });

                                      _calculateDistance().then((isCalculated) {
                                        if (isCalculated) {
                                          _scaffoldKey.currentState
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Distance Calculated Sucessfully'),
                                            ),
                                          );
                                        } else {
                                          _scaffoldKey.currentState
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error Calculating Distance'),
                                            ),
                                          );
                                        }
                                      });
                                    }
                                  : null,
                              color: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Show Route'.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Show current location button
            /*SafeArea(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 70),
                  child: FloatingActionButton.extended(
                    heroTag:"btn1",
                    backgroundColor: Colors.lightBlueAccent.withOpacity(0.75),
                    foregroundColor: Colors.black,
                    splashColor: Colors.orange,
                    onPressed: () {
                      setState(() {
                        ShowHideRouteFunc();
                      });
                    },
                    label: Text('Route'),
                    icon: Icon(Icons.directions),
                  ),
                ),
              ),
            ),*/
            //find parked car button

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.lightBlueAccent
                            .withOpacity(0.75), // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ), //ZoomIn Btn
                    SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.lightBlueAccent
                            .withOpacity(0.75), // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.lightBlueAccent
                            .withOpacity(0.75), // button color
                        child: InkWell(
                          splashColor: Colors.black, // inkwell color
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.my_location),
                          ),
                          onTap: () {
                            try {
                              mapController.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(
                                      _currentPosition.latitude,
                                      _currentPosition.longitude,
                                    ),
                                    zoom: 18.0,
                                  ),
                                ),
                              );
                            } catch (e) {
                              print(
                                  'Turn on Gps'); //edw na bei ena popup pou na anoigei to gps
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.lightBlueAccent
                            .withOpacity(0.75), // button color
                        child: InkWell(
                          splashColor: Colors.black, // inkwell color
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.map),
                          ),
                          // ignore: unnecessary_statements
                          onTap: _changeMapType,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Visibility(
                      visible: widget.showParkingSpotPressed,
                      child: FloatingActionButton.extended(
                        heroTag: "btn23",
                        backgroundColor:
                            Colors.lightBlueAccent.withOpacity(0.75),
                        foregroundColor: Colors.black,
                        splashColor: Colors.orange,
                        label: Text('Find Parked Car'),
                        onPressed: _showParkingSpot,
                        icon: Icon(Icons.directions_car),
                      ), //ZoomOut Btn
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  //*********************code from map.dart ***********************************//


  void _saveParkingSpot(LatLng tappedPoint) {
    if (widget.showParkingSpotPressed == false) {
      print('tappedPoint $tappedPoint');
      _handleTap(tappedPoint);
      _save(tappedPoint.latitude, tappedPoint.longitude);
    }
  }

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load("assets/car_icon.png");
    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  _handleTap(LatLng tappedPoint) async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/car_icon.png', 70);

    setState(() {
      markers = {};
      markers.add(Marker(
        markerId: MarkerId(tappedPoint.toString()),
        position: LatLng(tappedPoint.latitude, tappedPoint.longitude),
        rotation: 0.0,
        draggable: true,
        icon: BitmapDescriptor.fromBytes(markerIcon),
      ));
    });
  }
  //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ShowParkingSpot$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

  void _showParkingSpot() async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = 'longtitude';
    final key2 = 'Langtitude';
    final value1 = prefs.getDouble(key1) ?? 0;
    final value2 = prefs.getDouble(key2) ?? 0;
    print('read: $value1');
    print('read: $value2');
    double x = value1;
    double y = value2;
    refresh();
    _savedSpotMarker(x, y);

  }

  void _savedSpotMarker(double x, double y) async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/car_icon.png', 70);
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(LatLng(x, y), 18.8);
    _MapViewState.mapController.animateCamera(cameraUpdate);
    setState(() {
      print('saved car position marker placement');
      Marker carMarker = Marker(
        markerId: MarkerId('destinationCoordinates'),
        position: LatLng(
          x,
          y,
        ),
        infoWindow: InfoWindow(
          title: 'Car Location',
        ),
        icon: BitmapDescriptor.fromBytes(markerIcon),
      );
      markers.add(carMarker);
    });
  }

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$read write$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$//
  _read() async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = 'longtitude';
    final key2 = 'Langtitude';
    final value1 = prefs.getDouble(key1) ?? 0;
    final value2 = prefs.getDouble(key2) ?? 0;
    print('read: $value1');
    print('read: $value2');
  }

  _save(data1, data2) async {
    final prefs = await SharedPreferences.getInstance();
    final key1 = 'longtitude';
    final value1 = data1;
    final key2 = 'Langtitude';
    final value2 = data2;
    prefs.setDouble(key1, value1);
    prefs.setDouble(key2, value2);
    print('saved $value1');
    print('saved $value2');
  }

  refresh() {
    setState(() {});
  }

  void _changeMapType() {
    if (mapType == MapType.hybrid) {
      mapType = MapType.normal;
    } else
      mapType = MapType.hybrid;
    print('mapType= $mapType');
    refresh();
  }
}
//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

void ShowHideRouteFunc() {
  if (_MapViewState.showHideRouteVar == true) {
    _MapViewState.showHideRouteVar = false;
  } else
    _MapViewState.showHideRouteVar = true;
  print(_MapViewState.showHideRouteVar);

  //CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(latLng, zoom);
  //_MapViewState.mapController.animateCamera(cameraUpdate);
}
