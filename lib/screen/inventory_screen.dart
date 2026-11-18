
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/utils/app_color.dart';
import 'package:flutter_application_1/widget/custom_input.dart';

import 'item_detail_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Silakan login terlebih dahulu'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!userSnapshot.hasData ||
            !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text('Data pengguna tidak ditemukan'),
            ),
          );
        }

        final userData =
            userSnapshot.data!.data() as Map<String, dynamic>;

        final bool isAdmin = userData['role'] == 'admin';

        return Scaffold(
          backgroundColor: AppColor.white,
          appBar: AppBar(
            backgroundColor: AppColor.white,
            foregroundColor: AppColor.dark,
            elevation: 0,
            title: Text(
              isAdmin ? 'Kelola Inventaris' : 'Alat yang Bisa Dipinjam',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('items')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Terjadi kesalahan saat mengambil data',
                  ),
                );
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Belum ada data inventaris'),
                );
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data =
                    doc.data() as Map<String, dynamic>;

                return isAdmin ||
                    data['status'] == 'Available';
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text('Belum ada alat yang tersedia'),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final bool isAvailable =
                      data['status'] == 'Available';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailScreen(
                            documentId: doc.id,
                            data: data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColor.cream.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColor.cream,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      const BorderRadius.vertical(
                                    top: Radius.circular(14),
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: data['image'] != null &&
                                            data['image']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                            data['image'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.science_outlined,
                                                  size: 45,
                                                  color: AppColor.red,
                                                ),
                                              );
                                            },
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.science_outlined,
                                              size: 45,
                                              color: AppColor.red,
                                            ),
                                          ),
                                  ),
                                ),

                                // MENU EDIT DAN HAPUS KHUSUS ADMIN
                                if (isAdmin)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white,
                                      child: PopupMenuButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: AppColor.dark,
                                        ),
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Hapus'),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ItemFormScreen(
                                                  documentId: doc.id,
                                                  data: data,
                                                ),
                                              ),
                                            );
                                          } else if (value ==
                                              'delete') {
                                            confirmDelete(
                                              context,
                                              doc.id,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['category'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColor.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['item_name'] ?? '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.dark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? AppColor.sage
                                        : AppColor.red
                                            .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    data['status'] ?? '-',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isAvailable
                                          ? AppColor.dark
                                          : AppColor.red,
                                    ),
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
              );
            },
          ),

          // TOMBOL TAMBAH KHUSUS ADMIN
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  backgroundColor: AppColor.red,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ItemFormScreen(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                )
              : null,
        );
      },
    );
  }

  void confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Alat'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus alat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.red,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              await FirebaseFirestore.instance
                  .collection('items')
                  .doc(docId)
                  .delete();
            },
            child: const Text(
              'Ya',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// FORM TAMBAH DAN EDIT ALAT

class ItemFormScreen extends StatefulWidget {
  final String? documentId;
  final Map<String, dynamic>? data;

  const ItemFormScreen({
    super.key,
    this.documentId,
    this.data,
  });

  @override
  State<ItemFormScreen> createState() =>
      _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final nameC = TextEditingController();
  final codeC = TextEditingController();
  final imageC = TextEditingController();
  final specificationC = TextEditingController();

  final List<String> categories = [
    'Alat Ukur',
    'Alat Praktikum',
    'Alat Elektronik',
    'Alat Laboratorium',
    'Peralatan Keselamatan',
  ];

  String? category;

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      nameC.text = widget.data!['item_name'] ?? '';
      codeC.text = widget.data!['code'] ?? '';
      imageC.text = widget.data!['image'] ?? '';
      specificationC.text =
          widget.data!['spesification'] ?? '';

      if (categories.contains(widget.data!['category'])) {
        category = widget.data!['category'];
      }
    }
  }

  Future<void> saveItem() async {
    if (nameC.text.isEmpty ||
        category == null ||
        codeC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nama, kategori, dan kode wajib diisi',
          ),
        ),
      );
      return;
    }

    Map<String, dynamic> itemData = {
      'item_name': nameC.text,
      'category': category,
      'code': codeC.text,
      'image': imageC.text,
      'spesification': specificationC.text,
    };

    try {
      if (widget.documentId == null) {
        DocumentReference doc =
            await FirebaseFirestore.instance
                .collection('items')
                .add({
          ...itemData,
          'status': 'Available',
          'tanggal_pemakaian': null,
          'tanggal_kembali': null,
          'created_at': DateTime.now().toIso8601String(),
        });

        await doc.update({
          'item_id': doc.id,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.documentId)
            .update(itemData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan alat: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    codeC.dispose();
    imageC.dispose();
    specificationC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        title: Text(
          widget.documentId == null
              ? 'Tambah Alat'
              : 'Edit Alat',
        ),
        backgroundColor: AppColor.white,
        foregroundColor: AppColor.dark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CustomInput(
            controller: nameC,
            label: 'Nama Alat',
            hint: 'Contoh: Mikroskop',
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColor.cream,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: InputBorder.none,
              ),
              items: categories.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  category = value;
                });
              },
            ),
          ),
          CustomInput(
            controller: codeC,
            label: 'Kode Alat',
            hint: 'Contoh: LAB-01',
          ),
          CustomInput(
            controller: imageC,
            label: 'Link Gambar',
            hint: 'https://...',
          ),
          CustomInput(
            controller: specificationC,
            label: 'Spesifikasi',
            hint: 'Detail alat...',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Simpan Alat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
