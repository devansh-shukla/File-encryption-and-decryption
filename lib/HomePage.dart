import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isGranted = true;
  String filename = "demo.zip";
  String _videoURL =
      "https://assets.mixkit.co/videos/preview/mixkit-clouds-and-blue-sky-2408-large.mp4";
  String _imageURL =
      "https://images.unsplash.com/photo-1607753724987-7277196eac5d?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&dl=jeremy-bishop-FlR9yw3QEgw-unsplash.jpg&w=1920";

  Future<Directory> get getAppDir async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir;
  }

  Future<Directory> get getExternalVisibleDir async {
    if (await Directory('/storage/emulated/0/MyEncFolder').exists()) {
      final externalDir = Directory('/storage/emulated/0/MyEncFolder');
      return externalDir;
    } else {
      await Directory('/storage/emulated/0/MyEncFolder')
          .create(recursive: true);
      final externalDir = Directory('/storage/emulated/0/MyEncFolder');
      return externalDir;
    }
  }

  requestStoragePermission() async {
    if (!await Permission.storage.isGranted) {
      PermissionStatus result = await Permission.storage.request();
      if (result.isGranted) {
        setState(() {
          _isGranted = true;
        });
      } else {
        setState(() {
          _isGranted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    requestStoragePermission();
    return Scaffold(
      appBar: AppBar(
        title: Text('Encryption & Decryption'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("VIDEO ENC-DEC", style: TextStyle(fontSize: 30,),),
            SizedBox(height: 30,),
            ButtonTheme(
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.white70,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.red),
                    )
                ),
                child: Text("Download & Encrypt Video", style: TextStyle(color: Colors.red),),
                onPressed: () async {
                  if (_isGranted) {
                    Directory d = await getExternalVisibleDir;
                    _downloadAndCreate(_videoURL, d, filename);
                  } else {
                    print("No permission granted.");
                    requestStoragePermission();
                  }
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ButtonTheme(
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.green)
                  )
                ),
                child: Text("Decrypt Video", style: TextStyle(color: Colors.green),),
                onPressed: () async {
                  if (_isGranted) {
                    Directory d = await getExternalVisibleDir;
                    _getNormalFile(d, filename);
                  } else {
                    print("No permission granted.");
                    requestStoragePermission();
                  }
                },
              ),
            ),
            SizedBox(height: 100,),
            Text("IMAGE ENC-DEC",style: TextStyle(fontSize: 30,),),
            SizedBox(height: 30,),
            ButtonTheme(
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: Colors.red),
                    )
                ),
                child: Text("Download & Encrypt Image", style: TextStyle(color: Colors.red),),
                onPressed: () async {
                  if (_isGranted) {
                    Directory d = await getExternalVisibleDir;
                    _downloadAndCreate(_imageURL, d, filename);
                  } else {
                    print("No permission granted.");
                    requestStoragePermission();
                  }
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ButtonTheme(
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.white70,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.green)
                    )
                ),
                child: Text("Decrypt Image", style: TextStyle(color: Colors.green),),
                onPressed: () async {
                  if (_isGranted) {
                    Directory d = await getExternalVisibleDir;
                    _getNormalImage(d, filename);
                  } else {
                    print("No permission granted.");
                    requestStoragePermission();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_downloadAndCreate(String url, Directory d, filename) async {
  if (await canLaunch(url)) {
    print("Data downloading....");
    var resp = await http.get(Uri.parse(url));

    var encResult = _encryptData(resp.bodyBytes);
    String p = await _writeData(encResult, d.path + '/$filename.aes');
    // String p = await _writeData(encResult, '/storage/emulated/0/MyEncFolder/demo.mp4.aes');
    print("file encrypted successfully: $p");
  } else {
    print("Can't launch URL.");
  }
}

_getNormalFile(Directory d, filename) async {
  Uint8List encData = await _readData(d.path + '/$filename.aes');
  // Uint8List encData = await _readData('/storage/emulated/0/MyEncFolder/demo.mp4.aes');
  var plainData = await _decryptData(encData);
  //String p = await _writeData(plainData, d.path + '/$filename');
  String p =
    await _writeData(plainData, '/storage/emulated/0/MyEncFolder/demo.mp4');
  // String p =
  //   await _writeData(plainData, '/storage/emulated/0/MyEncFolder/demo.jpg');
  print("file decrypted successfully: $p");
}

_getNormalImage(Directory d, filename) async {
  Uint8List encData = await _readData(d.path + '/$filename.aes');
  // Uint8List encData = await _readData('/storage/emulated/0/MyEncFolder/demo.mp4.aes');
  var plainData = await _decryptData(encData);
  //String p = await _writeData(plainData, d.path + '/$filename');
  // String p =
  //   await _writeData(plainData, '/storage/emulated/0/MyEncFolder/demo.mp4');
  String p =
  await _writeData(plainData, '/storage/emulated/0/MyEncFolder/demo.jpg');
  print("file decrypted successfully: $p");
}

_encryptData(plainString) {
  print("Encrypting File...");
  final encrypted =
  MyEncrypt.myEncrypter.encryptBytes(plainString, iv: MyEncrypt.myIv);
  return encrypted.bytes;
}

_decryptData(encData) {
  print("File decryption in progress...");
  enc.Encrypted en = new enc.Encrypted(encData);
  return MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIv);
}

Future<Uint8List> _readData(fileNameWithPath) async {
  print("Reading data...");
  File f = File(fileNameWithPath);
  return await f.readAsBytes();
}

Future<String> _writeData(dataToWrite, fileNameWithPath) async {
  print("Writting Data...");
  File f = File(fileNameWithPath);
  await f.writeAsBytes(dataToWrite);
  return f.absolute.toString();
}

class MyEncrypt {
  static final myKey = enc.Key.fromUtf8('DevanshEncryptDevanshEncrypt1234');
  static final myIv = enc.IV.fromUtf8("Devansh12Devansh");
  static final myEncrypter = enc.Encrypter(enc.AES(myKey));
}