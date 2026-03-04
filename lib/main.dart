import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/constants/supabase_config.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/settings/presentation/bloc/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await configureDependencies();

  runApp(const UmkmKuApp());
}

class UmkmKuApp extends StatelessWidget {
  const UmkmKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => getIt<ThemeCubit>()..loadTheme(),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'UMKM Ku',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: BlocBuilder<AuthBloc, AuthState>(
              // Only rebuild on meaningful auth-state transitions;
              // AuthLoading during login/register is handled within pages.
              buildWhen: (previous, current) =>
                  current is AuthAuthenticated ||
                  current is AuthUnauthenticated ||
                  current is AuthInitial ||
                  (current is AuthError && previous is! AuthAuthenticated),
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return const HomePage();
                }
                if (state is AuthInitial) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                // AuthUnauthenticated | AuthError (failed session restore)
                return const LoginPage();
              },
            ),
          );
        },
      ),
    );
  }
}
