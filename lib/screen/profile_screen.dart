import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/utils/app_color.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String formatDate(dynamic date) {
    if (date == null) {
      return '-';
    }

    try {
      DateTime tanggal;

      if (date is Timestamp) {
        tanggal = date.toDate();
      } else {
        tanggal = DateTime.parse(date.toString());
      }

      return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
    } catch (e) {
      return '-';
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate otomatis mengarahkan ke LoginScreen.
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal logout: $e'),
          backgroundColor: AppColor.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Pengguna belum login')));
    }

    return Scaffold(
      backgroundColor: AppColor.cream,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.dark,
        foregroundColor: AppColor.white,
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat profil'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data profil belum tersedia'));
          }

          final data = snapshot.data!.data()!;

          final String name = data['name'] ?? 'Pengguna';
          final String kelas = data['kelas'] ?? '-';
          final String email = data['email'] ?? user.email ?? '-';
          final String foto = data['foto'] ?? '';
          final String role = data['role'] ?? 'student';

          final String roleName = role == 'admin' ? 'Administrator' : 'Student';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // PROFILE HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: AppColor.dark,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      // FOTO PROFIL
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: AppColor.sage,
                        backgroundImage: foto.isNotEmpty
                            ? NetworkImage(foto)
                            : const AssetImage('assets/nini1.jpeg')
                                  as ImageProvider,
                        onBackgroundImageError: (_, __) {},
                        child: foto.isEmpty ? null : null,
                      ),

                      const SizedBox(height: 15),

                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColor.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        roleName,
                        style: const TextStyle(
                          color: AppColor.sage,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.darkRed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          kelas,
                          style: const TextStyle(
                            color: AppColor.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // PERSONAL INFORMATION
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Personal Information',
                    style: TextStyle(
                      color: AppColor.dark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                infoCard(Icons.person_outline, 'Nama Lengkap', name),

                infoCard(Icons.school_outlined, 'Kelas', kelas),

                infoCard(Icons.email_outlined, 'Email', email),

                infoCard(Icons.admin_panel_settings_outlined, 'Role', roleName),

                infoCard(
                  Icons.calendar_month_outlined,
                  'Bergabung Sejak',
                  formatDate(data['created_at']),
                ),

                const SizedBox(height: 25),

                // RIWAYAT PEMINJAMAN
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Riwayat Peminjaman',
                    style: TextStyle(
                      color: AppColor.dark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('borrowings')
                      .snapshots(),

                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Text('Gagal memuat riwayat peminjaman');
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColor.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.history, size: 35, color: AppColor.red),
                            SizedBox(height: 8),
                            Text('Belum ada riwayat peminjaman'),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final borrowing = doc.data();

                        final String itemName =
                            borrowing['item_name'] ?? 'Nama Barang';

                        final String code = borrowing['code'] ?? '-';

                        final String status = borrowing['status'] ?? '-';

                        final String tanggal = formatDate(
                          borrowing['tanggal_peminjaman'],
                        );

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColor.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: AppColor.sage,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.science_outlined,
                                  color: AppColor.red,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.dark,
                                        fontSize: 14,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      'Kode: $code',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    Text(
                                      'Tanggal: $tanggal',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: status == 'Returned'
                                            ? Colors.green
                                            : AppColor.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ABOUT APP
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColor.sage,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About Lab Things',
                        style: TextStyle(
                          color: AppColor.dark,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Lab Things merupakan aplikasi '
                        'pengelolaan inventaris laboratorium '
                        'untuk membantu pencatatan dan '
                        'pengelolaan peralatan.',
                        style: TextStyle(
                          color: AppColor.dark,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      logout(context);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.red,
                      foregroundColor: AppColor.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'LAB THINGS • 2026',
                  style: TextStyle(
                    color: AppColor.dark,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // INFORMATION CARD
  Widget infoCard(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColor.red, size: 25),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColor.dark, fontSize: 12),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: AppColor.dark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
