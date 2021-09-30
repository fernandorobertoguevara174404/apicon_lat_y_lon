import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reporte meteorológico',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Reporte meteorológico'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List _weatherList = [];
  double lat1 = 0;
  double lon1 = 0;
  void _callAPI(double lat, double lon) async {
    dynamic data = await http.read(Uri.parse(
        'https://www.7timer.info/bin/civillight.php?lon=${lon}&lat=${lat}&ac=0&unit=metric&output=json&tzshift=0'));
    dynamic dic = jsonDecode(data);
    setState(() {
      _weatherList = dic["dataseries"];
      print(lat);
      lat1 = lat;
      print(lon);
      lon1 = lon;
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _determinePosition().then((position) => {
      _callAPI(position.latitude, position.longitude)
    }).catchError((e)=>print(e));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ((){
        if(_weatherList.length == 0){
          return Text("Loading...");
        } else{
          return Column(
            children: <Widget>[
              Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
              Text("Latitud: $lat1",style: TextStyle(fontSize: 18.0)),
              Padding(padding: EdgeInsets.symmetric(vertical: 3.0)),
              Text("Longitud: $lon1",style: TextStyle(fontSize: 18.0)),
              Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
              Row(
                  children: [
                    SizedBox(width: 25),
                    Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold)),

                    SizedBox(width: 65),
                    Text("Temperaturas", style: TextStyle(fontWeight: FontWeight.bold)),

                    SizedBox(width: 50),
                    Text("Clima", style: TextStyle(fontWeight: FontWeight.bold))]
              ),
              Expanded(
                  child: ListView.builder(
                      itemCount: _weatherList.length,
                      itemBuilder: (context, index) {
                        dynamic weather = _weatherList[index];
                        dynamic weatherIcon = ((){
                          switch(weather['weather']){
                            case 'cloudy':
                            case 'pcloudy':
                            case 'mcloudy':
                              return Icons.wb_cloudy_outlined;
                            case 'rain':
                            case 'lightrain':
                            case 'ishower':
                              return Icons.water;
                            case 'clear':
                            case 'ts':
                              return Icons.wb_sunny_outlined;
                            default:
                              return Icons.cancel;
                          }
                        })();
                        String weathertype = weather['weather'];
                        DateTime date = DateTime.parse(weather['date'].toString());
                        int max = weather['temp2m']['max'];
                        int min = weather['temp2m']['min'];
                        return ListTile(
                            title: Row(
                              children: <Widget>[
                                Row(
                                  children: [
                                    Text("${date.day}/${date.month}/${date.year}",style: TextStyle(fontSize: 14.0),),
                                    SizedBox(width: 15),
                                  ],
                                )
                                ,
                                Row(
                                  children: [
                                    Text("Max:$max°C",style: TextStyle(fontSize: 14.0)),
                                    SizedBox(width: 15),
                                    Text("Min:$min°C",style: TextStyle(fontSize: 14.0))
                                  ],
                                ),
                                Row(
                                  children: [
                                    SizedBox(width: 15),
                                    Icon(weatherIcon),
                                    SizedBox(width: 15),
                                    Text(weathertype, style: TextStyle(fontSize: 14.0),),
                                  ],
                                )
                              ],
                            ));
                      }))
            ],
          )
            ;

        }
      }()),
    );
  }


}