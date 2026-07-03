import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'utils/theme.dart';

class LottoProApp extends StatelessWidget {
  const LottoProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LottoPro Manager',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const LoginScreen(),
    );
  }
}
