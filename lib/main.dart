import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'role_selector.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
void main() => runApp(AIzCareApp());
class AIzCareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIzCare',
      theme: ThemeData(
        textTheme:GoogleFonts.acmeTextTheme(),
        scaffoldBackgroundColor: Color(0xFFF7F6FB),
        colorSchemeSeed: Colors.black54,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: RoleSelectorScreen(),
    );
  }
}
