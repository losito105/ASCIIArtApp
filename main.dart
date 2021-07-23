import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:enough_ascii_art/enough_ascii_art.dart' as art;
import 'package:image/image.dart' as img;


Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take A Picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(50, 100, 50, 1),
        foregroundColor: Color.fromRGBO(255, 255, 255, 1),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final XFile xf = await _controller.takePicture();

            /* conversion of image to ASCII art */
            final Uint8List bytes = await File(xf.path).readAsBytes();
            final img.Image image = img.decodeImage(bytes)!;
            String asciiImage = art.convertImage(image, invert: true);

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // pass asciiImage to DisplayScreen Widget
                  ascii: asciiImage,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// A widget that displays the ASCII art representation of the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String ascii;

  const DisplayPictureScreen({Key? key, required this.ascii}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ASCII Art')),
      body: new Container(
          alignment: Alignment.center,
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              new Container(
                color: Colors.black,
                child: Text(
                  ascii, // print ASCII art to screen within Container
                  textScaleFactor: .6, // size formatting to fit image to screen (>= .7 distorts, < .6 too small)
                  style: GoogleFonts.robotoMono(), // use monospaced font so image is displayed properly
                  ),
              ),
              SizedBox(height: 25), // put space in between image and screenshot message
              new Container(
                child: Text(
                  "Take A Screenshot To Save Your Art!",
                  style: GoogleFonts.robotoMono(),
                  textScaleFactor: 1.2,
                ),
              ),
            ]
          ),
      ),
    );
  }
}