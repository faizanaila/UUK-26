import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/utils/app_color.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final classController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final adminCodeController = TextEditingController();

  String selectedRole = 'student';
  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> register() async {
    final name = nameController.text.trim();
    final kelas = classController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final adminCode = adminCodeController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage('Semua form wajib diisi');
      return;
    }

    if (selectedRole == 'student' && kelas.isEmpty) {
      showMessage('Kelas wajib diisi');
      return;
    }

    if (selectedRole == 'admin' && adminCode != 'LABADMIN2026') {
      showMessage('Kode admin salah');
      return;
    }

    if (password.length < 6) {
      showMessage('Password minimal 6 karakter');
      return;
    }

    setState(() {
      isLoading = true;
    });

    User? createdUser;

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('Akun gagal dibuat');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set({
            'user_id': createdUser.uid,
            'name': name,
            'email': email,
            'kelas': selectedRole == 'student' ? kelas : '-',
            'role': selectedRole,
            'foto': '',
            'created_at': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      showMessage('Registrasi berhasil!');

      // Tidak perlu navigasi manual.
      // AuthGate akan mendeteksi akun yang sudah login.
    } on FirebaseAuthException catch (e) {
      if (createdUser != null) {
        try {
          await createdUser!.delete();
        } catch (_) {}
      }

      String message = 'Registrasi gagal';

      if (e.code == 'email-already-in-use') {
        message = 'Email sudah digunakan';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      } else if (e.code == 'network-request-failed') {
        message = 'Periksa koneksi internet';
      }

      if (mounted) showMessage(message);
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser!.delete();
        } catch (_) {}
      }

      if (mounted) {
        showMessage('Gagal menyimpan profil ke Firebase: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    nameController.dispose();
    classController.dispose();
    emailController.dispose();
    passwordController.dispose();
    adminCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.cream,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: AppColor.dark,
        foregroundColor: AppColor.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppColor.dark,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Daftar untuk menggunakan LAB THINGS'),
            const SizedBox(height: 25),

            const Text(
              'Daftar sebagai',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            RadioListTile<String>(
              title: const Text('Siswa'),
              value: 'student',
              groupValue: selectedRole,
              activeColor: AppColor.red,
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
            ),

            RadioListTile<String>(
              title: const Text('Admin'),
              value: 'admin',
              groupValue: selectedRole,
              activeColor: AppColor.red,
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
            ),

            const SizedBox(height: 12),

            buildInput(
              controller: nameController,
              label: 'Nama Lengkap',
              icon: Icons.person_outline,
            ),

            if (selectedRole == 'student') ...[
              const SizedBox(height: 15),
              buildInput(
                controller: classController,
                label: 'Kelas',
                icon: Icons.school_outlined,
              ),
            ],

            if (selectedRole == 'admin') ...[
              const SizedBox(height: 15),
              buildInput(
                controller: adminCodeController,
                label: 'Kode Admin',
                icon: Icons.admin_panel_settings_outlined,
              ),
            ],

            const SizedBox(height: 15),

            buildInput(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: AppColor.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.red,
                  foregroundColor: AppColor.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: AppColor.white)
                    : const Text(
                        'Register',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColor.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
