import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(); 
  bool isLoading = false;

  Future<void> handleLogin() async {
    setState(() => isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (!email.endsWith('@vit.edu') && !email.endsWith('@infosys.com')) {
      _showError("Access Denied: Only @vit.edu or @infosys.com allowed.");
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      _showError("Please enter a valid phone number (e.g., 9198...)");
      return;
    }

    try {
      AuthResponse response;
      try {
        response = await Supabase.instance.client.auth.signUp(email: email, password: password);
        if (response.user != null) {
          await Supabase.instance.client.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'organization_domain': email.split('@')[1],
            'full_name': email.split('@')[0],
            'phone': phone, 
          });
        }
      } catch (e) {
        response = await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RoleSelectionPage()));
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView( 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 20),
                const Text("Route-Roots", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text("Verified Carpooling Only", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Organization Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 10),
                TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Phone (e.g., 919922...)", hintText: "Include Country Code (91)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 10),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
                const SizedBox(height: 20),
                isLoading ? const CircularProgressIndicator() : ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white), onPressed: handleLogin, child: const Text("Enter Safe Space")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}