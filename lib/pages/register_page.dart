import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'password_page.dart';
import '../widgets/background_painter.dart';

// Global variable to store temporary registration data
Map<String, dynamic> tempRegistrationData = {};

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String gender = 'Male';
  DateTime? birthDate;
  Map<String, bool> fieldValidationStatus = {};

  final List<Map<String, String>> countryCodes = [
    {'code': '+1', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': '+91', 'name': 'India', 'flag': '🇮🇳'},
  ];

  String selectedCountryCode = '+91'; // Changed to +91
  String selectedCountryName = 'India'; // Changed to India
  String selectedFlag = '🇮🇳'; // Changed to India flag

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomPaint(painter: BackgroundPainter(), child: Container()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Full Name Field
                  _buildLabel("Full Name"),
                  _buildTextFormField(
                    controller: fullNameController,
                    hintText: 'Enter your full name',
                    fieldKey: 'fullName',
                    validator: (value) {
                      if (fieldValidationStatus['fullName'] == true && (value == null || value.isEmpty)) {
                        return 'Enter your name';
                      }
                      return null;
                    },
                  ),

                  // Email Field
                  _buildLabel("Email"),
                  _buildTextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'Enter your email',
                    fieldKey: 'email',
                    validator: (value) {
                      if (fieldValidationStatus['email'] == true) {
                        if (value == null || value.isEmpty) {
                          return 'Enter an email address';
                        }
                        if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),

                  // Phone Number Field
                  _buildLabel("Phone Number"),
                  _buildPhoneNumberField(),

                  // Gender Field
                  _buildLabel("Gender"),
                  _buildGenderDropdown(),

                  // Date of Birth Field
                  _buildLabel("Date of Birth"),
                  _buildDateOfBirthField(),

                  SizedBox(height: 20),
                  // Submit Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Set all fields to be validated
                        setState(() {
                          fieldValidationStatus = {
                            'fullName': true,
                            'email': true,
                            'phone': true,
                            'gender': true,
                            'birthDate': true,
                          };
                        });

                        // Validate all fields
                        if (_formKey.currentState!.validate()) {
                          // Combine country code and phone number
                          String fullPhoneNumber = '$selectedCountryCode${phoneController.text}';

                          // Store user data in the global variable
                          tempRegistrationData = {
                            'fullName': fullNameController.text.trim(),
                            'email': emailController.text.trim(),
                            'phoneNumber': fullPhoneNumber,
                            'gender': gender,
                            'birthDate': birthDate,
                          };

                          try {
                            final email = tempRegistrationData['email'] as String;
                            final phoneNumber = tempRegistrationData['phoneNumber'] as String;

                            // Check if email already exists
                            final QuerySnapshot emailQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('email', isEqualTo: email)
                                .get();

                            if (emailQuery.docs.isNotEmpty) {
                              // Email already exists
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("An account with this email already exists.")),
                              );
                              return; // Prevent further registration
                            }

                            // Check if phone number already exists
                            final QuerySnapshot phoneQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('phoneNumber', isEqualTo: phoneNumber)
                                .get();

                            if (phoneQuery.docs.isNotEmpty) {
                              // Phone number already exists
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("An account with this phone number already exists.")),
                              );
                              return; // Prevent further registration
                            }

                            // Navigate to PasswordPage (no data saving here)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PasswordPage(
                                  registrationData: tempRegistrationData,
                                ),
                              ),
                            );
                          } on FirebaseException catch (e) {
                            // Handle Firestore errors (e.g., show a SnackBar)
                            print("Error checking for duplicates: ${e.message}");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error registering user. Please try again.")),
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
                        "Register",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                  // Login Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Log in",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    TextInputType? keyboardType,
    required String hintText,
    required String fieldKey,
    required String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          errorStyle: TextStyle(height: 0.5),
        ),
        validator: validator,
        onTap: () {
          // Clear validation status for this field when user starts editing
          setState(() {
            fieldValidationStatus[fieldKey] = false;
          });
        },
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCountryCodePicker(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              height: 55,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Text(
                    selectedFlag,
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(width: 8),
                  Text(selectedCountryCode, style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                errorStyle: TextStyle(height: 0.5),
              ),
              validator: (value) {
                if (fieldValidationStatus['phone'] == true && (value == null || value.isEmpty || value.length < 10)) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
              onTap: () {
                setState(() {
                  fieldValidationStatus['phone'] = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: DropdownButtonFormField<String>(
        value: gender,
        style: TextStyle(color: Colors.white),
        dropdownColor: Colors.grey[900],
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          errorStyle: TextStyle(height: 0.5),
        ),
        items: <String>['Male', 'Female', 'Other', 'Prefer not to say']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(color: Colors.white, fontSize: 16)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            gender = value!;
            fieldValidationStatus['gender'] = false;
          });
        },
        validator: (value) {
          if (fieldValidationStatus['gender'] == true && (value == null || value.isEmpty)) {
            return 'Please select a gender';
          }
          return null;
        },
        menuMaxHeight: 200,
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: birthDate == null ? '' : '${birthDate!.toLocal()}'.split(' ')[0],
        ),
        onTap: () async {
          setState(() {
            fieldValidationStatus['birthDate'] = false;
          });

          DateTime? selectedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );

          if (selectedDate != null && selectedDate != birthDate) {
            setState(() {
              birthDate = selectedDate;
            });
          }
        },
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Select your birth date',
          hintStyle: TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          errorStyle: TextStyle(height: 0.5),
        ),
        validator: (value) {
          if (fieldValidationStatus['birthDate'] == true && birthDate == null) {
            return 'Enter your birth date';
          }
          return null;
        },
      ),
    );
  }

  void _showCountryCodePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: ListView.builder(
            itemCount: countryCodes.length,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () {
                  setState(() {
                    selectedCountryCode = countryCodes[index]['code']!;
                    selectedCountryName = countryCodes[index]['name']!;
                    selectedFlag = countryCodes[index]['flag']!;
                  });
                  Navigator.pop(context);
                },
                leading: Text(
                  countryCodes[index]['flag']!,
                  style: TextStyle(fontSize: 24),
                ),
                title: Text(
                  countryCodes[index]['name']!,
                  style: TextStyle(color: Colors.black),
                ),
                subtitle: Text(
                  countryCodes[index]['code']!,
                  style: TextStyle(color: Colors.black54),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}