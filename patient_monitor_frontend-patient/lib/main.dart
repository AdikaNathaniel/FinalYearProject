
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your pages
import 'login_appwrite.dart';
import 'call_home_page.dart'; // Make sure this exists or create it
import 'appwrite.dart'; // Adjust path if needed
import 'agora.dart'; // Adjust path if needed

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppwriteService()),
        ChangeNotifierProvider(create: (_) => AgoraService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Call App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        // Check if user is already logged in
        future: Provider.of<AppwriteService>(context, listen: false).getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else {
            // If user is logged in, go to Call Home, else show Login
            return snapshot.hasData ? const CallHomePage() : const LoginPage();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/call': (context) => const CallHomePage(),
      },
    );
  }
}