import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Kaf's File Manager", // replaced by localized title in F6
      home: Scaffold(body: Center(child: Text('KFM'))),
    );
  }
}
