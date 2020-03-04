import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:holding_gesture/holding_gesture.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;
  
  const ChatPage({this.server});
  
  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  static final maxMessageLength = 4096 - 3;
  BluetoothConnection connection;
  String distancia="";

  List<_Message> messages = List<_Message>();


  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        print("hello");
        if (isDisconnecting) {
          print('Disconnecting locally!');
        }
        else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: (
          isConnecting ? Text('Conectando ' + widget.server.name + '...') :
          isConnected ? Text('Conectado à ' + widget.server.name) :
          Text('Desconectado')
        )
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            left: queryData.size.width/1.5,
            top: queryData.size.height/30,
            child: Text("Distância: $distancia"+"cm",style: TextStyle(fontSize: 20,color: Colors.blue,fontWeight: FontWeight.bold),),
          ),
          Positioned(
            left: queryData.size.width/200,
            child: HoldDetector(
              onHold:(){_sendMessage("C");},
              child: Image.asset(
                "images/cima.png",
                color: Colors.blue,
                width: 200.0,
                height: 150.0,
              ),
            ),
          ),
          Positioned(
            top: queryData.size.height/2.7,
            left: queryData.size.width/200,
            child: HoldDetector(
              onHold:(){_sendMessage("B");},
              child: Image.asset(
                "images/baixo.png",
                color: Colors.blue,
                width: 200.0,
                height: 150.0,
              ),
            ),
          ),
          Positioned(
            top: queryData.size.height/5,
            left: queryData.size.width/2,
            child: HoldDetector(
              onHold:(){_sendMessage("E");},
              child: Image.asset(
                "images/esquerda.png",
                color: Colors.blue,
                width: 200.0,
                height: 150.0,
              ),
            ),
          ),
          Positioned(
            top: queryData.size.height/5,
            left: queryData.size.width/1.4,
            child: HoldDetector(
              onHold:(){_sendMessage("D");},
              child: Image.asset(
                "images/direita.png",
                color: Colors.blue,
                width: 200.0,
                height: 150.0,
              ),
            ),
          ),
        ],
      )
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;
    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      }
      else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        }
        else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    if(dataString.length>1){
      for(int i=0;i<dataString.length;i++){
        if(dataString[i]=="F") {
          distancia = distancia.split("").reversed.join();

          setState(() {
            distancia = distancia;
          });

          print(distancia);

          Future.delayed(const Duration(milliseconds: 500), () {
            distancia="";
          });

        }
        else distancia+=dataString[i];
      }
    }else{
      if(dataString=="F"){
        distancia = distancia.split("").reversed.join();

        setState(() {
          distancia = distancia;
        });

        print(distancia);

        Future.delayed(const Duration(milliseconds: 500), () {
          distancia="";
        });

      }else {
        distancia+=dataString;
      }
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    print(text);
    textEditingController.clear();

    if (text.length > 0)  {
      try {
        connection.output.add(utf8.encode(text));
        await connection.output.allSent;

      }
      catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
