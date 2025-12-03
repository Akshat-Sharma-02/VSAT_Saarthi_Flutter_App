import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/auth_repository.dart';
import '../../../../core/theme/app_colors.dart';
import 'otp_screen.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  static const String routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isUsernameAvailable = true;
  bool _checkingUsername = false;
  bool _obscurePassword = true;

  List<String> _suggestions = [];
  String? _errorMessage;
  File? _imageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // PICK IMAGE
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // USERNAME CHECK
  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) return;

    setState(() => _checkingUsername = true);

    try {
      final result = await _authRepository.checkUsername(username);

      setState(() {
        _isUsernameAvailable = result['available'] ?? true;
        _suggestions = result['suggestions']?.cast<String>() ?? [];
      });
    } catch (_) {
      setState(() => _isUsernameAvailable = true);
    } finally {
      setState(() => _checkingUsername = false);
    }
  }

  // NORMAL SIGNUP → OTP
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isUsernameAvailable) {
      setState(() => _errorMessage = "Username already taken");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _authRepository.signup(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      final userId = res['userId'] ?? res['_id'];

      if (userId == null || userId.toString().isEmpty) {
        throw Exception("Invalid userId");
      }

      // TEMP SAVE DATA FOR OTP
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_name', _nameController.text.trim());
      await prefs.setString('temp_email', _emailController.text.trim());

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        OtpScreen.routeName,
        arguments: userId.toString(),
      );
    } catch (e) {
      setState(() => _errorMessage = "Signup failed. Try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // GOOGLE SIGNUP → DASHBOARD
  Future<void> _signupWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();

      if (account == null) {
        setState(() => _errorMessage = "Google sign-in cancelled");
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        setState(() => _errorMessage = "Google token error");
        return;
      }

      final res = await _authRepository.loginWithGoogleToken(idToken);

      final token = res['token'];
      final user = res['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('name', user['name'] ?? '');
      await prefs.setString('email', user['email'] ?? '');
      await prefs.setString('image', user['photo'] ?? '');

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        DashboardScreen.routeName,
        (_) => false,
      );
    } catch (e) {
      setState(() => _errorMessage = "Google signup failed.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // PROFILE IMAGE
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5EDFF),
                  border: Border.all(color: const Color(0xFF2962FF), width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: _imageFile == null
                      ? const Icon(Icons.person, size: 50)
                      : ClipOval(
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInputField(_nameController, 'Full Name', Icons.person),

                  const SizedBox(height: 16),

                  _buildInputField(
                    _usernameController,
                    'Username',
                    Icons.alternate_email,
                    onChanged: _checkUsername,
                    suffix: _checkingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator()),
                          )
                        : Icon(
                            _isUsernameAvailable ? Icons.check_circle : Icons.error,
                            color: _isUsernameAvailable ? Colors.green : Colors.red,
                          ),
                  ),

                  const SizedBox(height: 16),

                  _buildInputField(_phoneController, 'Phone', Icons.phone, type: TextInputType.phone),

                  const SizedBox(height: 16),

                  _buildInputField(_emailController, 'Email', Icons.mail, type: TextInputType.emailAddress),

                  const SizedBox(height: 16),

                  _buildInputField(
                    _passwordController,
                    'Password',
                    Icons.lock,
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Create Account"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _signupWithGoogle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icon/google_icon.png', width: 20),
                    const SizedBox(width: 10),
                    const Text("Sign up with Google"),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType type = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      keyboardType: type,
      validator: (v) => v == null || v.isEmpty ? "$label required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}