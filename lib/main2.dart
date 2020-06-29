import 'dart:async';
import 'dart:convert';
import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors/sensors.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:launcher_assist/launcher_assist.dart';
import 'package:battery/battery.dart';
import 'package:sms/sms.dart';

class Anim {
  String name;
  double _value = 0, pos = 0, min, max, speed;
  bool endless = false;
  ActorAnimation actor;
  Anim(this.name, this.min, this.max, this.speed, this.endless);
  get value => _value * (max - min) + min;
  set value(double v) => _value = (v - min) / (max - min);
}

class AniControl extends FlareControls {
  List<Anim> items;
  AniControl(this.items);

  @override
  bool advance(FlutterActorArtboard board, double elapsed) {
    super.advance(board, elapsed);
    for (var a in items) {
      if (a.actor == null) continue;
      var d = (a.pos - a._value).abs();
      var m = a.pos > a._value ? -1 : 1;
      if (a.endless && d > 0.5) {
        m = -m;
        d = 1.0 - d;
      }
      var e = elapsed / a.actor.duration * (1 + d * a.speed);
      a.pos = e < d ? (a.pos + e * m) : a._value;
      if (a.endless) a.pos %= 1.0;
      a.actor.apply(a.actor.duration * a.pos, board, 1.0);
    }
    return true;
  }

  @override
  void initialize(FlutterActorArtboard board) {
    super.initialize(board);
    items.forEach((a) => a.actor = board.getAnimation(a.name));
  }

  operator [](String name) {
    for (var a in items) if (a.name == name) return a;
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
   int _batteryLevel;
  final Battery _battery = Battery();

  BatteryState _batteryState;
  int mode = 0, map = 0;
  AniControl compass;
  AniControl earth;
  double lat, lon;

  String city = '', weather = '', icon = '01d';
  double temp = 0, humidity = 0;

  void getWeather() async {
    var key = '7c5c03c8acacd8dea3abd517ae22af34';
    var url =
        'http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$key';
    var resp = await http.Client().get(url);
    var data = json.decode(resp.body);
    city = data['name'];
    var m = data['weather'][0];
    weather = m['main'];
    icon = m['icon'];
    m = data['main'];
    temp = m['temp'] - 273.15;
    humidity = m['humidity'] + 0.0;
    setState(() {});
  }

  void setLocation(double lati, double long, [bool weather = true]) {
    earth['lat'].value = lat = lati;
    earth['lon'].value = lon = long;
    if (weather) getWeather();
    setState(() {});
  }

  void locate() => Location()
      .getLocation()
      .then((p) => setLocation(p.latitude, p.longitude));

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    super.initState();
    fun();
    batteryx();
    //startTimer();

    compass = AniControl([
      Anim('dir', 0, 360, 45, true),
      Anim('hor', -9.6, 9.6, 20, false),
      Anim('ver', -9.6, 9.6, 20, false),
    ]);

    earth = AniControl([
      Anim('dir', 0, 360, 20, true),
      Anim('lat', -90, 90, 1, false),
      Anim('lon', -180, 180, 1, true),
    ]);

    FlutterCompass.events.listen((angle) {
      compass['dir'].value = angle;
      earth['dir'].value = angle;
    });

    accelerometerEvents.listen((event) {
      compass['hor'].value = -event.x;
      compass['ver'].value = -event.y;
    });

    setLocation(0, 0);
    locate();
  }

  // void startTimer() {
  //   // Start the periodic timer which prints something every 1 seconds
  //   _timer = new Timer.periodic(new Duration(seconds: 1), (time) {
  //     setState(() {
  //       _start = time.tick;
  //     });
  //   });
  // }

  Widget Compass() {
    return GestureDetector(
      onTap: () => setState(() => mode++),
      child: FlareActor(
        "assets/compass.flr",
        animation: 'mode${mode % 2}',
        controller: compass,
      ),
    );
  }

