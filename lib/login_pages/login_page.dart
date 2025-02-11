import 'package:busbuddy/main.dart'; // Import the main.dart file
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busbuddy/app1/main.dart' as app1;
import 'package:busbuddy/app2/main.dart' as app2;
import 'package:busbuddy/app3/main.dart' as app3;

class BusBuddyLoginPage extends StatefulWidget {
  const BusBuddyLoginPage({Key? key}) : super(key: key);

  @override
  _BusBuddyLoginPageState createState() => _BusBuddyLoginPageState();
}

class _BusBuddyLoginPageState extends State<BusBuddyLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  // Check if the user is already logged in
  void _checkCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        int userLevel = userDoc.get('level');
        // Navigate to the appropriate app based on user level
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _launchApp(userLevel), // Updated here
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        height: screenHeight,
        width: screenWidth,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff073358), Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: SingleChildScrollView(
            child: BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.1),
                    _buildTitle(screenWidth),
                    SizedBox(height: screenHeight * 0.03),
                    _buildSubtitle(),
                    SizedBox(height: screenHeight * 0.03),
                    _buildTextField(
                      label: 'Email Address',
                      controller: emailController,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    _buildPasswordField(
                      controller: passwordController,
                      isPasswordVisible: state.isPasswordVisible,
                      toggleVisibility: () => context
                          .read<LoginBloc>()
                          .add(TogglePasswordVisibility()),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text('Forgot Password?',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    _buildActionButton(context, screenHeight),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleForgotPassword() async {
    final String email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset email sent. Check your inbox.')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message ?? 'An error occurred. Please try again.')),
      );
    }
  }

  Widget _buildTitle(double screenWidth) {
    return Center(
      child: Text(
        'Sign In',
        style: TextStyle(
          fontSize: screenWidth * 0.08,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome!!!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        const Text(
          "Enter your Email address and Password to sign in. Enjoy your journey!",
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Color.fromARGB(153, 0, 0, 0)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        hintStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(138, 255, 255, 255)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isPasswordVisible,
    required VoidCallback toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isPasswordVisible,
      style: const TextStyle(color: Color.fromARGB(153, 0, 0, 0)),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(color: Colors.white),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(138, 255, 255, 255)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    double screenHeight,
  ) {
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.07,
      child: ElevatedButton(
        onPressed: () async {
          // Handle sign-in logic
          try {
            UserCredential userCredential =
                await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );

            User? user = userCredential.user;
            if (user != null) {
              // Fetch user data from Firestore
              DocumentSnapshot userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
              if (userDoc.exists) {
                int userLevel = userDoc.get('level');
                // Navigate to the appropriate app based on user level
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _launchApp(userLevel), // Updated here
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User data not found")),
                );
              }
            }
          } on FirebaseAuthException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(e.message ?? "Sign-in failed. Please try again.")),
            );
          }
        },
        child: const Text(
          'Sign In',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  // Navigate to the appropriate app based on user level
  Widget _launchApp(int userLevel) {
    switch (userLevel) {
      case 1:
        return app1.Level1app();
      case 2:
        return app2.Level2app();
      case 3:
        return app3.Level3app();
      default:
        return Scaffold(
          body: Center(child: Text('Invalid User Level')),
        );
    }
  }
}
