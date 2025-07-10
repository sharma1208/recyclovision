import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:recyclovision/scan_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'models/scan_record.dart'; // your ScanRecord and ClassificationResult model files
import 'package:flutter_animate/flutter_animate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // make sure Flutter is ready
  await Hive.initFlutter(); // initialize Hive for Flutter
  Hive.registerAdapter(ScanRecordAdapter());
  Hive.registerAdapter(ClassificationResultAdapter());
  await Hive.openBox<ScanRecord>('scanRecords');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print("Building MyApp");
    return MaterialApp(
      title: 'RecycloVision',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: false,
      ),
      home: const MyHomePage(title: 'RecycloVision Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;

  Future getImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final imageTemporary = File(image.path);

    setState(() {
      this._image = imageTemporary;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScanPage(imagePath: image.path)),
    );
  }

  Widget _buildRocketLogo(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: screenHeight, end: -screenHeight * 0.16),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutExpo,
      builder: (_, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Transform.scale(
            scale: 1.0 - (value / screenHeight) * 0.3,
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🌈 Rainbow glow background
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.pinkAccent.withOpacity(0.3),
                  Colors.orangeAccent.withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: [0.3, 0.7, 1.0],
              ),
            ),
          ),
          // ♻️ Main logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.6),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.recycling, size: 48, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Building MyHomePage");

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 🔁 Animated floating icons
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 150, left: 70),
              child: Icon(Icons.eco, size: 36, color: Colors.greenAccent)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                    delay: 100.ms,
                  )
                  .moveY(begin: -8, end: 8, duration: 1800.ms),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 150, right: 70),
              child: Icon(Icons.public, size: 36, color: Colors.lightBlueAccent)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                    delay: 200.ms,
                  )
                  .moveY(begin: -8, end: 8, duration: 1800.ms),
            ),
          ),
          Align(
            alignment: FractionalOffset(0.0, 0.42),
            child: Padding(
              padding: const EdgeInsets.only(left: 70),
              child:
                  Icon(Icons.local_drink, size: 36, color: Colors.purpleAccent)
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                        delay: 300.ms,
                      )
                      .moveY(begin: -8, end: 8, duration: 1800.ms),
            ),
          ),
          Align(
            alignment: FractionalOffset(1.0, 0.42),
            child: Padding(
              padding: const EdgeInsets.only(right: 70),
              child: Icon(Icons.waves, size: 36, color: Colors.cyanAccent)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                    delay: 400.ms,
                  )
                  .moveY(begin: -8, end: 8, duration: 1800.ms),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 30),
              child:
                  Icon(
                        Icons.energy_savings_leaf,
                        size: 36,
                        color: Colors.tealAccent,
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                        delay: 500.ms,
                      )
                      .moveY(begin: -8, end: 8, duration: 1800.ms),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40, right: 30),
              child: Icon(Icons.recycling, size: 36, color: Colors.amberAccent)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                    delay: 600.ms,
                  )
                  .moveY(begin: -8, end: 8, duration: 1800.ms),
            ),
          ),

          // 🚀 Logo animation (from bottom of screen)
          _buildRocketLogo(context),

          // ✨ Main content (text, button, terms)
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 240), // Spacer below rocket

                    Text(
                          'Welcome to RecycloVision',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(delay: 1000.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.5),

                    const SizedBox(height: 12),

                    Text(
                          'Reduce waste. Know your impact.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[300],
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(delay: 1200.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.4),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: getImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Scan',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ).animate(delay: 1400.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text.rich(
                        TextSpan(
                          text: 'By using RecycloVision, you agree to the ',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          children: const [
                            TextSpan(
                              text: 'terms',
                              style: TextStyle(color: Colors.blue),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'privacy policy',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 1600.ms).fadeIn(duration: 300.ms),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
