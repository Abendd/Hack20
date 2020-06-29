import 'package:flutter/material.dart';
import 'package:flutter_launcher/main2.dart';
import 'package:launcher_assist/launcher_assist.dart';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:launcher_assist/launcher_assist.dart';
import './pageController.dart';

class MainApps extends StatefulWidget {
  // final wallpaper;
  // MainApps(this.wallpaper);
  
  @override
  _MainAppsState createState() => _MainAppsState();
}

class _MainAppsState extends State<MainApps> {
  // var wallpaper;
  //  bool accessStorage;




 
  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    return Stack(
      children: <Widget>[
    // WallpaperContainer(wallpaper: widget.wallpaper),
        Scaffold(
          backgroundColor: Colors.transparent,
    //  appBar: AppBar(
    //      backgroundColor: Colors.transparent,
    //                       elevation: 0,
    //  ),
          body:     SingleChildScrollView(
                      child: Stack(
                        children: <Widget>[
                         
                          Container(
                            margin: EdgeInsets.only(top:h/35),
                            child: Column(
                              
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                   launcher("com.samsung.android.dialer","phone",Icon(Icons.phone,color: Colors.white.withOpacity(0.6),)),
                  //  launcher("com.whatsapp","Whatsapp"),
                  //  launcher("com.spotify.music","Spotify"),
                  //  launcher("com.google.android.gm","Gmail"),
                  //  launcher("com.linkedin.android","LinkedIn"),
                  //  launcher("com.google.android.youtube","YouTube"),
                  //  launcher("com.kkr.journal","Journal"),
                  //  launcher("com.sec.android.gallery3d","Photos"),//com.sec.androif.app.launcher
                  //  Container(
                  //    color: Colors.pink,
                  //    height: 300,
                  //    child: ListView.builder(
                           
                  //      itemCount: appx.length,
                  //      itemBuilder: (context,index){

                  //      return launcher("com.sec.android.gallery3d","Photos");
                  //    }),
                  //  )
                   
      //hamburger(neeche ad) -> logo -> terms condition -> mon-sun ->time reminder->share ->banner ad
                            ],
                    ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

Widget  launcher(String package, String name, Icon icon)
  {
    return Container(
      
      width: MediaQuery.of(context).size.width/8,
      margin: EdgeInsets.only(top:20),
                        child: RaisedButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.white.withOpacity(0.6),)
                          ),
                          
                          onPressed: () =>
                              LauncherAssist.launchApp("$package"),
                          color: Colors.transparent,
                          elevation: 0,
                          child: icon
                        ),
                      );
  }
}

