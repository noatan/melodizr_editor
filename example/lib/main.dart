import 'package:flutter/material.dart';
import 'package:melodizr_editor/melodizr_editor.dart';

void main() {
  runApp(const MyApp()); //MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  Widget _buildAudio(
    String text,
    double opacity,
    double height, {
    double? width,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Material(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(5),
            ),
            color: Colors.red.withOpacity(opacity),
          ),
          child: Center(child: Row()),
        ),
      ),
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          appBar: AppBar(),
          body: MelodizrTextEditor(
            null,
            null,
            path: 'sdfsdfsdf',
            toolbar: Container(
              color: Colors.red,
              height: 50,
            ),
            regexMap: {
              RegExp(r'\字(.*?)\文'):
                  //RegExp(r'字[a-zA-Z0-9]+\b'):
                  const WidgetSpan(child: SizedBox()),
              RegExp(r"\B#[a-zA-Z0-9]+\b"): const TextSpan(
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    decorationThickness: 0.001,
                    height: 1.2),
              ),
              RegExp(r"\B@[a-zA-Z0-9]+\b"): const TextSpan(
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    decorationThickness: 0.001,
                    height: 1.2),
              )
            },
            placeholder: _buildAudio('sds', 0.3, 40),
            feedback: _buildAudio(
              'sd',
              0.2,
              35,
              width: 200,
            ),
          ),
        ));
  }
}
