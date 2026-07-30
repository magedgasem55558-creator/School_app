import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // إضافة المكتبة

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false; // حالة خيار تذكرني

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // تحميل البيانات المحفوظة عند فتح الشاشة
  }

  // تحميل الإيميل المحفوظ
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('saved_email') ?? "";
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  // حفظ أو مسح البيانات
  Future<void> _handleRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      await _handleRememberMe(); // تنفيذ عملية الحفظ بعد النجاح

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في الدخول: ${e.toString()}")),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1590076215667-873d47343e06?q=80&w=2070'), fit: BoxFit.cover))),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: SingleChildScrollView( // لتجنب مشاكل المساحة عند ظهور الكيبورد
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("دخول أولياء الأمور", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  _buildTextField(_emailController, "البريد الإلكتروني", Icons.email),
                  const SizedBox(height: 15),
                  _buildTextField(_passwordController, "كلمة المرور", Icons.lock, obscure: true),
                  
                  // --- إضافة خيار تذكرني ---
                  Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.white70),
                    child: CheckboxListTile(
                      title: const Text("تذكرني", style: TextStyle(color: Colors.white70)),
                      value: _rememberMe,
                      activeColor: Colors.tealAccent,
                      checkColor: Colors.black,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) {
                        setState(() => _rememberMe = value ?? false);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  _isLoading 
                    ? const CircularProgressIndicator(color: Colors.tealAccent)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent[700], minimumSize: const Size(double.infinity, 50)),
                        onPressed: _login,
                        child: const Text("دخول", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}