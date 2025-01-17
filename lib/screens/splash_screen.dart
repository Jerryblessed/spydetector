import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spydetector/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ));
    });
    //
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.black,
            statusBarBrightness: Brightness.light, // For iOS: (dark icons)
            statusBarIconBrightness:
                Brightness.dark, // For Android: (dark icons)
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: size.height * 0.15,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/spydetector.png',
            ),
          ),
          Positioned(
            child: Container(
              margin: EdgeInsets.only(top: size.height * 0.35),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontSize: 35,
                        fontFamily: '',
                        fontWeight: FontWeight.w900,
                        color: Color(0xff2572FE),
                      ),
                    ),
                    Text(
                      '',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff2572FE),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
