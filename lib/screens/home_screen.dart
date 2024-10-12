import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:spydetector/screens/change_language.dart';
import 'package:spydetector/screens/server_location.dart';
import 'package:spydetector/src/ui/trace_screen_auto.dart';

import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:spydetector/src/ui/trace_screen.dart';

const kBgColor = Color(0xff246CE2);

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isConnected = false;

  // wireguard start

  final wireguard = WireGuardFlutter.instance;

  final WireguardService _wireguardService = WireguardService();
  String _downloadCount = 'N/A';
  String _uploadCount = 'N/A';
  late String name;

  // wireguard ends

  Duration _duration = const Duration();
  Timer? _timer;

// wireguard start
  @override
  void initState() {
    super.initState();
    _getWireGuardDataCounts();
    wireguard.vpnStageSnapshot.listen((event) {
      debugPrint("status changed $event");
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('status changed: $event'),
        ));
      }
    });
    name = 'my_wg_vpn';
  }

  Future<void> initialize() async {
    try {
      await wireguard.initialize(interfaceName: name);
      debugPrint("initialize success $name");
    } catch (error, stack) {
      debugPrint("failed to initialize: $error\n$stack");
    }
  }

  void _getWireGuardDataCounts() async {
    try {
      final dataCounts = await _wireguardService.getDataCounts();
      setState(() {
        _downloadCount = dataCounts['download'].toString();
        _uploadCount = dataCounts['upload'].toString();
      });
    } catch (e) {
      print('Failed to get data counts: $e');
    }
  }

  void startVpn() async {
    try {
      await wireguard.startVpn(
        serverAddress: '167.235.55.239:51820',
        wgQuickConfig: conf,
        providerBundleIdentifier: 'com.billion.wireguardvpn.WGExtension',
      );
    } catch (error, stack) {
      debugPrint("failed to start $error\n$stack");
    }
  }

  void disconnect() async {
    try {
      await wireguard.stopVpn();
    } catch (e, str) {
      debugPrint('Failed to disconnect $e\n$str');
    }
  }

  void getStatus() async {
    debugPrint("getting stage");
    final stage = await wireguard.stage();
    debugPrint("stage: $stage");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('stage: $stage'),
      ));
    }
  }

