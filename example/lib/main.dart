import 'package:flutter/material.dart';
import 'package:melodizr_editor/melodizr_editor.dart';

void main() {
  runApp(const MyApp()); //MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
            controller: MelodizrController(widget: SizedBox()),
          )),
    );
  }
}