  Widget Earth() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
       // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(city,
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Arame-Regular',
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          // Text('lat:${lat.toStringAsFixed(2)}  lon:${lon.toStringAsFixed(2)}'),
          Expanded(
            //flex: 8,
            child: GestureDetector(
              onTap: () => setState(() => earth.play('mode${++map % 2}')),
              onDoubleTap: locate,
              onPanUpdate: (pan) => setLocation(
                  (lat - pan.delta.dy).clamp(-90.0, 90.0),
                  (lon - pan.delta.dx + 180) % 360 - 180,
                  false),
              onPanEnd: (_) => getWeather(),
              child: FlareActor("assets/earth.flr",
                  animation: 'pulse', controller: earth,fit: BoxFit.contain,),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Container(
            //     width: 18,
            //     height: 18,
            //     child: FlareActor('assets/weather.flr', animation: icon)),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${temp.toInt()}°',
                  style: TextStyle(fontSize: 18, color: Colors.white,fontFamily: 'Arame-Regular')),
               Text("  ",  style: TextStyle(fontSize: 8, color: Colors.white,fontFamily: 'Arame-Regular')),
               Text('Humidity ${humidity.toInt()}%',  style: TextStyle(fontSize: 18, color: Colors.white,fontFamily: 'Arame-Regular')),
            ]),
          ]),
        ]);
  }
 List<SmsMessage> messages; 
SmsQuery query = new SmsQuery();
fun() async {
    List<SmsMessage> m = await query.getAllSms;
    setState(() {
      messages = m;
    });
  }

  batteryx()
  async {
    final _battery = Battery();
    _battery.batteryLevel.then((level) {
      this.setState(() {
        _batteryLevel = level;
      });
    });
        _battery.onBatteryStateChanged.listen((BatteryState state) {
      _battery.batteryLevel.then((level) {
        this.setState(() {
          _batteryLevel = level;
          _batteryState = state;
        });
      });
    });
  }
  @override
  Widget build(BuildContext context) {
 
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    return
        // Scaffold(
        //   backgroundColor: Colors.transparent,

        //   body: (_start / 5) % 2 < 1.0 ? Compass() : Earth());

        SafeArea(
      child: Scaffold(
          resizeToAvoidBottomPadding: false,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                     margin: EdgeInsets.only(left: w/40, top: 5),
                    child: Text("Hello Mr Stark,",
                        style: TextStyle(fontSize: 32, color: Colors.white,fontFamily: 'Arame-Regular')),
                  ),
                         InkWell(
                    onTap: () async {
                      FocusScope.of(context).requestFocus(new FocusNode());
                      print("-----------1-1------");

                      final AndroidIntent intent = new AndroidIntent(
                        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                        package: 'com.example.flutter_launcher',
                        data: "package:com.example.flutter_launcher",
                      );
                      intent.launch();
                    },
                    child: Container(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Arame-Regular',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
             
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                         margin: EdgeInsets.only(left: w / 1.8,top: h/8,right: w/30),
                      
                        height: h/2.6,
                        width: w/2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10,),
                          border: Border.all(color: Colors.white.withOpacity(0.5))

                      

                          //messages.elementAt(i).body
                        ),
                        child: ListView.builder(itemBuilder: (context,i)
                        {
                        
                          return messages==null? Container(child: Center(child: Text("Loading",   style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Arame-Regular',
                          color: Colors.white,
                        )),),):
                        Container(
                          padding: EdgeInsets.all(5),
                          child: Text(messages.elementAt(i).body,style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Arame-Regular',
                          color: Colors.white.withOpacity(0.8),
                        )),
                        );

                        }),
                      ),
                      Container(
                          margin: EdgeInsets.only(left: w / 1.25,top: 0.5),
                          height: h / 3,
                          child: Compass()),
                        
                         
                    ],
                  ),
