import 'package:flutter/material.dart';
import 'package:flutter_project/classes/bluetooth_device.dart';
import 'package:flutter_project/models/bluetooth_model.dart';
import 'package:provider/provider.dart';

class DeviceListPage extends StatelessWidget {
  const DeviceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Fit'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            children: [
              Expanded(
                child: Consumer<BluetoothModel>(
                  builder: (_, bluetoothModel, __) => ListView.builder(
                    itemCount: bluetoothModel.devices.length,
                    itemBuilder: (context, index) => getListItem(
                        bluetoothModel.devices[index], context, bluetoothModel),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Provider.of<BluetoothModel>(context, listen: false)
                      .startScanning();
                },
                child: const Text('Start Scanning'),
              ),
              ElevatedButton(
                onPressed: () {
                  Provider.of<BluetoothModel>(context, listen: false)
                      .stopScanning();
                },
                child: const Text('Stop Scanning'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getListItem(
      BluetoothDevice device, BuildContext context, BluetoothModel model) {
    final name = device.device.name;
    String status = device.status;
    return ListTile(
      title: Text(name),
      subtitle: Text(status),
      onTap: () async {
        if (status.toLowerCase().trim() != 'connected') {
          model.stopScanning();
          model.connectAndUpdate(device.device.id);
          // print("Discovering services start");
          // model.discoverServices(device.device.id);
          // print("Discovering services end");

        } else {
          print("DEVICE ID " + device.device.id);
          print("DEVICE NAME " + device.device.name);
          if (context.mounted) {
            print("MOUNTED");
            // Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(
            //       builder: ChangeNotifierProvider<HomeModel>(
            //         create: (context) => HomeModel(),
            //         child: const HomePage(),
            //       ),
            //     ));
          }
        }
      },
    );
  }
}
