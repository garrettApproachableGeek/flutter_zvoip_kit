import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_zvoip_kit/call.dart';
import 'package:flutter_zvoip_kit/flutter_zvoip_kit.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Call> calls = [];
  bool hasPermission = false;
  bool callShouldFail = false;

  @override
  void initState() {
    super.initState();

    FlutterZVoipKit.init(callStateChangeHandler: callStateChangeHandler);

    checkPermissionsUntilGranted();

    //listens to when call list is updated
    FlutterZVoipKit.callListStream.listen((allCalls) {
      setState(() {
        calls = allCalls;
      });
    });
  }

  Future<bool> callStateChangeHandler(call) async {
    dev.log("widget call state changed lisener: $call");
    setState(
        () {}); //calls states have been updated, setState so ui can reflect that

    //it is important we perform logic and return true/false for every CallState possible
    switch (call.callState) {
      case CallState
          .connecting: //simulate connection time of 3 seconds for our VOIP service
        dev.log("--------------> Call connecting");
        await Future.delayed(const Duration(seconds: 3));
        return true;
      case CallState
          .active: //here we would likely begin playig audio out of speakers
        dev.log("--------> Call active");
        return true;
      case CallState.ended: //end audio, disconnect
        dev.log("--------> Call ended");
        await Future.delayed(const Duration(seconds: 1));
        return true;
      case CallState.failed: //cleanup
        dev.log("--------> Call failed");
        return true;
      case CallState.held: //pause audio for specified call
        dev.log("--------> Call held");
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Voip Kit Example'),
      ),
      body: !hasPermission
          ? Center(
              child: ElevatedButton(
                child: Text("Grant Phone Permissions"),
                onPressed: () {
                  FlutterZVoipKit.checkPermissions(openSettings: true)
                      .then((value) => setState(() {
                            hasPermission = value;
                          }));
                },
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  ElevatedButton(
                    child: Text("Simlualate incoming call"),
                    onPressed: () {
                      Future.delayed(const Duration(seconds: 2)).then((value) {
                        FlutterZVoipKit.reportIncomingCall(
                            handle: "${Random().nextInt(10)}" * 9,
                            uuid: Uuid().v4());
                      });
                    },
                  ),
                  ElevatedButton(
                    child: Text("Start Call outgoing call"),
                    onPressed: () {
                      FlutterZVoipKit.startCall(
                        "${Random().nextInt(10)}" * 9,
                      );
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        final call = calls[index];
                        return Container(
                          color: call.callState == CallState.active
                              ? Colors.green[300]
                              : call.callState == CallState.held
                                  ? Colors.yellow[800]
                                  : (call.callState == CallState.connecting
                                      ? Colors.yellow[200]
                                      : Colors.red),
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text("Number: ${call.address}"),
                              ),
                              if (call.callState == CallState.connecting)
                                CircularProgressIndicator(),
                              if (call.callState != CallState.connecting &&
                                  call.callState != CallState.incoming)
                                ElevatedButton(
                                  onPressed: () {
                                    call.hold(
                                        onHold: !(call.callState ==
                                            CallState.held));
                                  },
                                  child: Text(call.callState == CallState.held
                                      ? "Resume"
                                      : "Hold"),
                                ),
                              if (call.callState == CallState.active)
                                IconButton(
                                  icon: Icon(
                                    Icons.phone_disabled_sharp,
                                    size: 30,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    call.end();
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                      itemCount: calls.length,
                    ),
                  )
                ],
              ),
            ),
    );
  }

  void checkPermissionsUntilGranted() {
    Future.delayed(const Duration(milliseconds: 100)).then((value) async {
      //delay to wait for init state to be done
      hasPermission =
          await FlutterZVoipKit.checkPermissions(openSettings: false);
      bool first = true; //dont bring to settings first time
      while (!hasPermission) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("No Permissions"),
              content: Text(
                  "You allow this app to use your phone and add it to phone list in settings."),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Ok"),
                )
              ],
            );
          },
        );

        hasPermission =
            await FlutterZVoipKit.checkPermissions(openSettings: !first);
        first = false;
        if (!hasPermission) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      setState(() {});
    });
  }
}