Container(
  margin: EdgeInsets.only(left:w/1.8,top: h/1.7),

 height: h/5,
 width: w/4,
  child: CustomPaint(
                painter: _BatteryLevelPainter(_batteryLevel, _batteryState),
                child: _batteryState == BatteryState.charging
                    ? Icon(Icons.flash_on)
                    : Container(),
              ),
)
         ,  
             
                          Container(
                          margin: EdgeInsets.only(
                            right: w / 1.3,top: h/5
                          ),
                          height: h / 1.7,
                          child: Earth()),


                      Container(
 margin:EdgeInsets.only(top:h/1.2),
  child: ListView(
    padding: EdgeInsets.only(left:10,bottom: 5),
    scrollDirection: Axis.horizontal,
    children: <Widget>[
      launcher("com.samsung.android.dialer","phone",Icon(Icons.phone,color: Colors.white.withOpacity(0.6),size: 35,)),
       launcher("com.samsung.android.calendar","phone",Icon(Icons.calendar_today,color: Colors.white.withOpacity(0.6),size: 35,)),
        launcher("com.samsung.android.dialer","phone",Icon(Icons.stay_current_portrait,color: Colors.white.withOpacity(0.6),size: 35,)),
         launcher("com.samsung.android.dialer","phone",Icon(Icons.style,color: Colors.white.withOpacity(0.6),size: 35,)),
          launcher("com.samsung.android.dialer","phone",Icon(Icons.subtitles,color: Colors.white.withOpacity(0.6),size: 35,)),
           launcher("com.samsung.android.dialer","phone",Icon(Icons.perm_phone_msg,color: Colors.white.withOpacity(0.6),size: 35,)),
            launcher("com.samsung.android.dialer","phone",Icon(Icons.party_mode,color: Colors.white.withOpacity(0.6),size: 35,)),
             launcher("com.samsung.android.dialer","phone",Icon(Icons.phonelink,color: Colors.white.withOpacity(0.6),size: 35,)),
                        launcher("com.samsung.android.dialer","phone",Icon(Icons.perm_phone_msg,color: Colors.white.withOpacity(0.6),size: 35,)),
            launcher("com.samsung.android.dialer","phone",Icon(Icons.party_mode,color: Colors.white.withOpacity(0.6),size: 35,)),
             launcher("com.samsung.android.dialer","phone",Icon(Icons.phonelink,color: Colors.white.withOpacity(0.6),size: 35,)),
             

    ],
  )
  
 
),

               
            ],
          )),
    );
  }
  Widget  launcher(String package, String name, Icon icon)
  {
    return Column(
      children: <Widget>[
        Container(
          
          width: MediaQuery.of(context).size.width/9,
          margin: EdgeInsets.only(top:0,left: 0),
                            child: RaisedButton(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              //  side: BorderSide(color: Colors.white.withOpacity(0.6),)
                              ),
                              
                              onPressed: () =>
                                  LauncherAssist.launchApp("$package"),
                              color: Colors.transparent,
                              elevation: 0,
                              child: icon
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                               boxShadow: [BoxShadow(
      color: Colors.white,
      blurRadius: 2.0,
    ),]
                            ),
                            width: MediaQuery.of(context).size.width/16,
                            height:  MediaQuery.of(context).size.height/196,
                        
                          )
      ],
    );
  }
}



class _BatteryLevelPainter extends CustomPainter {
  final int _batteryLevel;
  final BatteryState _batteryState;

  _BatteryLevelPainter(this._batteryLevel, this._batteryState);

  @override
  void paint(Canvas canvas, Size size) {
    Paint getPaint(
        {Color color = Colors.white,
        PaintingStyle style = PaintingStyle.stroke}) {
      return Paint()
        ..color = color
        ..strokeWidth = 1.0
        ..style = style;
    }

    final double batteryRight = size.width - 4.0;

    final RRect batteryOutline = RRect.fromLTRBR( 
        0.0, 0.0, batteryRight, size.height, Radius.circular(3.0));

    // Battery body
    canvas.drawRRect(
      batteryOutline,
      getPaint(),
    );

    // Battery nub
    canvas.drawRect(
      Rect.fromLTWH(batteryRight, (size.height / 2.0) - 5.0, 4.0, 10.0),
      getPaint(style: PaintingStyle.fill),
    );

    // Fill rect
    canvas.clipRect(Rect.fromLTWH(
        0.0, 0.0, batteryRight * _batteryLevel / 100.0, size.height));

    Color indicatorColor;
    if (_batteryLevel < 15) {
      indicatorColor = Colors.red[300];
    } else if (_batteryLevel < 30) {
      indicatorColor = Colors.orange[200];
    } else {
      indicatorColor = Colors.green[300];
    }

    canvas.drawRRect(
        RRect.fromLTRBR(0.5, 0.5, batteryRight - 0.5, size.height - 0.5,
            Radius.circular(3.0)),
        getPaint(style: PaintingStyle.fill, color: indicatorColor));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final _BatteryLevelPainter old = oldDelegate as _BatteryLevelPainter;
    return old._batteryLevel != _batteryLevel ||
        old._batteryState != _batteryState;
  }
}