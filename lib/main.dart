import 'package:flutter/material.dart';
import 'data/services/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/chat_list/chat_list_screen.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final bool isLoggedIn = await AuthService.tryAutoLogin();
    runApp(MessengerApp(isLoggedIn: isLoggedIn));
}

class MessengerApp extends StatelessWidget {
    final bool isLoggedIn;
    const MessengerApp({super.key, required this.isLoggedIn});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Messenger',
            theme: ThemeData(
                useMaterial3: true,
                primarySwatch: Colors.blue,
                scaffoldBackgroundColor: const Color(0xFFF8F9FA),
                appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                    titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                ),
            ),
            home: isLoggedIn ? ChatListScreen() : LoginScreen(),
        );
    }
}