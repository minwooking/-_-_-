import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:timer_builder/timer_builder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

enum UploadType {
  /// Uploads a randomly generated string (as a file) to Storage.
  string,

  /// Uploads a file from the device.
  file,

  /// Clears any tasks from the list.
  clear,
}

class CameraExample extends StatefulWidget {
  const CameraExample({Key? key}) : super(key: key);

  @override
  _CameraExampleState createState() => _CameraExampleState();
}

class _CameraExampleState extends State<CameraExample> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  // final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  Uint8List? _imageFile;
  Firebase? firebase_Storage;
  ScreenshotController screenshotController = ScreenshotController();
  Position? _currentPositions;
  var leftDiceNumber = 1;
  var _toDay = DateTime.now();
  String? _currentAddress;
  double? _currentPositions_lat;
  double? _currentPositions_lng;
  String? aaddres;

  getPlaceAddress(_currentPositions_lat, _currentPositions_lng) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${_currentPositions_lat},${_currentPositions_lng}&key=AIzaSyDXTmNX0t5ePIOE5ByPMr4p6Rz6raAt3IA';
    final response = await http.get(Uri.parse(url));
    // return
    String addres = jsonDecode(response.body)["results"][0]
        ['address_components'][0]['long_name'];
    setState(() {
      aaddres = addres;
    });
  }

  var _image;
  // double? longitude = 126.5510603;
  // double? latitude = 33.247167;
  final picker = ImagePicker();
  List? _outputs;
  File? basename;
  get child => null;

  // 앱이 실행될 때 loadModel 호출

// 파이어 베이스 업로드
  // Future _uploadFile(BuildContext context) async {
  //   try {
  //     // 스토리지에 업로드할 파일 경로
  //     final firebaseStorageRef =
  //         FirebaseFirestore.instance.collection('image').doc();
  //     // 파일 업로
  //     // 완료까지 기다림
  //     // 업로드 완료 후 url
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  //
  // final picker1 = ImagePicker();

  // Future pickImage() async {
  //   final pickedFile = await picker1.getImage(source: ImageSource.camera);

  //   setState(() {
  //     _imageFile = File(pickedFile!.path) as Uint8List?;
  //   });
  // }

  // 완료 후 앞 화면으로 이동
