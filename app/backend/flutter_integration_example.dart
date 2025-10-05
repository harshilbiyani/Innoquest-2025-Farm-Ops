// Example Flutter integration for FarmOps Backend API
// Add this to your Flutter project

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  // Change this based on your platform:
  // - For Android Emulator: http://10.0.2.2:5000
  // - For iOS Simulator: http://localhost:5000
  // - For Physical Device: http://YOUR_COMPUTER_IP:5000
  static const String baseUrl = 'http://10.0.2.2:5000';

  Future<void> _login() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _message = 'Please enter your mobile phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final url = Uri.parse('$baseUrl/api/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mobile_phone': _phoneController.text.trim()}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Login successful
        setState(() {
          _message =
              'Login successful! Welcome ${data['user']['mobile_phone']}';
          _isLoading = false;
        });

        // Navigate to home page or save user data
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        // Login failed
        setState(() {
          _message = data['message'] ?? 'Login failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message =
            'Error: Unable to connect to server. Make sure backend is running.';
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FarmOps Login'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo or App Name
            const Icon(Icons.agriculture, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Welcome to FarmOps',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Phone Number Input
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Login Button
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),

            // Message Display
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message.contains('successful')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.contains('successful')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message.contains('successful')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}

// Don't forget to add http package to pubspec.yaml:
// dependencies:
//   http: ^1.1.0
