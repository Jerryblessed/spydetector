import 'package:flutter/material.dart';
import 'package:flutter_traceroute/flutter_traceroute.dart';
import 'dart:async';

import 'package:flutter_traceroute/flutter_traceroute_platform_interface.dart';

class TraceScreen extends StatefulWidget {
  const TraceScreen({Key? key}) : super(key: key);

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  final List<Map<String, dynamic>> iocs = [
    {
      "type": "cidr",
      "tag": "suspicious",
      "tlp": "white",
      "value": "172.16.250.70"
    },
    {
      "type": "cidr",
      "tag": "suspicious",
      "tlp": "white",
      "value": "206.224.70.116"
    },
    {
      "type": "freedns",
      "tag": "suspicious",
      "tlp": "white",
      "value": "hicam.net"
    }
  ];

  final Map<String, Map<String, String>> websites = {
    "google.com": {"ip_address": "8.8.8.8"},
    "bing.com": {"ip_address": "40.113.200.201"}
  };

  List<String> allTracerouteIPs = []; // Store all traced IPs
  List<Map<String, dynamic>> matchedIocs = []; // Store matched IOCs

  final FlutterTraceroute traceroute = FlutterTraceroute();
  bool isTracing = false;
  String log = '';

  @override
  void initState() {
    super.initState();
  }

  // Perform traces for all websites
  Future<void> performTraces() async {
    setState(() {
      isTracing = true;
      log = 'Starting networking analysis...\n';
    });

    for (var website in websites.entries) {
      String name = website.key;
      String ip = website.value['ip_address'] ?? '';

      log += 'Tracing $name ($ip)...\n';
      setState(() {});

      // Trace the current website and perform IOC checking after each trace
      await traceWebsiteWithTimeout(ip, name);
    }

    setState(() {
      isTracing = false;
    });

    // After all traces, check for IOC matches
    Future.delayed(const Duration(milliseconds: 500), () {
      if (matchedIocs.isNotEmpty) {
        showAlert(); // If IOC matches are found
      } else {
        showGoodToGo(); // If no IOC matches
      }
    });
  }

  // Perform traceroute with a timeout
  Future<void> traceWebsiteWithTimeout(String ip, String websiteName) async {
    Completer<void> completer = Completer<void>();
    TracerouteArgs args = TracerouteArgs(host: ip, ttl: 30);
    List<String> websiteTracerouteIPs = []; // Store IPs for this website

    // Start the traceroute
    Stream<TracerouteStep> traceStream = traceroute.trace(args);

    // Set a timer to stop the traceroute after 10 seconds
    Timer timer = Timer(const Duration(seconds: 10), () {
      log += 'Timeout for $websiteName after 10 seconds.\n';
      setState(() {});
      traceroute.stopTrace();
      completer.complete();
    });

    // Listen for traceroute events
    traceStream.listen((event) {
      if (event is TracerouteStepFinished || !timer.isActive) {
        // When traceroute finishes or timer expires, store the IPs
        log += 'Completed traceroute for $websiteName.\n\n';
        setState(() {});
        allTracerouteIPs.addAll(websiteTracerouteIPs);

        // Check if any IPs in websiteTracerouteIPs match any IOC value
        checkIOCs(websiteTracerouteIPs); // Check the collected IPs

        completer.complete();
        timer.cancel(); // Cancel the timer since we're done
      } else if (event is TracerouteStep) {
        setState(() {
          String? extractedIp = extractIp(event.toString());
          if (extractedIp != null) {
            websiteTracerouteIPs.add(extractedIp); // Store IPs during tracing
            allTracerouteIPs.add(extractedIp);
            log += '$extractedIp\n'; // Log only the IP
          }
        });
      }
    }, onError: (error) {
      log += 'Error tracing $websiteName: $error\n\n';
      setState(() {});
      completer.complete();
    });

    await completer.future;
  }

  // Method to check IOCs against collected traceroute IPs
  void checkIOCs(List<String> websiteTracerouteIPs) {
    for (var ioc in iocs) {
      String type = ioc['type'];
      String value = ioc['value'];

      if (type == 'cidr') {
        for (var ip in websiteTracerouteIPs) {
          if (isIpInCidr(ip, value)) {
            matchedIocs.add(ioc); // Add the IOC JSON if there's a match
          }
        }
      } else if (type == 'freedns') {
        // Additional logic for DNS-based matching (if necessary)
      }
    }
  }

  // Display alert for matched IOCs
  void showAlert() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AlertScreen(
        isThreat: true,
        iocs: matchedIocs,
      ),
    ));
  }

  // Display "Good to go" message
  void showGoodToGo() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const AlertScreen(
        isThreat: false,
      ),
    ));
  }

  // Extract IP address from TracerouteStep
  String? extractIp(String tracerouteStepString) {
    RegExp ipRegex = RegExp(r'(\d{1,3}\.){3}\d{1,3}', multiLine: true);
    Match? match = ipRegex.firstMatch(tracerouteStepString);
    return match?.group(0);
  }

  // Check if IP is within a CIDR range
  bool isIpInCidr(String ip, String cidr) {
    List<String> cidrParts = cidr.split('/');
    if (cidrParts.length != 2) return false;

    String baseIp = cidrParts[0];
    int prefix = int.tryParse(cidrParts[1]) ?? 0;

    int ipInt = ipToInt(ip);
    int baseIpInt = ipToInt(baseIp);

    if (prefix < 0 || prefix > 32) return false;

    int mask = prefix == 0 ? 0 : (~0 << (32 - prefix)) & 0xFFFFFFFF;
    return (ipInt & mask) == (baseIpInt & mask);
  }

  int ipToInt(String ip) {
    List<String> parts = ip.split('.');
    return (int.parse(parts[0]) << 24) +
        (int.parse(parts[1]) << 16) +
        (int.parse(parts[2]) << 8) +
        int.parse(parts[3]);
  }

  @override
  void dispose() {
    traceroute.stopTrace();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Starting networking analysis...')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTracing) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              log,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: performTraces,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}

class AlertScreen extends StatelessWidget {
  final bool isThreat;
  final List<Map<String, dynamic>>? iocs;

  const AlertScreen({Key? key, required this.isThreat, this.iocs})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isThreat ? Colors.red : Colors.green,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isThreat
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your device is watched by:',
                      style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...iocs!.map((ioc) {
                      return Text(
                        'Type: ${ioc['type']}, Value: ${ioc['value']}',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                        textAlign: TextAlign.center,
                      );
                    }).toList(),
                  ],
                )
              : const Text(
                  'Good to go!',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
