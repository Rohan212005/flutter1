// password_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_page.dart';
import '../widgets/background_painter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordPage extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const PasswordPage({Key? key, required this.registrationData}) : super(key: key);

  @override
  _PasswordPageState createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String passwordStrength = '';
  double strengthLevel = 0.0;
  bool isPasswordFieldFocused = false;

  void _checkPasswordStrength(String password) {
    setState(() {
      if (password.length >= 12 &&
          password.contains(RegExp(r'[A-Z]')) &&
          password.contains(RegExp(r'[0-9]')) &&
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        passwordStrength = 'Very Strong';
        strengthLevel = 1.0;
      } else if (password.length >= 8 &&
          password.contains(RegExp(r'[A-Z]')) &&
          password.contains(RegExp(r'[0-9]'))) {
        passwordStrength = 'Strong';
        strengthLevel = 0.75;
      } else if (password.length >= 6) {
        passwordStrength = 'Weak';
        strengthLevel = 0.5;
      } else {
        passwordStrength = 'Very Weak';
        strengthLevel = 0.25;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(painter: BackgroundPainter(), child: Container()),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 120.0),
                      child: Text(
                        "Set Password",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Password",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: _checkPasswordStrength,
                      onTap: () => setState(() {
                        isPasswordFieldFocused = true;
                      }),
                      onFieldSubmitted: (_) => setState(() {
                        isPasswordFieldFocused = false;
                      }),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    if (isPasswordFieldFocused) ...[
                      SizedBox(height: 10),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         
                          Container(
                            height: 10,
                            width: MediaQuery.of(context).size.width * 1,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: strengthLevel,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Color.lerp(Colors.red, Colors.green, strengthLevel),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          
                          Text(
                            passwordStrength,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 20),
                   
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Confirm Password",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Confirm your password',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                   
                    ElevatedButton(
    onPressed: () async {
      if (_formKey.currentState!.validate()) {
        try {
     
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(child: CircularProgressIndicator()),
          );

      
          final password = passwordController.text.trim();

         
          final fullName = widget.registrationData['fullName'] as String;
          final email = widget.registrationData['email'] as String;
          final phoneNumber = widget.registrationData['phoneNumber'] as String;
          final gender = widget.registrationData['gender'] as String;
          final dob = widget.registrationData['birthDate'] as DateTime?;

      
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

   
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'fullName': fullName,
            'email': email,
            'phoneNumber': phoneNumber,
            'gender': gender,
            'dob': dob,
            'uid': userCredential.user!.uid // Store the user ID
          });

         
          Navigator.of(context).pop(); // Dismiss loading indicator
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuthPage(
                email: email,
                userData: {
                  'uid': userCredential.user!.uid
                }, // Pass user ID to AuthPage
              ),
            ),
          );
        } on FirebaseAuthException catch (e) {
          Navigator.of(context).pop();
          print("Error: ${e.message}");
          String errorMessage = 'An error occurred. Please try again.';
          if (e.code == 'weak-password') {
            errorMessage = 'The password provided is too weak.';
          } else if (e.code == 'email-already-in-use') {
            errorMessage = 'The account already exists for that email.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } catch (e) {
          Navigator.of(context).pop();
          print("Error: ${e.toString()}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "An unexpected error occurred. Please try again.")),
          );
        }
      }
    },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        "Submit",
                        style: TextStyle(fontSize: 18, color: Colors.white),
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
