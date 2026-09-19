import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';
import 'main_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController(text: 'Apex Digital & Electronics Ltd.');
  final _usernameCtrl = TextEditingController(text: 'admin@apexdigital.in');
  final _passwordCtrl = TextEditingController(text: 'admin123');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() => _errorMessage = null);

      final company = _companyCtrl.text.trim();
      final username = _usernameCtrl.text.trim();
      final password = _passwordCtrl.text.trim();

      // Check credentials (Developer/Admin default credentials)
      if ((username == 'admin@apexdigital.in' || username == 'admin') && password == 'admin123') {
        ref.read(authProvider.notifier).login(company: company, username: username);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password. Please use developer/admin credentials.';
        });
      }
    }
  }

  void _fillDeveloperCredentials() {
    setState(() {
      _companyCtrl.text = 'Apex Digital & Electronics Ltd.';
      _usernameCtrl.text = 'admin@apexdigital.in';
      _passwordCtrl.text = 'admin123';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? QtColors.darkSurface : QtColors.lightSurface;
    final borderCol = isDark ? QtColors.darkBorder : QtColors.lightBorder;
    final headerBg = isDark ? QtColors.darkHeader : QtColors.lightHeader;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Qt Workbench Logo & Title Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? QtColors.darkAccent : QtColors.lightAccent).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? QtColors.darkAccent : QtColors.lightAccent, width: 2),
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: 44,
                  color: isDark ? QtColors.darkPrimary : QtColors.lightAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'GST BILLING WORKBENCH',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Qt Desktop Enterprise Invoicing System (v2.4)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Login Card Container
              Container(
                width: 440,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderCol, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Qt Title Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: headerBg,
                        border: Border(bottom: BorderSide(color: borderCol, width: 1)),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, size: 16, color: isDark ? QtColors.darkPrimary : QtColors.lightAccent),
                          const SizedBox(width: 8),
                          Text(
                            'STAFF / ADMIN SIGN IN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [


                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: QtColors.darkError.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: QtColors.darkError),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: QtColors.darkError, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(fontSize: 11, color: QtColors.darkError),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Company Name Field
                            TextFormField(
                              controller: _companyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Company Name *',
                                prefixIcon: Icon(Icons.business, size: 18),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Company name required' : null,
                            ),
                            const SizedBox(height: 14),

                            // Username Field
                            TextFormField(
                              controller: _usernameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Admin / Staff Username *',
                                prefixIcon: Icon(Icons.person, size: 18),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Username required' : null,
                            ),
                            const SizedBox(height: 14),

                            // Password Field
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password *',
                                prefixIcon: const Icon(Icons.key, size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Password required' : null,
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 14),

                            // Remember me Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: QtColors.darkAccent,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _rememberMe = val);
                                  },
                                ),
                                const Expanded(
                                  child: Text('Remember session on this browser', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: QtButton(
                                label: 'SIGN IN TO WORKBENCH',
                                icon: Icons.login,
                                isPrimary: true,
                                onPressed: _handleLogin,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'GST Billing System | Secured Admin Portal',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
