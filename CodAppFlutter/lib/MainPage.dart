import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import './SelectBondedDevicePage.dart';
import './ChatPage.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;


  @override
  void initState() {
    super.initState();
    
    // Obstendo estado atual do bluetooth (ligado/desligado)
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() { _bluetoothState = state; });
    });

    // Espera por alterações no estado do bluetooth (ligado/desligado)
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // O modo detectável é desativado quando o Bluetooth é desativado
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth"),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            SwitchListTile(
              title: const Text('Ligar/Desligar Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async { // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }
                future().then((_) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              title: const Text('Bluetooth status'),
              subtitle: Text(_bluetoothState.toString()),
              trailing: RaisedButton(
                child: const Text('Configurações BT'),
                onPressed: () {
                  FlutterBluetoothSerial.instance.openSettings();
                },
              ),
            ),

            Divider(),
            ListTile(
              title: RaisedButton(
                child: Text('Conectar a dispositivos pareados'),
                onPressed: () async {
                  if(_bluetoothState.isEnabled){
                    final BluetoothDevice selectedDevice = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) { return SelectBondedDevicePage(checkAvailability: false); })
                    );

                    if (selectedDevice != null) {
                      print('Connect -> selected ' + selectedDevice.address);
                      _startChat(context, selectedDevice);
                    }
                    else {
                      print('Connect -> no device selected');
                    }
                  }else{
                    Alert(context: context, title: "Bluetooth desligado", desc: "Ligue o bluetooth para "
                        "\nmostrar a lista de dispositivos pareados.").show();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) { return ChatPage(server: server); }));
  }


}
