import 'dart:async';
import 'dart:io';

import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// import 'package:dio/adapter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
// import 'package:http_parser/http_parser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String APP_ID = "YOUR_APP_ID";
  static const String ANDROID_KEY = "YOUR_ANDROID_KEY";
  static const String IOS_KEY = "YOUR_IOS_KEY";

  @override
  initState() {
    super.initState();
    Backendless.initApp(
        "AB15E5A4-ADCF-1F50-FF42-369C1066A600",
        "DF8D652C-1667-4DF3-95D8-A4615FC7541E",
        "AFEEDF1D-81A8-4737-988B-4469EA4A48EE");
  }

  final String api = "http://104.248.50.142/uploadProfilePicture";
  File _image;
  String _image_path;
  File _compressed;
  final picker = ImagePicker();

  Future getImage() async {
    PickedFile pickedFile =
        await picker.getImage(source: ImageSource.camera, maxWidth: 1200);
    setState(() {
      _image = File(pickedFile.path);
      _image_path = pickedFile.path;
    });
  }

  Future<File> compress() async {
    if (_compressed != null) return _compressed;
    String newPath = "${_image.parent.path}/${DateTime.now().toString()}.jpg";
    print(newPath);
    File imageCompressed = await FlutterImageCompress.compressAndGetFile(
      _image.absolute.path,
      newPath,
      quality: 60,
    );
    // setState(() {
    _compressed = imageCompressed;
    // });

    return imageCompressed;
  }

  double porcen(count, total) {
    return (count * 100) / total;
  }

  Future uploadToVps() async {
    Dio dio = new Dio();
    File imageCompressed = await compress();
    // print(imageCompressed);
    int size = await _image.length();
    print((size / 1024) / 1024);
    FormData formData = FormData.fromMap({
      // "name": "mypic",
      // "age": 25,
      // "mypic": await MultipartFile.fromFile(_image_path, filename: "upload.jpg")
      "mypic": await MultipartFile.fromFile(imageCompressed.absolute.path,
          filename: "upload.jpg")
    });

    Response response = await dio.post(
      api,
      data: formData,
      onSendProgress: (count, total) => {print(porcen(count, total))},
    );
    print(response);
  }

  Future backendless() async {
    File file = await compress();
    // File file = File(imageCompressed);
    Backendless.files
        .upload(
      file,
      "/flutter_files",
      onProgressUpdate: (progress) => {print("progress $progress")},
    )
        .then((response) {
      print("File has been uploaded. File URL is - " + response);
      file.delete();
    });
  }

  Future createAccount() async {
    BackendlessUser newUser = BackendlessUser();
    newUser.email = "sericmorales@gmail.com";
    newUser.password = "appengine";
    try {
      await Backendless.userService.register(newUser);
    } on PlatformException catch (err) {
      //error code 3033 == user account exists
      print(err);
    }
    // .then((res) => {print(res)})
    // .catchError((err) => {print(err)});
  }

  Future checkRegistrationStatus() async {
    try {
      DeviceRegistration deviceRegistration =
          await Backendless.messaging.getDeviceRegistration();
      print("Result: $deviceRegistration");
    } on PlatformException catch (err) {
      print(err);
    }
  }

  Future registerDevice() async {
    List<String> channels = ["default"];
    DateTime expiration = DateTime.parse("2020-06-24 21:05");
    print(expiration);
    try {
      DeviceRegistrationResult op =
          await Backendless.messaging.registerDevice(channels, expiration);
      print(op);
    } on PlatformException catch (err) {
      print(err);
    }
    // Future<DeviceRegistrationResult> Backendless.messaging.registerDevice([List<String> channels, DateTime expiration]);
  }

  Future sendEMail() async {
    // BASIC EMAIL API
    String subject = "Cool title of an email marketing campaign";
    String message = """Hello!\n\n

            This is an example of an email message delivered with Backendless.\n
            Just something basic to give you an idea of how the API works,\n
            however, there is so much more you can do with the platform\n\n

            Enjoy!\n
            Your friends @visnex.co""";
    List<String> recipients = ["sericmorales@gmail.com"];
    try {
      await Backendless.messaging
          .sendHTMLEmail(subject, message, recipients)
          .then((res) => print(res));
    } on PlatformException catch (err) {
      print(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
            ),
            _image == null ? Text('No image selected.') : Image.file(_image),
            Text("${_image?.absolute?.path}"),
            FlatButton(
              child: Text("subir a backendless"),
              onPressed: backendless,
            ),
            FlatButton(
              child: Text("subir al vps y storyblok"),
              onPressed: uploadToVps,
            ),
            FlatButton(
              child: Text("register"),
              onPressed: createAccount,
            ),
            FlatButton(
              child: Text("send email"),
              onPressed: sendEMail,
            ),
            FlatButton(
              child: Text("registration status"),
              onPressed: checkRegistrationStatus,
            ),
            FlatButton(
              child: Text("Register Device"),
              onPressed: registerDevice,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
