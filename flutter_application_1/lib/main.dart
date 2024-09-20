import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/features/dashboard/ui/dashboard_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FaceRecognitionPage(),
    );
  }
}

class FaceRecognitionPage extends StatefulWidget {
  @override
  _FaceRecognitionPageState createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _result = "";

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5000/recognize'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final jsonResponse = json.decode(res.body);

      setState(() {
        _isLoading = false;
        _result = jsonResponse['message'];
      });

      if (jsonResponse['matched']) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      } else {
        _showErrorMessage();
      }
    } else {
      setState(() {
        _isLoading = false;
        _result = "Error occurred during recognition";
      });
    }
  }

  void _showErrorMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('Face does not match!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_image != null) Image.file(_image!),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Pick an image'),
                  ),
                  ElevatedButton(
                    onPressed: _uploadImage,
                    child: const Text('Upload and Recognize'),
                  ),
                  if (_result.isNotEmpty) Text(_result),
                ],
              ),
      ),
    );
  }
}
