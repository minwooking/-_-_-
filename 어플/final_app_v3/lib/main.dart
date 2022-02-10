import 'package:flutter/material.dart';
import 'camera_ex.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase login:list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '식의약용 자생식물 분류기 Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: CameraExample(),
    );
  }
}
