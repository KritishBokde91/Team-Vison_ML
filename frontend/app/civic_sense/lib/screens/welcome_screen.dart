import 'package:civic_sense/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Lottie.asset('assets/lotties/welcome1.json', reverse: true),
            Text(
              'Welcome to Civic Sense',
              style: GoogleFonts.robotoCondensed(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 3.h,
            ),
            SizedBox(
              height: 6.h,
              width: 50.w,
              child: Stack(
                children: [
                  Positioned(
                    child: Container(
                      height: 6.h,
                      width: 50.w,
                      decoration: BoxDecoration(
                        color: Color(0xFF61d5bd),
                        borderRadius: BorderRadius.circular(20.sp),
                      ),
                    ),
                  ),
                  Positioned(
                      child: Container(
                        height: 6.h,
                        width: 50.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF).withValues(alpha: 0.75),
                                Color(0xFFFFFFFF).withValues(alpha: 0.28),
                                Color(0xFFFFFFFF).withValues(alpha: 0.18),
                                Color(0xFFFFFFFF).withValues(alpha: 0),
                              ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter
                          ),
                          borderRadius: BorderRadius.circular(20.sp),
                        ),
                      ),
                  ),
                  Positioned.fill(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20.sp),
                      onTap: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
                      },
                      child: Center(
                        child: Text(
                          'Get Started',
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
