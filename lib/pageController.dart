import 'dart:typed_data';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_launcher/main2.dart';
import 'package:flutter_launcher/mainapps.dart';


import 'package:flutter/services.dart';
import 'package:launcher_assist/launcher_assist.dart';
import 'package:permission_handler/permission_handler.dart';

import 'main.dart';


class PageGo extends StatefulWidget {
  @override
  _PageGoState createState() => _PageGoState();
}

class _PageGoState extends State<PageGo> {
  PageController _controller = PageController(
    initialPage: 0,
);
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

    var wallpaper;
   bool accessStorage=true;
   Future<bool> handleStoragePermissions() async {
    PermissionStatus storagePermissionStatus = await _getPermissionStatus();

    if (storagePermissionStatus == PermissionStatus.granted) {
      //which means that we have been given the permission to access device storage,
      return true;
    } else {
      _handleInvalidPermissions(storagePermissionStatus);
      return false;
    }
  }

  Future<PermissionStatus> _getPermissionStatus() async {
    print("inside get permission status");
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.disabled) {
      Map<PermissionGroup, PermissionStatus> permissionStatus =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.storage]);
      return permissionStatus[PermissionGroup.storage] ??
          PermissionStatus.unknown;
    } else {
      print("already granted");
      return permission;
    }
  }

  void _handleInvalidPermissions(
    PermissionStatus storagePermissionStatus,
  ) {
    if (storagePermissionStatus == PermissionStatus.denied) {
      throw new PlatformException(
          code: "PERMISSION_DENIED",
          message: "Access to location data denied",
          details: null);
    } else if (storagePermissionStatus == PermissionStatus.disabled) {
      throw new PlatformException(
          code: "PERMISSION_DISABLED",
          message: "Location data is not available on device",
          details: null);
    }
  }
    @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
  ]);
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
       handleStoragePermissions().then((permissionGranted) {
      if (permissionGranted) {
        LauncherAssist.getWallpaper().then((imageData) {
          setState(() {
            wallpaper = imageData;
        accessStorage = !accessStorage;
          });
        });
      } else {
        print("inside of the else part ");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
     double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    return Stack(
      children: <Widget>[
      Container(
        width: double.infinity,
        child: Image.memory(
            wallpaper != null ? wallpaper : Uint8List(0),
            fit: BoxFit.cover,
          ),
      ),
        BackdropFilter(
            filter: new ImageFilter.blur(sigmaX: 30.0, sigmaY:30.0),
                  child: Container(
                 height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.black.withOpacity(0.1)
          ),
        ),
        Scaffold(
          resizeToAvoidBottomPadding: false,
backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              HomePage(),
              Container(
                height: h/1.5,
                width: w/3,
                margin: EdgeInsets.only(left:w/4,top: h/6),
                
                child: MyApp())
            ],
          )
          
//           CarouselSlider(
            
//             options:
//   CarouselOptions(
    
//         enableInfiniteScroll: false,
// viewportFraction: 0.99999,
//   height:h,
//         autoPlay: false,
//         initialPage: 0,
//  enlargeCenterPage: false,
  
//   ),
//   items: [
//         HomePage(),
//   //MyApp(),
  
   
// ],
// ),
          


 
          
        ),
      ],
    );
  }
}