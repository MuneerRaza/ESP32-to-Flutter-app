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

  factory DataPacket.fromBytes(List<int> bytes) {
    String action = utf8.decode(bytes.sublist(0, 10));
    String motor = utf8.decode(bytes.sublist(10, 20));
    bool rLimit = bytes[20] == 1;
    bool fLimit = bytes[21] == 1;
    String mode = utf8.decode(bytes.sublist(22, 32));
    return DataPacket(action, motor, rLimit, fLimit, mode);
  }

  List<int> toBytes() {
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
  bool isAlertOn = false;
  //Bluetooth config
  FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice device;
  late BluetoothCharacteristic characteristic;
  final String DEVICE_NAME = "ESP32_Motor";
  final String SERVICE_UUID = '29b8e60c-b575-47ab-b38f-e74f676df270';
  final String CHARACTERISTIC_UUID = 'bd91b3b6-82be-480a-ace2-0f97b1b081e3';

  bool isManual = false; // mode
  Color circleColor = Colors.yellow;
  Icon playIcon = const Icon(Icons.play_arrow_rounded, size: 30,);
  Icon pauseIcon = const Icon(Icons.pause, size: 25);
  Icon dynamicIcon = const Icon(Icons.play_arrow_rounded, size: 30,);
  String status = 'Stopped'; // motor
  String action = 'None';
  bool fLimit = false;
  bool rLimit = false;


  @override
  void initState() {
    super.initState();
    checkBluetoothStatus();
  }
  void checkBluetoothStatus() async {
    FlutterBlue flutterBlue = FlutterBlue.instance;

    bool isBluetoothOn = await flutterBlue.isOn;
    if (!isBluetoothOn) {
      isAlertOn = true;
      showBluetoothOffAlert();
    }

    flutterBlue.state.listen((state) {
      if (state == BluetoothState.on) {
        if (isAlertOn) {
          Navigator.of(context).pop();
        }
        initBlue();
      }
    });
  }

  void showBluetoothOffAlert() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Bluetooth Error'),
          content: Text('Please turn on Bluetooth to use this app.'),
        );
      },
    );
  }


  void initBlue() {
    flutterBlue.startScan().onError((error, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
        content: Text('Error while scanning devices!', style: GoogleFonts.poppins(textStyle: const TextStyle(color: Colors.white)),),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
      ));
    });

    flutterBlue.scanResults.listen((results) {
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
                            DataPacket data = DataPacket(action, status, rLimit, fLimit, 'Manual');
                            sendData(data);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Manual Mode'),
                              duration: Duration(seconds: 1),
                            ));
                          } else {
                            // TODO: Auto mode
                            DataPacket data = DataPacket(action, status, rLimit, fLimit, 'Auto');
                            sendData(data);
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
                          DataPacket data = DataPacket(action, status, rLimit, fLimit, 'Manual');
                          sendData(data);
                        }
                      },
                      onLongPressEnd: rLimit ? null : (details) {
                        if(isManual && status == 'Started'){
                          setState(() {
                            action = 'None';
                          });
                          DataPacket data = DataPacket(action, status, rLimit, fLimit, 'Manual');
                          sendData(data);
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
                            DataPacket data = DataPacket(action, status, rLimit, fLimit, 'Auto');
                            sendData(data);
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
                          var mode = '';
                          if (isManual){
                            mode = 'Manual';
                          } else {
                            mode = 'Auto';
                          }
                          if(status == 'Started'){
                            DataPacket data = DataPacket(action, status, rLimit, fLimit, mode);
                            sendData(data);
                          } else if(status == 'Stopped'){
                            DataPacket data = DataPacket(action, status, rLimit, fLimit, mode);
                            sendData(data);
                          }

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
                          DataPacket data = DataPacket(action, status, rLimit, fLimit, 'Manual');
                          sendData(data);
                        }
                      },
                      onLongPressEnd: fLimit ? null : (details) {
                        if(isManual && status == 'Started'){
                          setState(() {
                            action = 'None';
                          });
                          DataPacket data = DataPacket(action, status, rLimit, fLimit, 'Manual');
                          sendData(data);
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
                            DataPacket data = DataPacket(action, status, rLimit, fLimit, 'Auto');
                            sendData(data);
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
      await device.connect().then((value) {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(
          content: Text('Successfully Connected to $DEVICE_NAME'),
          duration: const Duration(seconds: 1),
        ));
      });
      discoverServices();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
        content: Text('Error occur while connecting to $DEVICE_NAME'),
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
    characteristic.write(data.toBytes(), withoutResponse: true).onError((error, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
        duration: const Duration(seconds: 1),
      ));
    });


  }



}