//

  // Tensor flow lite
  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  // 모델과 label.txt를 가져온다.
  loadModel() async {
    await Tflite.loadModel(
      model: "assets/imagemodel.tflite",
      labels: "assets/label.txt",
    ).then((value) {
      setState(() {
        //_loading = false;
      });
    });
  }
  // Tensor flow lite

  Future getImage(ImageSource imageSource) async {
    final image = await picker.pickImage(source: imageSource);

    setState(() {
      _image = File(image!.path);
      // 가져온 이미지를 _image에 저장
    });
    await classifyImage(File(image!.path)); // 가져온 이미지를 분류 하기 위해 await을 사용
  }

  // 이미지 분류
  Future classifyImage(File image) async {
    print("asdasddas$image");
    var output = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 2, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
        );
    setState(() {
      _outputs = output;
      leftDiceNumber = Random().nextInt(15) + 1;
    });
  }

  // 이미지를 보여주는 위젯
  Widget showImage() {
    return Container(
        color: const Color(0xffd0cece),
        margin: EdgeInsets.only(left: 0, right: 0),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width,
        child: Center(
            child: _image == null
                ? Text('식물을 넣어주세요.')
                : Image.file(File(_image!.path))));
  }

  // _getCurrentLocation() {
  //   Geolocator.getCurrentPosition(
  //           desiredAccuracy: LocationAccuracy.best,
  //           forceAndroidLocationManager: true)
  //       .then((Position position) {
  //     setState(() {
  //       _currentPositions = position;
  //     });
  //   }).catchError((e) {
  //     print(e);
  //   });
  // }
  bool? serviceEnabled;
  LocationPermission? permission;

  _getUserLocation() async {
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled == null) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    setState(() {
      _currentPositions_lat = position.latitude;
      _currentPositions_lng = position.longitude;
    });
  }

  recycleDialog() {
    _outputs != null
        ? showDialog(
            context: context,
            barrierDismissible:
                false, // barrierDismissible - Dialog를 제외한 다른 화면 터치 x
            builder: (BuildContext context) {
              return AlertDialog(
                // RoundedRectangleBorder - Dialog 화면 모서리 둥글게 조절
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '초록이:  ' +
                          _outputs![0]['label'].toString().toUpperCase() +
                          '이네요',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                        background: Paint()..color = Colors.white,
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  Center(
                    child: new FlatButton(
                      child: new Text("닫기"),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  )
                ],
              );
            })
        : showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "데이터가 없거나 잘못된 이미지 입니다.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  Center(
                    child: new FlatButton(
                      child: new Text("Ok"),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  )
                ],
              );
            });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 세로 고정
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    return Scaffold(
        backgroundColor: const Color(0xfff4f3f9),
        appBar: AppBar(
          title: Text('식의약용 자생식물 분류기'),
          centerTitle: true,
        ),
        body: Screenshot(
          controller: screenshotController,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text(
              //   '자생식물분류기',
              //   style: TextStyle(fontSize: 25, color: const Color(0xff1ea271)),
              // ),
              // SizedBox(
              //   height: 10.0,
              // ),
              Text(
                _outputs != null
                    ? '이 식물은 ' +
                        _outputs![0]['label'].toString().toUpperCase() +
                        ' 입니다'
                    : '아직 결과가 나오지 않았습니다.',
                style: TextStyle(fontSize: 25, color: const Color(0xff1ea271)),
              ),
              SizedBox(height: 15.0),
              showImage(),
              SizedBox(height: 15.0),
              Text(_outputs != null
                  ? leftDiceNumber == 0
                      ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 INFJ입니다.'
                      : leftDiceNumber == 1
                          ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 INFP입니다.'
                          : leftDiceNumber == 2
                              ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ENTJ입니다.'
                              : leftDiceNumber == 3
                                  ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ENTP입니다.'
                                  : leftDiceNumber == 4
                                      ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 INFJ입니다.'
                                      : leftDiceNumber == 5
                                          ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ENFJ입니다.'
                                          : leftDiceNumber == 6
                                              ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ENFP입니다.'
                                              : leftDiceNumber == 7
                                                  ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ISTJ입니다.'
                                                  : leftDiceNumber == 8
                                                      ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ISFJ입니다.'
                                                      : leftDiceNumber == 9
                                                          ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ESTJ입니다.'
                                                          : leftDiceNumber == 10
                                                              ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ESFJ입니다.'
                                                              : leftDiceNumber ==
                                                                      11
                                                                  ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ISTP입니다.'
                                                                  : leftDiceNumber ==
                                                                          12
                                                                      ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ISFP입니다.'
                                                                      : leftDiceNumber ==
                                                                              13
                                                                          ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ESTP입니다.'
                                                                          : leftDiceNumber == 14
                                                                              ? '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ESFP입니다.'
                                                                              : '${_outputs![0]['label'].toString().toUpperCase()}를 선택한 당신의 MBTI는 ESFP입니다.'
                  : '이식물을 선택한 당신의 MBTI는?'),
              SizedBox(height: 15.0),

              Text(_outputs != null
                  ? _outputs![0]['label'].toString().toUpperCase() == "구실잣밤나무"
                      ? '효능:항산화,항염증,항균,개화시기:6월,식용부위: 열매'
                      : _outputs![0]['label'].toString().toUpperCase() ==
                              "까마귀쪽나무"
                          ? '효능:항영증,관점열 개선\n식용부위:열매\n서식장소:바닷가'
                          : _outputs![0]['label'].toString().toUpperCase() ==
                                  "꽝꽝나무"
                              ? '효능:항산화,항염증 개화시기:7~8월'
                              : _outputs![0]['label'].toString().toUpperCase() ==
                                      "돈나무"
                                  ? '효능:항균,항염증\n개화시기:5~6월\n식용부위:알려지지않음'
                                  : _outputs![0]['label'].toString().toUpperCase() ==
                                          "메밀"
                                      ? '효능:항산화,항비만,항암\n개화시기:7~10월\n식용부위:잎,열매,씨앗'
                                      : _outputs![0]['label']
                                                  .toString()
                                                  .toUpperCase() ==
                                              "백량금"
                                          ? '효능:항산화,항염증 개화시기:10월'
                                          : leftDiceNumber == "순비기나무"
                                              ? '효능:주름개선,미백 개화시기:7월~9월'
                                              : _outputs![0]['label']
                                                          .toString()
                                                          .toUpperCase() ==
                                                      "좁은잎천선과"
                                                  ? '효능:항염증,관절염 개선\n:결실시기:9월~10월\n 식용부위: 잎,열매'
                                                  : _outputs![0]['label']
                                                              .toString()
                                                              .toUpperCase() ==
                                                          "참가시나무"
                                                      ? '효능:항염증,개화시기:5월,식용부위: 열매'
                                                      : _outputs![0]['label']
                                                                  .toString()
                                                                  .toUpperCase() ==
                                                              "참꽃나무"
                                                          ? '효능:항염증,항균 개화시기:5월'
                                                          : _outputs![0]['label']
                                                                      .toString()
                                                                      .toUpperCase() ==
                                                                  "참식나무"
                                                              ? '효능: 항균,항염증,식용부위:알려지지않음\n 결실시기9월~10월'
                                                              : _outputs![0]['label']
                                                                          .toString()
                                                                          .toUpperCase() ==
                                                                      "큰조롱"
                                                                  ? '효능:미백,혈관 건강개선,개화시기:7~8월,식용부위:뿌리'
                                                                  : _outputs![0]['label'].toString().toUpperCase() == "한라꽃향유"
                                                                      ? '효능:항염증,개화시기:9~10월'
                                                                      : _outputs![0]['label'].toString().toUpperCase() == "해국"
                                                                          ? '효능:항염증,항산화,개화시기:7월~11월'
                                                                          : _outputs![0]['label'].toString().toUpperCase() == "황근"
                                                                              ? '효능:항산화,주름개선 개화시기:7월~8월, 식용부위: - '
                                                                              : '여기에 식물효능이 나옵니다'
                  : '여기에 식물이 나옵니다.'),
              SizedBox(
                height: 15.0,
              ),
              Text(_currentPositions_lat != null
                  ? '제주도 ${aaddres} 입니다'
                  : '현재위치를 실행하지 않았습니다'),
              SizedBox(
                height: 12.0,
              ),
              Text('${_toDay.month}월입니다'),
              SizedBox(
                height: 13.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // 카메라 촬영 버튼
                  FloatingActionButton(
                    child: Icon(Icons.add_a_photo),
                    tooltip: 'pick Iamge',
                    onPressed: () async {
                      await getImage(ImageSource.camera);
                      recycleDialog();
                    },
                  ),

                  // 갤러리에서 이미지를 가져오는 버튼
                  FloatingActionButton(
                    child: Icon(Icons.wallpaper),
                    tooltip: 'pick Iamge',
                    onPressed: () async {
                      await getImage(ImageSource.gallery);
                      recycleDialog();
                    },
                  ),

                  FloatingActionButton(
                      child: Text(
                        'NFT발급',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('my_plant')
                            .add({
                          '식물이름':
                              _outputs![0]['label'].toString().toUpperCase(),
                          '위치':
                              "현재위치는 위도: ${_currentPositions_lat}, 경도: ${_currentPositions_lng} 주소 :${aaddres} 입니다",
                          '시간': '${_toDay.month}월',
                        });
                      }),
                  FloatingActionButton(
                      child: Text("현재위치",
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                      onPressed: () async {
                        await _getUserLocation();
                        await getPlaceAddress(
                            _currentPositions_lat, _currentPositions_lng);
                      }),
                ],
              )
            ],
          ),
        ));
  }

  // 앱이 종료될 때
  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
