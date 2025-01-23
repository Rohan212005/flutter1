import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'video_call.dart';
import '../widgets/background_painter.dart';
import 'package:random_string/random_string.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoginSnackBar(context);
    });
  }

  void _showLoginSnackBar(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final showSnackbar = arguments?['showSnackbar'] as bool?;
    if (showSnackbar == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF212121),
            title: const Text("Exit App", style: TextStyle(color: Colors.white)),
            content: const Text(
              "Are you sure you want to exit?",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("No", style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text("Yes", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Home"),
          backgroundColor: const Color(0xFF212121),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 0.0),
              child: PopupMenuButton<String>(
                color: const Color(0xFF212121),
                onSelected: (value) async {
                  if (value == 'logout') {
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF212121),
                        title: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          "Are you sure you want to log out?",
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              "Logout",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _signOut(context);
                    }
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'settings',
                      child:
                          Text("Settings", style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text("Logout", style: TextStyle(color: Colors.white)),
                    ),
                  ];
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    backgroundColor: Color(0xFF212121),
                    foregroundColor: Colors.white,
                    radius: 16,
                    child: Icon(
                      Icons.account_circle,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: BackgroundPainter(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _joinCall(context);
                        },
                        child: const Text("Join a Call",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _createCall(context);
                        },
                        child: const Text("Create a Call",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
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

  Future<void> _signOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();

    
    await GoogleSignIn().signOut();

    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushReplacementNamed(context, '/login');
  } catch (e) {
    print("Error signing out: ${e.toString()}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error signing out. Please try again.")),
    );
  }
}

  void _createCall(BuildContext context) {
    String roomId = randomAlphaNumeric(8);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text("Your Room ID", style: TextStyle(color: Colors.white)),
          content: Text(roomId, style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallPage(
                      uid: 1,
                      roomId: roomId, // Pass the generated room ID
                    ),
                  ),
                );
              },
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: roomId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Room ID copied to clipboard")),
                );
              },
              child: const Text("Copy", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _joinCall(BuildContext context) {
    String roomId = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text("Enter Room ID", style: TextStyle(color: Colors.white)),
          content: TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              roomId = value;
            },
            decoration: const InputDecoration(
              hintText: "Room ID",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallPage(
                      uid: 2,
                      roomId: roomId, // Pass the entered room ID
                    ),
                  ),
                );
              },
              child: const Text("Join", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
