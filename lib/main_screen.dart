import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class MotorController extends StatefulWidget {
  const MotorController({super.key});

  @override
  State<MotorController> createState() => _MotorControllerState();
}

class _MotorControllerState extends State<MotorController> {
  bool isManual = false;
  Color circleColor = Colors.yellow;
  Icon playIcon = const Icon(Icons.play_arrow_rounded, size: 30,);
  Icon pauseIcon = const Icon(Icons.pause, size: 25);
  Icon dynamicIcon = const Icon(Icons.play_arrow_rounded, size: 30,);
  String status = 'Stopped';
  String action = 'None';

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
              child: Center(child: Text('Status: $status\n Action: $action')),
              width: x,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.black, // Customize border color
                  width: 1.5, // Customize border width
                ),
              ),
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
                      onLongPressStart: (details) {
                      //   TODO: reverse long press start
                      },
                      onLongPressEnd: (details) {
                        // TODO: revere long press end
                      },
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey[300],
                        onPressed: () {},
                        child: const Icon(Icons.arrow_upward_rounded,),
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
                            } else if(status == 'Stopped'){
                              dynamicIcon = pauseIcon;
                              status = 'Started';
                            }
                          });
                        },
                        child: dynamicIcon
                    ),
                    const SizedBox(height: 20,),
                    GestureDetector(
                      onLongPressStart: (details) {
                        //   TODO: forward long press start
                      },
                      onLongPressEnd: (details) {
                        // TODO: forward long press end
                      },
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey[300],
                        onPressed: () {},
                        child: const Icon(Icons.arrow_downward_rounded),
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
}
