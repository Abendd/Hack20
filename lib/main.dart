import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intent/extra.dart';
import 'package:intent/intent.dart' as android_intent;
import 'package:intent/action.dart' as android_action;
import 'package:intent/extra.dart' as android_extra;
import 'package:intent/category.dart' as android_category;
import 'package:intent/flag.dart' as android_flag;
import 'package:launcher_assist/launcher_assist.dart';
import 'main2.dart';
import 'pageController.dart';

import 'package:android_intent/android_intent.dart';

void main() => runApp(new MaterialApp(
       builder: (context, child) {
    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: child,
    );
  },
      debugShowCheckedModeBanner: false,
      home: PageGo(),
    ));
class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var installedApps;

  bool accessStorage;

  @override
  initState() {
    accessStorage = false;
    super.initState();
    // Get all apps
    LauncherAssist.getAllApps().then((var apps) {
      setState(() {
        installedApps = apps;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get wallpaper as binary data
    if (accessStorage) {
      setState(() {});
      print("set state called");
    }

    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.grey),
        home: Stack(
          children: <Widget>[
            // WallpaperContainer(wallpaper: widget.wallpaper),
            Scaffold(
      
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomPadding: false,
              body: WillPopScope(
                onWillPop: () => Future(() => false),
                child: Stack(
                  children: <Widget>[
                    installedApps != null
                        ? ForegroundWidget(installedApps: installedApps)
                        : Container(),
                    accessStorage
                        ? Container()
                        : Positioned(
                            top: 0,
                            left: 20,
                            child: SafeArea(
                              child: Tooltip(
                                message:
                                    "Click this to allow storage permission",
                              ),
                            ),
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
}

class ForegroundWidget extends StatefulWidget {
  const ForegroundWidget({
    Key key,
    @required this.installedApps,
  }) : super(key: key);

  final installedApps;

  @override
  _ForegroundWidgetState createState() => _ForegroundWidgetState();
}

List<Map<String, String>> appx=[];

class _ForegroundWidgetState extends State<ForegroundWidget>
    with SingleTickerProviderStateMixin {
  
  AnimationController opacityController;
  Animation<double> _opacity;

  @override
  void initState() {
    filtered = widget.installedApps;
    super.initState();
    opacityController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(opacityController);
  }

  TextEditingController editingController = TextEditingController();

  List<dynamic> filtered = List();

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    opacityController.forward();
    return FadeTransition(
      opacity: _opacity,
      child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
         //   margin: EdgeInsets.only(left: 10, right: 10),
            child: TextFormField(
              onChanged: (string) {
                print("=====1=====");
                setState(() {
                  filtered = widget.installedApps
                      .where((u) => (u['label']
                          .toString()
                          .toLowerCase()
                          .contains(string.toLowerCase())))
                      .toList();
                });
              },
              controller: editingController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Search",
                hintStyle: TextStyle(color: Colors.white60),
                prefixIcon: Icon(Icons.search, color: Colors.white60),
              ),
            ),
          ),
          Expanded(
              // height: h/1.3,
              // margin: EdgeInsets.only(top: h/35),

              child: filtered.length > 0
                  ? gridViewContainer(filtered)
                  : Container(
                      child: Center(
                          child: Text("No Results",
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white70,
                              ))),
                    )),
        ],
      ),
    );
  }

  bool x = true;

  gridViewContainer(installedApps) {
    // installedApps.sort();
    List<dynamic> apps = filtered;
    return ListView.builder(
        itemCount: filtered != null ? filtered.length : 0,
        itemBuilder: (context, index) {
          x
              ? filtered.sort((a, b) => a['label'].compareTo(b['label']))
              : filtered;

          return GestureDetector(
              onLongPress: () {
                FocusScope.of(context).requestFocus(new FocusNode());
                print('========22=========');
                final AndroidIntent intents = new AndroidIntent(
                  action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                  package: "${filtered[index]["package"]}",
                  data: "package:${filtered[index]["package"]}",
                  //     package: 'com.example.flutter_launcher',
                  // data: "package:com.example.flutter_launcher",
                );
                intents.launch();
              },
              
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(bottom:10),
                      // padding: EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        //mainAxisSize: MainAxisSize.min, //change here
                        children: <Widget>[
                        //  iconContainer(index),
                          SizedBox(width: 10),

                          Text(
                            filtered[index]["label"],

                            style: TextStyle(color: Colors.white, fontSize: 18,fontFamily: 'Arame-Regular'),
                            textAlign: TextAlign.center,
                            // maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Text(filtered [index]["package"], style: TextStyle(   //package name
                          //     color: Colors.white,fontSize: 10
                          //   ),),
                        ],
                      ),
                    ),

                    //For making app star and fav...
              //       IconButton(icon: Icon(Icons.star,color: Colors.white60,), onPressed: ()
              //       {
              //  // appx.add("")
              //  setState(() {
              //     appx.add({
              //    "name": filtered[index]["label"],
              //    "package": filtered[index]["label"]
              //  });
              //  });
              
                   
              //                            print(   filtered.elementAt(index)['label']);

              //                            print(appx);
              //       })
                  ],
                ),
              
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
                LauncherAssist.launchApp(filtered[index]["package"]);
              });
        });
  }

  iconContainer(index) {
    try {
      return Stack(
        children: <Widget>[
          Image.memory(
            filtered[index]["icon"] != null
                ? filtered[index]["icon"]
                : Uint8List(0),
            height: 45,
            width: 45,
            color: Colors.white.withOpacity(0.9)
          ),
        ],
      );
    } catch (e) {
      return Container();
    }
  }
}

class WallpaperContainer extends StatelessWidget {
  const WallpaperContainer({
    Key key,
    @required this.wallpaper,
  }) : super(key: key);

  final wallpaper;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          color: Colors.deepOrangeAccent[100],
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Image.memory(
            wallpaper != null ? wallpaper : Uint8List(0),
            fit: BoxFit.cover,
          ),
        ),
        Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.black.withOpacity(0.35)),
      ],
    );
  }
}
