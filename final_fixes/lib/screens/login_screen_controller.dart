import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/home_screen.dart';

class LoginScreenController extends StatefulWidget {
  const LoginScreenController({super.key});

  @override
  State<LoginScreenController> createState() => _LoginScreenControllerState();
}

class _LoginScreenControllerState extends State<LoginScreenController> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // التحقق من دعم المصادقة بالبصمة
    final canAuthenticate = await userProvider.isBiometricAvailable();
    
    if (!canAuthenticate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المصادقة بالبصمة غير متاحة على هذا الجهاز')),
        );
      }
      return;
    }
    
    // محاولة تسجيل الدخول بالبصمة
    final success = await userProvider.signInWithBiometrics();
    
    if (success) {
      if (mounted) {
        // الانتقال إلى الشاشة الرئيسية
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تسجيل الدخول بالبصمة')),
        );
      }
    }
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final success = await userProvider.signIn(
        _emailController.text,
        _passwordController.text,
        _rememberMe,
      );
      
      if (success) {
        if (mounted) {
          // الانتقال إلى الشاشة الرئيسية
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تسجيل الدخول. تحقق من البريد الإلكتروني وكلمة المرور')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شعار التطبيق
                Image.asset(
                  'assets/logo.jpg',
                  height: 120,
                ),
                const SizedBox(height: 24),
                
                // عنوان الشاشة
                const Text(
                  'مرحباً بك في فريق الأنصار',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'الرجاء تسجيل الدخول للمتابعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                
                // نموذج تسجيل الدخول
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // حقل البريد الإلكتروني
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال البريد الإلكتروني';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // حقل كلمة المرور
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كلمة المرور';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // خيار تذكرني
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                          ),
                          const Text('تذكرني'),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // في التطبيق الفعلي، سيتم هنا الانتقال إلى شاشة استعادة كلمة المرور
                            },
                            child: const Text('نسيت كلمة المرور؟'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // زر تسجيل الدخول
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return ElevatedButton(
                            onPressed: userProvider.isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: userProvider.isLoading
                                ? const CircularProgressIndicator()
                                : const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // زر المصادقة بالبصمة
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return OutlinedButton.icon(
                            onPressed: userProvider.isLoading ? null : _authenticateWithBiometrics,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('تسجيل الدخول بالبصمة'),
                          );
                        },
                      ),
                    ],
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
