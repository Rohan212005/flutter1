import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import '../widgets/background_painter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class AuthPage extends StatefulWidget {
  final String email;
  final Map<String, dynamic> userData;

  const AuthPage({Key? key, required this.email, required this.userData})
      : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> controllers =
      List.generate(6, (index) => TextEditingController());
  late String otp; // Store the generated OTP

  @override
  void initState() {
    super.initState();
    otp = generateOTP();
    sendOTPEmail(widget.email, otp);
  }

  // Function to set the logged-in status
  Future<void> _setLoggedInStatus(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus all OTP fields when tapping outside
        for (var node in focusNodes) {
          node.unfocus();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            CustomPaint(painter: BackgroundPainter(), child: Container()),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 120.0),
                      child: Text(
                        "Verification Required",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    Text(
                      "Please enter the OTP sent to your email address",
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.email,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    // OTP input fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) => SizedBox(
                          width: 40,
                          height: 50,
                          child: _otpField(index),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
  onPressed: () async {
    // Collect the OTP from the input fields
    final enteredOTP = controllers.map((controller) => controller.text).join();

    if (enteredOTP == otp) {
      // OTP verification successful
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification successful!')),
      );

      try {
        // Set logged-in status to true
        await _setLoggedInStatus(true);

        // Navigate to HomePage
        Navigator.pushReplacementNamed(context, '/home', arguments: {'showSnackbar': true});
      } on FirebaseAuthException catch (e) {
        // Handle Firestore errors (e.g., show a SnackBar)
        print("Error saving user data: ${e.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error registering user. Please try again."),
          ),
        );
      }
    } else {
      // Handle OTP verification failure (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  },
     style: ElevatedButton.styleFrom(
       padding: EdgeInsets.symmetric(
         horizontal: 48, vertical: 16),
       backgroundColor: Colors.green,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(30),
       ),
       elevation: 8,
     ),
                child: Text("Submit",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _otpField(int index) {
    return TextFormField(
      controller: controllers[index],
      focusNode: focusNodes[index],
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(1),
      ],
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white, fontSize: 20),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue), // Highlight when focused
        ),
      ),
      onChanged: (value) {
        if (value.isNotEmpty && index < 5) {
          // Move focus to the next field
          FocusScope.of(context).requestFocus(focusNodes[index + 1]);
        }
      },
    );
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes to prevent memory leaks
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Function to generate a 6-digit OTP
  String generateOTP() {
    var rnd = Random();
    var otp = "";
    for (var i = 0; i < 6; i++) {
      otp += rnd.nextInt(9).toString();
    }
    return otp;
  }

  // Function to send OTP email
  Future<void> sendOTPEmail(String email, String otp) async {
    final smtpServer =
        gmail('rohansmauryasm@gmail.com', 'nzyh dgeg xhrc ihgq'); 

    final message = Message()
      ..from = Address(
          'rohansmauryasm@gmail.com', 'RohanMaurya') 
      ..recipients.add(email)
      ..subject = 'Your OTP for Verification'
      ..text = 'Your OTP is: $otp';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent.');
      print(e.toString());
      // Handle email sending error (e.g., show a SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error sending OTP email. Please try again.")));
    }
  }
}
