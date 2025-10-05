import 'package:flutter/material.dart';
import '../chatbot_page.dart';
import '../profile_page.dart';
import '../home_page.dart';
import 'voice_navigation_button.dart';

class BottomNavBar extends StatelessWidget {
  final String currentPage;
  final String? mobileNumber;

  const BottomNavBar({super.key, required this.currentPage, this.mobileNumber});

  void _showVoiceNavigationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: VoiceNavigationButton(mobileNumber: mobileNumber),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFE2FCE1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Profile Icon
          IconButton(
            icon: Image.asset(
              'assets/images/profile.png',
              width: 28,
              height: 28,
              color: currentPage == 'profile' ? const Color(0xFF2BC24A) : null,
            ),
            onPressed: () {
              if (currentPage != 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
            },
          ),

          // Center Icon - Mic for home page, Home icon for other pages
          IconButton(
            icon: currentPage == 'home'
                ? const Icon(Icons.mic, size: 32, color: Color(0xFF008575))
                : Image.asset('assets/images/Home.png', width: 28, height: 28),
            onPressed: () {
              if (currentPage == 'home') {
                // Show voice navigation dialog on home page
                _showVoiceNavigationDialog(context);
              } else {
                // Navigate to home page from other pages
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        HomePage(mobileNumber: mobileNumber ?? ''),
                  ),
                  (route) => false,
                );
              }
            },
          ),

          // Chatbot Icon
          IconButton(
            icon: Image.asset(
              'assets/images/chatbot.png',
              width: 28,
              height: 28,
              color: currentPage == 'chatbot' ? const Color(0xFF2BC24A) : null,
            ),
            onPressed: () {
              if (currentPage != 'chatbot') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ChatbotPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
