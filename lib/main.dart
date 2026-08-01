import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/supabase_config.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const NolatePartnerApp());
}

class NolatePartnerApp extends StatefulWidget {
  const NolatePartnerApp({super.key});

  @override
  State<NolatePartnerApp> createState() => _NolatePartnerAppState();
}

class _NolatePartnerAppState extends State<NolatePartnerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  // Method channel to receive deep links from iOS AppDelegate
  static const _channel = MethodChannel('supabase_auth_callback');

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleDeepLink);
  }

  Future<void> _handleDeepLink(MethodCall call) async {
    if (call.method == 'handleDeepLink') {
      final String? url = call.arguments as String?;
      if (url != null) {
        await Supabase.instance.client.auth.getSessionFromUrl(Uri.parse(url));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Nolate Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const MainLayout();
    }
    return const LoginScreen();
  }
}
