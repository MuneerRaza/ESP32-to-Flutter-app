import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';

class DataPacket {
  String stepperAction;
  String motor;
  bool rLimit;
  bool fLimit;
  String mode;

  DataPacket(this.stepperAction, this.motor, this.rLimit, this.fLimit, this.mode);

  factory DataPacket.fromBytes(List<int> bytes) {
    String stepperAction = utf8.decode(bytes.sublist(0, 10));
    String motor = utf8.decode(bytes.sublist(10, 20));
    bool rLimit = bytes[20] == 1;
    bool fLimit = bytes[21] == 1;
    String mode = utf8.decode(bytes.sublist(22, 32));
    return DataPacket(stepperAction, motor, rLimit, fLimit, mode);
  }

  List<int> toBytes() {
    List<int> bytes = utf8.encode(stepperAction) + utf8.encode(motor) + [rLimit ? 1 : 0, fLimit ? 1 : 0] + utf8.encode(mode);
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
  String stepperStatus = 'Stopped';
  String servoStatus = 'Stopped';
  String stepperAction = 'None';
  String servoAction = 'None';
  int servoNum = 0;
  bool fLimit = false;
  bool rLimit = false;
  Color servo1Color = const Color(0xFFFFF98D);
  Color servo2Color = const Color(0xFFFFF98D);
  Color servo3Color = const Color(0xFFFFF98D);
  Icon servoIcon = const Icon(Icons.arrow_forward_ios_rounded);
  Icon servoForward = const Icon(Icons.arrow_forward_ios_rounded);
  Icon servoBackward = const Icon(Icons.arrow_back_ios_new_rounded);


  @override
  void initState() {
    super.initState();
    checkBluetoothStatus();
  }
  void checkBluetoothStatus() async {
    print("hello");
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
    flutterBlue.scanResults.listen((results) {
    for (ScanResult result in results) {
      print('Device Name: ${result.device.name}, RSSI: ${result.rssi}');
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
              width: x,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.black, // Customize border color
                  width: 1.5, // Customize border width
                ),
              ),
              child: Center(
                child: Text('Stepper Status: $stepperStatus\nStepper Action: $stepperAction\n\nServo Status: $servoStatus\nServo Action: $servoAction',
                style: GoogleFonts.poppins(textStyle: TextStyle(fontSize: x*0.04)),
                textAlign: TextAlign.center,),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: y*0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Auto', style: GoogleFonts.poppins(textStyle: TextStyle(fontSize: x*0.04),)),
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
                      Text('Manual', style: GoogleFonts.poppins(textStyle: TextStyle(fontSize: x*0.04),)),
                    ],
                  ),

                  Container(
                    width: 25,
                    height: 25,
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
                      height: y*0.15,
                    ),
                    GestureDetector(
                      onLongPressStart: rLimit ? null : (details) {
                        if(isManual && stepperStatus == 'Started'){
                          setState(() {
                            stepperAction = 'Reverse';
                            fLimit = false;
                            circleColor = Colors.orange;
                          });
                           sendData(createUpdatedDataPacket());
                        //   TODO reverse long press start
                        }
                      },
                      onLongPressEnd: rLimit ? null : (details) {
                        if(isManual && stepperStatus == 'Started'){
                          setState(() {
                            circleColor = Colors.green;
                            stepperAction = 'None';
                          });
                          sendData(createUpdatedDataPacket());
                          //   TODO reverse long press end
                        }
                      },
                      child: SizedBox(
                        width: x*0.16,
                        child: FittedBox(
                          child: FloatingActionButton(
                            backgroundColor: rLimit ? Colors.grey[400]: Colors.blueGrey[300],
                            disabledElevation: 0,
                            onPressed: rLimit ? null : () {
                              if(!isManual && stepperStatus == 'Started'){
                                setState(() {
                                  circleColor = Colors.orange;
                                  stepperAction = 'Reverse';
                                  fLimit = false;
                                });
                                //   TODO reverse press
                                sendData(createUpdatedDataPacket());
                              }
                            },
                            child: Icon(Icons.arrow_upward_rounded, color: rLimit ? Colors.grey[700]:Colors.black,),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    SizedBox(
                      width: x*0.16,
                      child: FittedBox(
                        child: FloatingActionButton(
                            backgroundColor: Colors.blueGrey[300],
                            onPressed: () {
                              setState(() {
                                if(stepperStatus == 'Started'){
                                  dynamicIcon = playIcon;
                                  stepperStatus = 'Stopped';
                                  stepperAction = 'None';
                                  circleColor = Colors.yellow;
                                } else if(stepperStatus == 'Stopped'){
                                  dynamicIcon = pauseIcon;
                                  stepperStatus = 'Started';
                                  servoNum = 0;
                                  servoStatus = 'Stopped';
                                  servoAction = 'None';
                                  servo1Color = servo2Color = servo3Color = const Color(0xFFFFF98D);
                                  circleColor = Colors.green;
                                }
                              });
                              // var mode = '';
                              if (isManual){
                                // mode = 'Manual';
                              } else {
                                // mode = 'Auto';
                              }
                              if(stepperStatus == 'Started'){
                                //   TODO stepper start
                              } else if(stepperStatus == 'Stopped'){
                                //   TODO stepper stop
                              }
                              sendData(createUpdatedDataPacket());

                            },
                            child: dynamicIcon
                        ),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    GestureDetector(
                      onLongPressStart: fLimit ? null : (details) {
                        if(isManual && stepperStatus == 'Started'){
                          setState(() {
                            circleColor = Colors.blue;
                            stepperAction = 'Forward';
                            rLimit = false;
                          });
                          //   TODO forward long press start
                          sendData(createUpdatedDataPacket());
                        }
                      },
                      onLongPressEnd: fLimit ? null : (details) {
                        if(isManual && stepperStatus == 'Started'){
                          setState(() {
                            circleColor = Colors.green;
                            stepperAction = 'None';
                          });
                          //   TODO forward long press end
                          sendData(createUpdatedDataPacket());
                        }
                      },
                      child: SizedBox(
                        width: x*0.16,
                        child: FittedBox(
                          child: FloatingActionButton(
                            backgroundColor: fLimit ? Colors.grey[400]: Colors.blueGrey[300],
                            disabledElevation: 0,
                            onPressed: fLimit ? null : () {
                              if(!isManual && stepperStatus == 'Started'){
                                setState(() {
                                  circleColor = Colors.blue;
                                  stepperAction = 'Forward';
                                  rLimit = false;
                                });
                                sendData(createUpdatedDataPacket());
                                //   TODO forward press
                              }
                            },
                            child: Icon(Icons.arrow_downward_rounded, color: fLimit ? Colors.grey[700]:Colors.black,),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
            Container(
              height: y*0.03,
            ),
            const Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text('Servo Motors'),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Container(
              height: y*0.03,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                    onPressed: (){
                      if(stepperStatus == 'Stopped'){
                        setState(() {
                          if (servo1Color == Colors.blueGrey[300]) {
                            servoNum--;
                            if (servoNum == 0) {
                              servoAction = 'None';
                            }
                            servoStatus = 'Servo 1 Stopped';
                            servo1Color = const Color(0xFFFFF98D);
                          } else {
                            servoNum++;
                            servoStatus = 'Servo 1 Started';
                            servo1Color = Colors.blueGrey[300]!;
                          }
                        });
                      }
                    },
                    backgroundColor: servo1Color,
                    splashColor: Colors.transparent,
                    child: Text('1', style: TextStyle(fontSize: x*0.045),)
                ),
                FloatingActionButton(
                    onPressed: (){
                      if(stepperStatus == 'Stopped'){
                      setState(() {
                        if (servo2Color == Colors.blueGrey[300]) {
                          servoNum--;
                          if (servoNum == 0) {
                            servoAction = 'None';
                          }
                          servoStatus = 'Servo 2 Stopped';
                          servo2Color = const Color(0xFFFFF98D);
                        } else {
                          servoNum++;
                          servoStatus = 'Servo 2 Started';
                          servo2Color = Colors.blueGrey[300]!;
                        }
                      });
                    }
                    },
                    backgroundColor: servo2Color,
                    splashColor: Colors.transparent,
                    child: Text('2', style: TextStyle(fontSize: x*0.045),)
                ),
                FloatingActionButton(
                    onPressed: (){
                      if(stepperStatus == 'Stopped'){
                        setState(() {
                          if (servo3Color == Colors.blueGrey[300]) {
                            servoNum--;
                            if (servoNum == 0) {
                              servoAction = 'None';
                            }
                            servoStatus = 'Servo 3 Stopped';
                            servo3Color = const Color(0xFFFFF98D);
                          } else {
                            servoNum++;
                            servoStatus = 'Servo 3 Started';
                            servo3Color = Colors.blueGrey[300]!;
                          }
                        });
                      }
                    },
                    backgroundColor: servo3Color,
                    splashColor: Colors.transparent,

                    child: Text('3', style: TextStyle(fontSize: x*0.045),)
                ),
                const SizedBox(width: 15,),
                FloatingActionButton(
                  backgroundColor: Colors.blueGrey[300],
                    onPressed: (){
                      if(servoNum > 0){
                        setState(() {
                          if(servoIcon == servoForward){
                            servoAction = 'Backward';
                            servoIcon = servoBackward;
                          } else {
                            servoAction = 'Forward';
                            servoIcon = servoForward;
                          }
                        });
                      }
                    },
                    child: servoIcon)
              ],
            ),

          ],
        ),
      ),
    );
    
  
  }
  
  DataPacket createUpdatedDataPacket() {
    return DataPacket(stepperAction, stepperStatus, rLimit, fLimit, isManual ? 'manual' : 'auto');
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
              stepperAction = receivedData.stepperAction;
              stepperStatus = receivedData.motor;
              if (receivedData.mode == 'manual'){
                isManual = true;
              } else if(receivedData.mode == 'auto') {
                isManual = false;
              }
              rLimit = receivedData.rLimit;
              fLimit = receivedData.fLimit;
            });
          });
          return;
        }
      }

    }
  }
}
void sendData(DataPacket data) async {
  // List<BluetoothService> services = await device.discoverServices();
  // for (var service in services) {
  //   if (service.uuid.toString() == SERVICE_UUID) {
  //     for (var characteristic in service.characteristics) {
  //       if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
  //         this.characteristic = characteristic;
  //         // Subscribe to notifications
  //         characteristic.setNotifyValue(true);
          String val = "a";
          List<int> b = utf8.encode(val);
          await characteristic.write(data.toBytes(), withoutResponse: true).onError((error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(error.toString()),
              duration: const Duration(seconds: 1),
            ));
          });
  //   //     }
  //   //   }
  //   // }
  // }
    // init a sample value to send

    // int v = 0;
    
    
  // } else {
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text('Bluetooth characteristic not initialized'),
  //     duration: const Duration(seconds: 1),
  //   ));
  // }
}
  //

}