// wireguard ends

  startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      const addSeconds = 1;
      setState(() {
        final seconds = _duration.inSeconds + addSeconds;
        _duration = Duration(seconds: seconds);
      });
    });
  }

  stopTimer() {
    setState(() {
      _timer?.cancel();
      _duration = const Duration();
    });
  }

  void _showScanModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 500,
          child: Center(
            child: _ScanProgress(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.electric_bolt,
                    color: Colors.orangeAccent,
                    size: 26,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'spyguard',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: kBgColor,
                    ),
                  ),
                ],
              ),
            ),
            // ListTile(
            //   onTap: () {
            //     Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) => const ChangeLanguage()));
            //   },
            //   leading: const Icon(
            //     Icons.translate,
            //     size: 18,
            //   ),
            //   title: const Text(
            //     'Change Language',
            //     style: TextStyle(fontSize: 14),
            //   ),
            //   trailing: const Icon(
            //     Icons.arrow_forward_ios_rounded,
            //     size: 16,
            //   ),
            // ),
            // const ListTile(
            //   leading: Icon(
            //     Icons.rate_review,
            //     size: 18,
            //   ),
            //   title: Text(
            //     'Rate US',
            //     style: TextStyle(fontSize: 14),
            //   ),
            //   trailing: Icon(
            //     Icons.arrow_forward_ios_rounded,
            //     size: 16,
            //   ),
            // ),
            // const ListTile(
            //   leading: Icon(
            //     Icons.share,
            //     size: 18,
            //   ),
            //   title: Text(
            //     'Share App',
            //     style: TextStyle(fontSize: 14),
            //   ),
            //   trailing: Icon(
            //     Icons.arrow_forward_ios_rounded,
            //     size: 16,
            //   ),
            // ),
            // const ListTile(
            //   leading: Icon(
            //     Icons.info,
            //     size: 18,
            //   ),
            //   title: Text(
            //     'About',
            //     style: TextStyle(fontSize: 14),
            //   ),
            //   trailing: Icon(
            //     Icons.arrow_forward_ios_rounded,
            //     size: 16,
            //   ),
            // ),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(
          elevation: 0,
          backgroundColor: kBgColor,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: kBgColor,
            statusBarBrightness: Brightness.dark, // For iOS: (dark icons)
            statusBarIconBrightness:
                Brightness.light, // For Android: (dark icons)
          ),
        ),
      ),
      backgroundColor: kBgColor,
      body: SafeArea(
        child: ListView(
          children: [
            SizedBox(
              height: size.height * 0.4,
              child: Column(
                children: [
                  /// header action icons
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: InkWell(
                            onTap: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                            child: const Icon(
                              Icons.segment,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const Row(
                          children: [
                            // Icon(
                            //   Icons.vpn_key,
                            //   color: Colors.greenAccent,
                            //   size: 22,
                            // ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'connect to spydetector',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600),
                            ),
                            SizedBox(
                              width: 50,
                            ),
                          ],
                        ),
                        // const Icon(
                        //   Icons.settings_outlined,
                        //   color: Colors.white,
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: kBgColor,
                      child: Column(
                        children: [
                          SizedBox(
                            height: size.height * 0.02,
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(size.height),
                            onTap: () {
                              // Call either getStatus or initialize based on connection state
                              _isConnected ? getStatus() : initialize();

                              // Call either disconnect or startVpn based on connection state
                              _isConnected ? disconnect() : startVpn();

                              // Start or stop the timer
                              _isConnected ? stopTimer() : startTimer();

                              // Update the connection state
                              setState(() => _isConnected = !_isConnected);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  width: size.height * 0.12,
                                  height: size.height * 0.12,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.power_settings_new,
                                          size: size.height * 0.035,
                                          color: kBgColor,
                                        ),
                                        Text(
                                          _isConnected
                                              ? 'Disconnect'
                                              : 'Connect',
                                          style: TextStyle(
                                            fontSize: size.height * 0.013,
                                            fontWeight: FontWeight.w500,
                                            color: kBgColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: size.height * 0.01,
                          ),
                          Column(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: _isConnected ? 90 : size.height * 0.14,
                                height: size.height * 0.030,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  _isConnected ? 'Connected' : 'Not Connected',
                                  style: TextStyle(
                                    fontSize: size.height * 0.015,
                                    color: kBgColor,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: size.height * 0.012,
                              ),
                              _countDownWidget(size),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: Platform.isIOS ? size.height * 0.51 : size.height * 0.565,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Column(
                children: [
                  /// horizontal line
                  Container(
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                        color: const Color(0xffB4B4C7),
                        borderRadius: BorderRadius.circular(3)),
                    height: size.height * 0.005,
                    width: 35,
                  ),

                  /// Connection Information
                  Expanded(
                    child: Padding(
                      // padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                      padding: const EdgeInsets.fromLTRB(50, 30, 30, 0),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: Row(
                                children: [],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Material(
                    color: kBgColor,
                    child: InkWell(
                      onTap: () {
                        _showScanModal(
                            context); // Show scan modal instead of navigating
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        child: Row(
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                                Text(
                                  ' Scan network now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: 25,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_right_outlined,
                                size: 25,
                                color: kBgColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 60,
                        bottom: 10), // More padding on top, less on bottom
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const TraceScreen2()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // White background
                        foregroundColor: Colors.black, // Black text color
                        side: const BorderSide(
                            color: Colors.lightBlue,
                            width: 2), // Light blue border
                        minimumSize:
                            const Size(250, 50), // Wider button (250px width)
                        padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 40), // More internal padding
                        textStyle:
                            const TextStyle(fontSize: 20), // Larger text size
                      ),
                      child: const Text('Information'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countDownWidget(Size size) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    final hours = twoDigits(_duration.inHours.remainder(60));

    return Text(
      '$hours : $minutes : $seconds',
      style: TextStyle(color: Colors.white, fontSize: size.height * 0.03),
    );
  }
}

const String conf = '''
[Interface]
Address = 192.168.6.86/32
DNS = 1.1.1.1,8.8.8.8
PrivateKey = CMikDp937nfKPJNwobRttjXEthGcSJW+B5jSW0kcEks=
[Peer]
publickey=zwBItQRGuJze84z4Gv/27O/Xq4CIA0BBCRLWiEXnwC4=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = uk.vpnjantit.com:1024
''';

class WireguardService {
  static const platform =
      MethodChannel('billion.group.wireguard_flutter/wgcontrol');

  Future<Map<String, int>> getDataCounts() async {
    try {
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod('getDataCounts');
      return Map<String, int>.from(result);
    } catch (e) {
      throw 'Failed to get data counts: $e';
    }
  }
}

// circular progress bar
class _ScanProgress extends StatefulWidget {
  @override
  State<_ScanProgress> createState() => __ScanProgressState();
}

class __ScanProgressState extends State<_ScanProgress> {
  double progress = 0.0;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 1000), (Timer timer) {
      setState(() {
        progress += 1;
        if (progress >= 100) {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        CircularProgressIndicator(
          value: progress / 100,
          strokeWidth: 6,
        ),
        const Text('Scanning...', style: TextStyle(fontSize: 18)),
        const Text('Use your phone then go back to app...',
            style: TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        Text('${progress.toInt()}%', style: const TextStyle(fontSize: 18)),
        if (progress >= 100) ...[
          const SizedBox(height: 40),
          const Text('Successfully scanned devices',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TraceScreen2()),
              );
            },
            child: const Text('see network scan logs'),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// circular progress bar
