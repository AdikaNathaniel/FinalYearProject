import 'package:flutter/material.dart';
import 'package:patient_monitor/pregnancy-chatbot.dart';
import 'login_page.dart';
import 'otp_page.dart';
import 'health_metrics.dart';
import 'predictions.dart';
import 'create_cancel-appointment.dart';
import 'view-appointment.dart';
import 'wellness-page.dart';
import 'protein-strip.dart';
import 'users_summary.dart';
import 'pregnancy-calculator.dart';
import 'pregnancy-chatbot.dart';
import 'real-time-chat.dart';
import 'doctor-chat.dart';
import 'pregnant-woman-chat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PregMonitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //  home:  WellnessTipsScreen(userEmail: 'example@example.com'),
      // home: CreateCancelAppointmentPage(),
      //  home: ViewAppointmentsPage(),
      // home: UserListPage(),
       home: LoginPage(),
      //  home: PregnantWomanChatPage(),
      // home:  PregnancyCalculatorScreen(),
      // home: UrineStripColorSelector(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}



 //  home: const LoginPage(),
//  home : PregnancyComplicationsPage(),
  // home: const LoginPage(),