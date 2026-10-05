import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/initial_connections.dart';
import 'models/user_connection.dart';
import 'services/notification_service.dart';
import 'widgets/status_bar.dart';
import 'widgets/terminal_header.dart';
import 'widgets/system_status.dart';
import 'widgets/connection_list.dart';
import 'widgets/command_terminal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI to immersive dark mode for terminal aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('> NOTIFICATION_SERVICE_INIT_ERROR: $e');
  }

  runApp(const NotiApp());
}

class NotiApp extends StatelessWidget {
  const NotiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTI — Terminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Colors.black,
          primary: Colors.white,
          onPrimary: Colors.black,
        ),
      ),
      home: const NotiHomeScreen(),
    );
  }
}

class NotiHomeScreen extends StatefulWidget {
  const NotiHomeScreen({super.key});

  @override
  State<NotiHomeScreen> createState() => _NotiHomeScreenState();
}

class _NotiHomeScreenState extends State<NotiHomeScreen> {
  List<UserConnection> _connections = List.from(initialConnections);
  String? _externalCommand;

  void _handleCallUser(String handle) {
    setState(() {
      _externalCommand = '/send_alert $handle';
    });
  }

  void _handleClearExternalCommand() {
    setState(() {
      _externalCommand = null;
    });
  }

  void _handleUpdateConnections(List<UserConnection> updated) {
    setState(() {
      _connections = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const StatusBarWidget(),
            const TerminalHeaderWidget(),
            SystemStatusWidget(totalConnections: _connections.length),
            ConnectionListWidget(
              connections: _connections,
              onCallUser: _handleCallUser,
            ),
            CommandTerminalWidget(
              connections: _connections,
              onUpdateConnections: _handleUpdateConnections,
              externalCommand: _externalCommand,
              onClearExternalCommand: _handleClearExternalCommand,
            ),
          ],
        ),
      ),
    );
  }
}
