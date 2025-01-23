import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';
import '../widgets/background_painter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _signInWithGoogle() async {
  try {
    // Sign out from Google Sign-In (if already signed in)
    if (await GoogleSignIn().isSignedIn()) {
      await GoogleSignIn().signOut();
    }
    // Trigger the Google authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    if (googleAuth != null) {
      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Extract user data
      final User? user = userCredential.user;
      final String? displayName = user?.displayName;
      final String? email = user?.email;
      final String? phoneNumber = user?.phoneNumber;
      final String? photoURL = user?.photoURL;

      // Prepare user data to be passed to HomePage or stored directly
      final Map<String, dynamic> userData = {
        'uid': user?.uid,
        'fullName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
        'photoURL': photoURL,
        // Add other necessary fields
      };

      // Set logged-in status to true using shared_preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully logged in!")),
      );

      // Navigate to HomePage and remove the LoginPage from the stack
      Navigator.pushReplacementNamed(context, '/home', arguments: {'showSnackbar': true});

    } else {
      // Handle the case where googleAuth is null, perhaps by showing an error.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed.")),
      );
    }
  } on FirebaseAuthException catch (e) {
    print("Error signing in with Google: ${e.message}");
    String errorMessage = 'An error occurred. Please try again.';
    if (e.code == 'account-exists-with-different-credential') {
      errorMessage =
          'Account already exists with different credentials. Try another method.';
    } else if (e.code == 'invalid-credential') {
      errorMessage = 'Invalid Google credential.';
    } else if (e.code == 'user-disabled') {
      errorMessage = 'This user account has been disabled.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  } catch (e) {
    print("Error: ${e.toString()}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("An unexpected error occurred. Please try again.")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                        "Login",
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
                        "Email",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      focusNode: emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                      onTap: () {
                        emailFocusNode.requestFocus();
                      },
                    ),
                    SizedBox(height: 20),
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
                      focusNode: passwordFocusNode,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      onTap: () {
                        passwordFocusNode.requestFocus();
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
                              builder: (context) =>
                                  Center(child: CircularProgressIndicator()),
                            );

                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            // Sign in with email and password
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );

                            Navigator.of(context).pop(); // Dismiss loading indicator

                            // Navigate to AuthPage for OTP verification
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AuthPage(
                                  email: email,
                                  userData: {},
                                ),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            Navigator.of(context).pop();

                            print("Error logging in: ${e.message}");
                            String errorMessage =
                                'An error occurred. Please try again.';
                            if (e.code == 'user-not-found') {
                              errorMessage = 'User not found.';
                            } else if (e.code == 'wrong-password') {
                              errorMessage = 'Incorrect password.';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMessage)),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterPage()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: "Register",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      "Or sign up with",
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SocialButton(
                            backgroundColor: Colors.white,
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                            ),
                            label: "Google",
                            textStyle: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                            onPressed: () {
                              _signInWithGoogle();
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: SocialButton(
                            backgroundColor: Colors.white,
                            icon: Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue, // Blue circle
                              ),
                              child: Center(
                                child: Text(
                                  "f",
                                  style: TextStyle(
                                    color: Colors.white, // White "f"
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            label: "Facebook",
                            textStyle: TextStyle(
                              color: Colors.blue, // Blue text
                              fontSize: 16,
                            ),
                            onPressed: () {
                              // TODO: Implement Facebook Sign-In logic
                            },
                          ),
                        ),
                      ],
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

// Social Button Widget
class SocialButton extends StatelessWidget {
  final Color backgroundColor;
  final Widget icon;
  final String label;
  final TextStyle textStyle;
  final VoidCallback onPressed;

  const SocialButton({
    required this.backgroundColor,
    required this.icon,
    required this.label,
    required this.textStyle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          SizedBox(width: 8),
          Text(
            label,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}