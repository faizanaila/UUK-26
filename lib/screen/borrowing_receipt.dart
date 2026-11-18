import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/utils/app_color.dart';

class BorrowingReceiptScreen extends StatelessWidget {
  const BorrowingReceiptScreen({super.key});

  Future<void> returnItem(
    BuildContext context,
    String borrowingId,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final db = FirebaseFirestore.instance;

      final borrowingRef = db.collection('borrowings').doc(borrowingId);

      final studentBorrowingRef = db
          .collection('users')
          .doc(user.uid)
          .collection('borrowings')
          .doc(borrowingId);

      final itemRef = db.collection('items').doc(data['item_id']);

      await db.runTransaction((transaction) async {
        // Membaca semua dokumen terlebih dahulu
        final borrowingSnapshot = await transaction.get(borrowingRef);
        final studentSnapshot = await transaction.get(studentBorrowingRef);
        final itemSnapshot = await transaction.get(itemRef);

        if (!borrowingSnapshot.exists ||
            !studentSnapshot.exists ||
            !itemSnapshot.exists) {
          throw Exception('Data peminjaman atau barang tidak ditemukan');
        }

        final borrowingData = borrowingSnapshot.data()!;
        final studentData = studentSnapshot.data()!;
        final itemData = itemSnapshot.data()!;

        // Memastikan peminjaman milik siswa yang sedang login
        if (borrowingData['user_id'] != user.uid ||
            studentData['user_id'] != user.uid) {
          throw Exception(
            'Kamu tidak memiliki akses untuk mengembalikan barang ini',
          );
        }

        // Memastikan status peminjaman masih Dipinjam
        if (borrowingData['status'] != 'Dipinjam' ||
            studentData['status'] != 'Dipinjam') {
          throw Exception('Peminjaman ini sudah tidak aktif');
        }

        // Memastikan barang masih berstatus Borrowed
        if (itemData['status'] != 'Borrowed') {
          throw Exception('Status barang sudah berubah');
        }

        // Memastikan ID peminjaman cocok dengan barang
        if (itemData['active_borrowing_id'] != borrowingId) {
          throw Exception(
            'ID peminjaman tidak cocok. Periksa data active_borrowing_id pada barang.',
          );
        }

        final tanggalKembali = DateTime.now().toIso8601String();

        // Mengubah status peminjaman utama
        transaction.update(borrowingRef, {
          'status': 'Returned',
          'tanggal_pengembalian': tanggalKembali,
        });

        // Mengubah status riwayat peminjaman siswa
        transaction.update(studentBorrowingRef, {
          'status': 'Returned',
          'tanggal_pengembalian': tanggalKembali,
        });

        // Mengembalikan status barang
        transaction.update(itemRef, {
          'status': 'Available',
          'active_borrowing_id': FieldValue.delete(),
        });
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barang berhasil dikembalikan!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengembalikan barang: ${e.code} - ${e.message}'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengembalikan barang: $e')));
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString());

      return '${date.day}/${date.month}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Silakan login terlebih dahulu'));
    }

    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        title: const Text('Receipt Peminjaman'),
        backgroundColor: AppColor.dark,
        foregroundColor: AppColor.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('borrowings')
            .where('status', isEqualTo: 'Dipinjam')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal mengambil receipt: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 65,
                      color: AppColor.sage,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada barang yang sedang dipinjam',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColor.dark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final image = (data['image'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.cream.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.sage),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppColor.red),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'BUKTI PEMINJAMAN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColor.dark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Dipinjam',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    if (image.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          image,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              height: 100,
                              child: Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 14),

                    Text(
                      data['item_name'] ?? 'Nama Barang',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColor.dark,
                      ),
                    ),

                    const SizedBox(height: 12),

                    receiptInfo('Kode Barang', data['code'] ?? '-'),
                    receiptInfo('Kategori', data['category'] ?? '-'),
                    receiptInfo(
                      'Tanggal Peminjaman',
                      formatDate(data['tanggal_peminjaman']),
                    ),
                    receiptInfo('ID Peminjaman', doc.id),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Konfirmasi Pengembalian'),
                                content: Text(
                                  'Apakah kamu yakin ingin mengembalikan ${data['item_name'] ?? 'barang ini'}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                    },
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      returnItem(context, doc.id, data);
                                    },
                                    child: const Text('Ya, Kembalikan'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.assignment_return),
                        label: const Text('Kembalikan Barang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.red,
                          foregroundColor: AppColor.white,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget receiptInfo(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColor.darkRed,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(color: AppColor.dark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
