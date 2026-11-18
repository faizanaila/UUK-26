import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screen/borrowing_receipt.dart';
import 'package:flutter_application_1/screen/borrowing_requests_screen.dart';
import 'package:flutter_application_1/screen/item_detail_screen.dart';
import 'package:flutter_application_1/utils/app_color.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';

// ================= MAIN NAVIGATION =================

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error Firestore:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Data pengguna tidak ditemukan')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        final role = (userData['role'] ?? 'student')
            .toString()
            .toLowerCase()
            .trim();

        final bool isAdmin = role == 'admin';

        final pages = isAdmin
            ? <Widget>[
                const HomeScreen(isAdmin: true),
                const InventoryScreen(),
                const ProfileScreen(),
                const BorrowingRequestsScreen(),
              ]
            : <Widget>[
                const HomeScreen(isAdmin: false),
                const InventoryScreen(),
                const BorrowingReceiptScreen(),
                const ProfileScreen(),
              ];

        if (selectedIndex >= pages.length) {
          selectedIndex = 0;
        }

        return Scaffold(
          body: pages[selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            selectedItemColor: AppColor.red,
            unselectedItemColor: Colors.grey,
            backgroundColor: AppColor.white,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            items: isAdmin
                ? const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      label: 'Beranda',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2_outlined),
                      label: 'Kelola Alat',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Profil',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.assignment_outlined),
                      label: 'Pengajuan',
                    ),
                  ]
                : const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      label: 'Beranda',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2_outlined),
                      label: 'Pinjam Alat',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_outlined),
                      label: 'Receipt',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Profil',
                    ),
                  ],
          ),
        );
      },
    );
  }
}

// ================= HOME SCREEN =================

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({super.key, this.isAdmin = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final searchController = TextEditingController();

  String searchText = '';
  int currentBanner = 0;

  final List<String> banners = [
    'assets/fto1.jpg',
    'assets/fto2.jpg',
    'assets/fto3.jpg',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ================= BANNER =================

  Widget bannerSlider() {
    return Column(
      children: [
        SizedBox(
          height: 185,
          child: PageView.builder(
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                currentBanner = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColor.dark,
                  borderRadius: BorderRadius.circular(18),
                  image: DecorationImage(
                    image: AssetImage(banners[index]),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      AppColor.dark.withOpacity(0.5),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LAB THINGS / 2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep your lab organized.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Manage your laboratory equipment easily.',
                      style: TextStyle(color: AppColor.cream, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: currentBanner == index ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: currentBanner == index ? AppColor.red : AppColor.cream,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= STATUS CARD =================

  Widget statusCard(String title, int count, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: textColor, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                color: textColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DAFTAR ALAT =================

  Widget daftarAlat() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('items').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text('Gagal mengambil data alat');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada data alat'));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final name = (data['item_name'] ?? '').toString().toLowerCase();

          final available = data['status'] == 'Available';

          return name.contains(searchText) && (widget.isAdmin || available);
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('Tidak ada alat yang ditemukan'));
        }

        return SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final bool isAvailable = data['status'] == 'Available';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ItemDetailScreen(documentId: doc.id, data: data),
                    ),
                  );
                },
                child: Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColor.cream.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: SizedBox(
                          height: 105,
                          width: double.infinity,
                          child:
                              data['image'] != null &&
                                  data['image'].toString().isNotEmpty
                              ? Image.network(
                                  data['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.science_outlined,
                                      color: AppColor.red,
                                      size: 35,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.science_outlined,
                                  color: AppColor.red,
                                  size: 35,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['item_name'] ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColor.dark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['category'] ?? '-',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['status'] == 'Pending'
                                  ? 'Menunggu Persetujuan'
                                  : data['status'] ?? '-',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAvailable
                                    ? AppColor.dark
                                    : AppColor.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ================= HOME BUILD =================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // HEADER USER
            StreamBuilder<DocumentSnapshot>(
              stream: user == null
                  ? null
                  : FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
              builder: (context, snapshot) {
                String name = 'Pengguna';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  name = data['name'] ?? 'Pengguna';
                }

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColor.dark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isAdmin
                                ? 'Dashboard Admin'
                                : 'Selamat datang kembali,',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.sage,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Halo, $name!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const CircleAvatar(
                        backgroundColor: AppColor.sage,
                        child: Icon(
                          Icons.science_outlined,
                          color: AppColor.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // SEARCH
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari alat laboratorium...',
                prefixIcon: const Icon(Icons.search, color: AppColor.red),
                filled: true,
                fillColor: AppColor.cream.withOpacity(0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BANNER
            bannerSlider(),

            const SizedBox(height: 20),

            // STATUS ALAT
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .snapshots(),
              builder: (context, snapshot) {
                int available = 0;
                int borrowed = 0;
                int total = 0;

                if (snapshot.hasData) {
                  total = snapshot.data!.docs.length;

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;

                    if (data['status'] == 'Available') {
                      available++;
                    }

                    if (data['status'] == 'Borrowed') {
                      borrowed++;
                    }
                  }
                }

                return Row(
                  children: [
                    statusCard(
                      widget.isAdmin ? 'Available' : 'Alat Tersedia',
                      available,
                      AppColor.sage,
                      AppColor.dark,
                    ),
                    const SizedBox(width: 12),
                    statusCard(
                      widget.isAdmin ? 'Borrowed' : 'Total Alat',
                      widget.isAdmin ? borrowed : total,
                      AppColor.red,
                      Colors.white,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // JUDUL DAFTAR ALAT
            Text(
              widget.isAdmin ? 'Daftar Semua Alat' : 'Alat yang Bisa Dipinjam',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppColor.dark,
              ),
            ),

            const SizedBox(height: 12),

            daftarAlat(),
          ],
        ),
      ),
    );
  }
}
