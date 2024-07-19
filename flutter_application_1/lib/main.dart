import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "package:flutter/services.dart" as s;
import "package:yaml/yaml.dart";


Map map = {
  'model': 'gpt-3.5-turbo-1106',
};

void main() {
  runApp(const MyApp());
  //getReplyMessage();
}

Future<String> getReplyMessage() async{
  final data = await s.rootBundle.loadString('assets/info.yaml');
  final mapData = loadYaml(data);
  String bearedToken = mapData['token'];

  Map<String, String> headers = {
    'Authorization':'Bearer $bearedToken',
    'Content-Type':'application/json'
  };

  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: headers,
    body: jsonEncode(map)
  );
  Map res = jsonDecode(response.body) as Map<String, dynamic>;
  print(res["choices"][0]["message"]["content"]);
  return res["choices"][0]["message"]["content"];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter AI Blockchain'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _text = "";
  final myController = TextEditingController();
  final scrollController = ScrollController();
  List<Widget> _widgets = [];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future _setText(String text) async{
    setState(() {
      _text = text;
    });
    print(_text);
    Map current = {
      "role":"user",
      "content":_text,
    };
    map["messages"] = [current];
    // _widgets.add(Text(
    //     _text,
    //     style: const TextStyle(
    //       color: Colors.green,
    //     ),
    //   )
    // );
    await getReplyMessage().then((String result){
      setState(() {
        _widgets.add(Text(
        _text,
        style: const TextStyle(
          color: Colors.green,
            ),
          )
        );
        _widgets.add(Text(
            result,
            style: const TextStyle(
              color: Colors.red,
            ),
          )
        );

      });
      
    });
    myController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: TextField(
            controller: myController,
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter your sentence',
                suffixIcon: IconButton(onPressed: () async { await _setText(myController.text); setState(() {});}, icon: const Icon(Icons.co2)),
              ),
            ),
          ),
          Expanded(
              child: ListView.builder(
              itemCount: _widgets.length,
              itemBuilder: (context, index) => _widgets[index],
            ),
          ),
          
        ],
      ),
    );
  }
}
