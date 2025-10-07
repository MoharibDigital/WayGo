import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // For sign up
  final TextEditingController _carTypeController = TextEditingController();
  final TextEditingController _carPlateController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isSignUp = false; // Toggle between login and signup
  String _userType = 'customer'; // 'driver' or 'customer'

  void _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // تحقق وهمي فقط
    await Future.delayed(const Duration(seconds: 1));
    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
      // إذا كان آخر نوع مستخدم هو سائق أو زبون، احفظه (للتجربة، اجعلها زبون افتراضياً)
      await prefs.setString('user_type', 'customer');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _error = AppLocalizations.of(context)!.pleaseEnterEmailPassword;
        _isLoading = false;
      });
    }
  }

  void _signUp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty && (_userType == 'customer' || (_carTypeController.text.isNotEmpty && _carPlateController.text.isNotEmpty && _carColorController.text.isNotEmpty))) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
      await prefs.setString('user_type', _userType);
      await prefs.setString('user_email', _emailController.text.trim());
      // إضافة بيانات المستخدم إلى Firestore
      final userData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'userType': _userType,
        if (_userType == 'driver')
          'car': {
            'type': _carTypeController.text.trim(),
            'plate': _carPlateController.text.trim(),
            'color': _carColorController.text.trim(),
          },
        'createdAt': FieldValue.serverTimestamp(),
      };
      try {
        await FirebaseFirestore.instance.collection('users').add(userData);
      } catch (e) {
        print('Firestore error: ' + e.toString());
        setState(() {
          _error = AppLocalizations.of(context)!.errorSavingData;
          _isLoading = false;
        });
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _error = AppLocalizations.of(context)!.pleaseFillAllFields;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _carTypeController.dispose();
    _carPlateController.dispose();
    _carColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF1976D2), // Blue
              Color(0xFF64B5F6), // Light Blue
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: const Icon(Icons.directions_car, size: 72, color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 32),
                Text(
                  _isSignUp ? l10n.createNewAccount : l10n.signIn,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Colors.white.withOpacity(0.90),
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        if (_isSignUp)
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: l10n.name,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        if (_isSignUp) const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.95),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.95),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        if (_isSignUp)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: DropdownButtonFormField<String>(
                                  value: _userType,
                                  decoration: InputDecoration(
                                    labelText: l10n.accountType,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    prefixIcon: const Icon(Icons.person_outline),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.95),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'customer',
                                      child: Text(l10n.customer),
                                    ),
                                    DropdownMenuItem(
                                      value: 'driver',
                                      child: Text(l10n.driver),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _userType = val!;
                                    });
                                  },
                                ),
                              ),
                              if (_userType == 'driver') ...[
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _carTypeController,
                                  decoration: InputDecoration(
                                    labelText: l10n.carType,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    prefixIcon: const Icon(Icons.directions_car),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _carPlateController,
                                  decoration: InputDecoration(
                                    labelText: l10n.carPlate,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    prefixIcon: const Icon(Icons.confirmation_number),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _carColorController,
                                  decoration: InputDecoration(
                                    labelText: l10n.carColor,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    prefixIcon: const Icon(Icons.color_lens),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 16),
                        if (_error != null)
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2), // Blue
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _isLoading ? null : (_isSignUp ? _signUp : _login),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(_isSignUp ? l10n.signUp : l10n.signIn, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _error = null;
                                  });
                                },
                          child: Text(
                            _isSignUp ? l10n.alreadyHaveAccount : l10n.dontHaveAccount,
                            style: const TextStyle(fontSize: 16, color: Color(0xFF1976D2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
