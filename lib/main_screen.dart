import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';

class DataPacket {
  String action;
  String motor;
  bool rLimit;
  bool fLimit;
  String mode;

  DataPacket(this.action, this.motor, this.rLimit, this.fLimit, this.mode);

  // Constructor to create a DataPacket from a list of bytes
  factory DataPacket.fromBytes(List<int> bytes) {
    // Decode the bytes into individual properties (adjust based on your encoding logic)
    String action = utf8.decode(bytes.sublist(0, 10));
    String motor = utf8.decode(bytes.sublist(10, 20));
    bool rLimit = bytes[20] == 1;
    bool fLimit = bytes[21] == 1;
    String mode = utf8.decode(bytes.sublist(22, 32));
    return DataPacket(action, motor, rLimit, fLimit, mode);
  }

  // Convert DataPacket properties into a list of bytes
  List<int> toBytes() {
    // Encode properties into bytes (adjust based on your encoding logic)
    List<int> bytes = utf8.encode(action) + utf8.encode(motor) + [rLimit ? 1 : 0, fLimit ? 1 : 0] + utf8.encode(mode);
    return bytes;
  }
}

class MotorController extends StatefulWidget {
  const MotorController({super.key});

  @override
  State<MotorController> createState() => _MotorControllerState();
}

class _MotorControllerState extends State<MotorController> {
  //Bluetooth config
  FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice device;
  late BluetoothCharacteristic characteristic;
  final String DEVICE_NAME = "ESP32_Device";
  final String SERVICE_UUID = '';
  final String CHARACTERISTIC_UUID = '';

  bool isManual = false; // mode
  Color circleColor = Colors.yellow;
  Icon playIcon = const Icon(Icons.play_arrow_rounded, size: 30,);
  Icon pauseIcon = const Icon(Icons.pause, size: 25);
  Icon dynamicIcon = const Icon(Icons.play_arrow_rounded, size: 30,);
  String status = 'Stopped'; // motor
  String action = 'None';
  bool fLimit = true;
  bool rLimit = false;


  @override
  void initState() {
    super.initState();
    flutterBlue.startScan().onError((error, stackTrace) {
    ScaffoldMessenger.of(context).showSnackBar( SnackBar(
    content: Text(error.toString()),
    duration: const Duration(seconds: 1),
    ));
    });
    flutterBlue.scanResults.listen((results) {
      print(results);
      // Find the ESP32_Device
      for (var result in results) {
        if (result.device.name == DEVICE_NAME) {
          device = result.device;
          connectToDevice();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double x = MediaQuery.of(context).size.width;
    double y = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Motor Controller', style: GoogleFonts.poppins(textStyle: TextStyle(fontSize: x*0.055), color: Colors.white),)),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: y*0.02, horizontal: x*0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              // TODO: Indicator text box
              width: x,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.black, // Customize border color
                  width: 1.5, // Customize border width
                ),
              ),
              child: Center(child: Text('Status: $status\nAction: $action')),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: y*0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Auto'),
                      Switch(
                        value: isManual,
                        onChanged: (value) {
                          setState(() {
                            isManual = value;
                          });
                          if(isManual){
                            // TODO: Manual mode
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Manual Mode'),
                              duration: Duration(seconds: 1),
                            ));
                          } else {
                            // TODO: Auto mode
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Auto Mode'),
                              duration: Duration(seconds: 1),
                            ));
                          }
                        },
                      ),
                      const Text('Manual'),
                    ],
                  ),

                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Container(
                      height: y*0.4,
                    ),
                    GestureDetector(
                      onLongPressStart: rLimit ? null : (details) {
                        if(isManual && status == 'Started'){
                          setState(() {
                            action = 'Reverse';
                            fLimit = false;
                          });
                        }
                      },
                      onLongPressEnd: rLimit ? null : (details) {
                        if(isManual && status == 'Started'){
                          setState(() {
                            action = 'None';
                          });
                        }
                      },
                      child: FloatingActionButton(
                        backgroundColor: rLimit ? Colors.grey[400]: Colors.blueGrey[300],
                        disabledElevation: 0,
                        onPressed: rLimit ? null : () {
                          if(!isManual && status == 'Started'){
                            setState(() {
                              action = 'Reverse';
                              fLimit = false;
                            });
                          }
                        },
                        child: Icon(Icons.arrow_upward_rounded, color: rLimit ? Colors.grey[700]:Colors.black,),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    FloatingActionButton(
                        backgroundColor: Colors.blueGrey[300],
                        onPressed: () {
                          setState(() {
                            if(status == 'Started'){
                              dynamicIcon = playIcon;
                              status = 'Stopped';
                              action = 'None';
                              circleColor = Colors.yellow;
                            } else if(status == 'Stopped'){
                              dynamicIcon = pauseIcon;
                              status = 'Started';
                              circleColor = Colors.green;
                            }
                          });
                        },
                        child: dynamicIcon
                    ),
                    const SizedBox(height: 20,),
                    GestureDetector(
                      onLongPressStart: fLimit ? null : (details) {
                        if(isManual && status == 'Started'){
                          setState(() {
                            action = 'Forward';
                            rLimit = false;
                          });
                        }
                      },
                      onLongPressEnd: fLimit ? null : (details) {
                        if(isManual && status == 'Started'){
                          setState(() {
                            action = 'None';
                          });
                        }
                      },
                      child: FloatingActionButton(
                        backgroundColor: fLimit ? Colors.grey[400]: Colors.blueGrey[300],
                        disabledElevation: 0,
                        onPressed: fLimit ? null : () {
                          if(!isManual && status == 'Started'){
                            setState(() {
                              action = 'Forward';
                              rLimit = false;
                            });
                          }
                        },
                        child: Icon(Icons.arrow_downward_rounded, color: fLimit ? Colors.grey[700]:Colors.black,),
                      ),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void connectToDevice() async {
    try {
      await device.connect();
      discoverServices();
      } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
        content: Text(error.toString()),
        duration: const Duration(seconds: 1),
      ));
    }
  }
  void discoverServices() async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            this.characteristic = characteristic;
            // Subscribe to notifications
            characteristic.setNotifyValue(true);
            // Handle received data
            characteristic.value.listen((value) {
              DataPacket receivedData = DataPacket.fromBytes(value);
              setState(() {
                action = receivedData.action;
                status = receivedData.motor;
                if (receivedData.mode == 'manual'){
                  isManual = true;
                } else if(receivedData.mode == 'auto') {
                  isManual = false;
                }
                rLimit = receivedData.rLimit;
                fLimit = receivedData.fLimit;
              });

            });
          }
        }
      }
    }
  }

  void sendData(DataPacket data) {
    characteristic.write(data.toBytes(), withoutResponse: true).whenComplete((){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Data Sent!"),
        duration: Duration(seconds: 1),
      ));
    }).onError((error, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
        duration: const Duration(seconds: 1),
      ));
    });
  }


}
