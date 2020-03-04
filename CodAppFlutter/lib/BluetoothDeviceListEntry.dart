import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothDeviceListEntry extends ListTile {
  BluetoothDeviceListEntry({
    @required BluetoothDevice device,
    int rssi,
    GestureTapCallback onTap,
    GestureLongPressCallback onLongPress,
    bool enabled = true
  }) : super(
    onTap: onTap,
    onLongPress: onLongPress,
    enabled: enabled,
    leading: Icon(Icons.devices), // @TODO . !BluetoothClass! class aware icon
    title: Text(device.name ?? "Unknown device"),
    subtitle: Text(device.address.toString()),
  );
}
