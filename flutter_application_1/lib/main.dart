import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "package:flutter/services.dart" as s;
import "package:yaml/yaml.dart";


Map map = {
  'model': 'gpt-3.5-turbo-1106',
};

Map walletMap = {
    "description":"",
    "name":"",
    "metadata":{},
    "kmsId":""
};

void main() {
  runApp(const MyApp());
  //getReplyMessage();
  //createWallet();
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

Future<String> createWallet(String description, String name, Map metadata, String kmsId) async{
  final data = await s.rootBundle.loadString('assets/info.yaml');
  final mapData = loadYaml(data);
  String apiKey = mapData['wallet'];
  Map<String, String> headers = {
    'x-api-key':apiKey,
  };
  walletMap["description"] = "\"$description\"";
  walletMap["name"] = "\"$name\"";
  walletMap["metadata"] = metadata;
  walletMap["kmsId"] = "\"$kmsId\"";
  print(walletMap);
  final response = await http.post(
    Uri.parse('https://api.starton.com/v3/kms/wallet'),
    headers: headers,
    body: jsonEncode(walletMap)
  );
  Map res = jsonDecode(response.body) as Map<String, dynamic>;
  print(res["message"]);
  if(res['statusCode'] == 400){
    String reply = "";
    for(int i = 0; i < res["message"].length; i++){
      reply += res["message"][i];
      if(i < res["message"].length - 1){
        reply += ", ";
      }
    }
    return reply;
  }
  return res["message"];
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
  bool AIorBlock = true;
  String _text = "";
  final myController = TextEditingController();
  final descriptionController = TextEditingController();
  final walletNameController = TextEditingController();
  final kmsIdController = TextEditingController();
  final metaDataController = TextEditingController();
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
    await getReplyMessage().then((String result){
      setState(() {
        _widgets.add(
          Align(alignment: Alignment.centerRight,child: Text(
              _text,
              style: const TextStyle(
                 color: Colors.green,
                 fontSize: 16,
             ),
           ),
          ) 
        );
        _widgets.add(Text(
            result,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          )
        );

      });
      
    });
    myController.text = "";
  }

  Future _createWallet() async{
    String description = descriptionController.text;
    String name = walletNameController.text;
    String kmsId = kmsIdController.text;
    Map metaData = metaDataController.text.length == 0 ? {} : jsonDecode(metaDataController.text);
    String message = await createWallet(description, name, metaData, kmsId);
    print(message);
    showDialog<String>(context: context, builder: (BuildContext context) => AlertDialog(
          title: const Text('Message'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: FloatingActionButton.large(
            onPressed: (){setState(() {
                AIorBlock = true;
              });
            },
            child: Text("AI"),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: FloatingActionButton.large(
            onPressed: (){
              setState(() {
                AIorBlock = false;
              });
            },
            child: Text("Create Wallet"),
            ),
          ),
        ],
      ),
      body: AIorBlock ? Column(
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
      ) : 
      Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10,5,0,0),child: Text("Wallet Name", style: TextStyle(fontSize: 16),),)
            ),
          ),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: TextField(
            controller: walletNameController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your wallet name'
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10,5,0,0),child: Text("Description", style: TextStyle(fontSize: 16),),)
            ),
          ),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your description'
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10,5,0,0),child: Text("kmsId", style: TextStyle(fontSize: 16),),)
            ),
          ),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: TextField(
            controller: kmsIdController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your kmsId'
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10,5,0,0),child: Text("metaData", style: TextStyle(fontSize: 16),),)
            ),
          ),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: TextField(
            controller: metaDataController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your metaData json format'
              ),
            ),
          ),
          Container(width: 200, height: 50,child: FloatingActionButton.large(onPressed: (){_createWallet();}, child: Text("Create Wallet"),),)
        ],
      ),
    );
  }
}
