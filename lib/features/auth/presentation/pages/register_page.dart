import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _usernameFocusNode = FocusNode();

  String? _businessType;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _checkingUsername = false;
  String? _usernameAvailabilityError;

  static const _businessTypes = [
    'Warung/Toko Kelontong',
    'Kuliner/Makanan',
    'Fashion/Pakaian',
    'Elektronik',
    'Jasa',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onUsernameFocusChange);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _storeNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode
      ..removeListener(_onUsernameFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onUsernameFocusChange() {
    if (!_usernameFocusNode.hasFocus) {
      _checkUsernameAvailability();
    }
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.length < 4 ||
        !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return; // Sync validator handles these cases
    }
    setState(() {
      _checkingUsername = true;
      _usernameAvailabilityError = null;
    });
    try {
      final available =
          await getIt<AuthRemoteDataSource>().isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          _checkingUsername = false;
          _usernameAvailabilityError =
              available ? null : 'Username sudah digunakan. Coba yang lain.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingUsername = false);
    }
  }

  void _submit() {
    // Force re-validate to pick up async username error
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_usernameAvailabilityError != null) return;
    if (_checkingUsername) return;

    context.read<AuthBloc>().add(
          RegisterSubmitted(
            RegisterParams(
              fullName: _fullNameController.text.trim(),
              username: _usernameController.text.trim(),
              storeName: _storeNameController.text.trim(),
              businessType: _businessType!,
              phone: _phoneController.text.trim(),
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              password: _passwordController.text,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        leading: const BackButton(),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            final messenger = ScaffoldMessenger.of(context);
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content:
                      Text('Selamat datang, ${state.user.storeName}!'),
                  backgroundColor: colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            Navigator.of(context).pop();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Nama Lengkap ────────────────────────────────────────
                _buildField(
                  controller: _fullNameController,
                  label: 'Nama Lengkap Pemilik',
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    if (v.trim().length < 3) {
                      return 'Nama minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Username ────────────────────────────────────────────
                TextFormField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.nunito(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    constraints: const BoxConstraints(minHeight: 56),
                    suffixIcon: _checkingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_usernameAvailabilityError == null &&
                                _usernameController.text.length >= 4)
                            ? const Icon(Icons.check_circle_outline,
                                color: Colors.green)
                            : null,
                    errorText: _usernameAvailabilityError,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Username wajib diisi';
                    }
                    if (v.trim().length < 4) {
                      return 'Username minimal 4 karakter';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Hanya boleh huruf, angka, dan underscore (_)';
                    }
                    if (_usernameAvailabilityError != null) {
                      return _usernameAvailabilityError;
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_usernameAvailabilityError != null) {
                      setState(() => _usernameAvailabilityError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // ── Nama Toko ───────────────────────────────────────────
                _buildField(
                  controller: _storeNameController,
                  label: 'Nama Toko / Usaha',
                  icon: Icons.storefront_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama toko wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Jenis Usaha ─────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _businessType,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    color: colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Jenis Usaha',
                    prefixIcon: Icon(Icons.category_outlined),
                    constraints: BoxConstraints(minHeight: 56),
                  ),
                  items: _businessTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type,
                                style: GoogleFonts.nunito(fontSize: 16)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _businessType = value),
                  validator: (v) =>
                      v == null ? 'Jenis usaha wajib dipilih' : null,
                ),
                const SizedBox(height: 16),

                // ── Nomor HP ────────────────────────────────────────────
                _buildField(
                  controller: _phoneController,
                  label: 'Nomor HP (08xx...)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nomor HP wajib diisi';
                    }
                    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                    if (!v.trim().startsWith('08')) {
                      return 'Nomor HP harus diawali 08';
                    }
                    if (digits.length < 10 || digits.length > 13) {
                      return 'Nomor HP harus 10–13 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Email (Opsional) ────────────────────────────────────
                _buildField(
                  controller: _emailController,
                  label: 'Email (opsional)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final emailRegex =
                          RegExp(r'^[\w.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z]+$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Format email tidak valid';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Kata Sandi ──────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.nunito(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    constraints: const BoxConstraints(minHeight: 56),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                    if (v.length < 6) return 'Kata sandi minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Konfirmasi Kata Sandi ───────────────────────────────
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.nunito(fontSize: 18),
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Kata Sandi',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    constraints: const BoxConstraints(minHeight: 56),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Konfirmasi kata sandi wajib diisi';
                    }
                    if (v != _passwordController.text) {
                      return 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Daftar Button ───────────────────────────────────────
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Daftar Sekarang',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      style: GoogleFonts.nunito(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        constraints: const BoxConstraints(minHeight: 56),
      ),
      validator: validator,
    );
  }
}
