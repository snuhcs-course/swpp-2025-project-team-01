import 'package:flutter/material.dart';
import 'core/theme/colorScheme.dart';

void main() {
  runApp(const ReView());
}

class ReView extends StatelessWidget {
  const ReView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        extensions: [
          AppHighlights.fromScheme(lightScheme),
        ],
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: const Center(
        child: Text('Hello, world!'),
      ),
    );
  }
}