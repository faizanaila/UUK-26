
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/utils/app_color.dart';

class ItemDetailScreen extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const ItemDetailScreen({
    super.key,
    required this.documentId,
    required this.data,
  });

  Future<void> ajukanPinjam(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
        ),
      );
      return;
    }

    try {
      final db = FirebaseFirestore.instance;

      final itemRef = db.collection('items').doc(documentId);
      final userRef = db.collection('users').doc(user.uid);

      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data() ?? {};

      final borrowingRef = db.collection('borrowings').doc();

      final studentBorrowingRef = userRef
          .collection('borrowings')
          .doc(borrowingRef.id);

      await db.runTransaction((transaction) async {
        final itemSnapshot = await transaction.get(itemRef);

        if (!itemSnapshot.exists) {
          throw Exception('Alat tidak ditemukan');
        }

        final itemData =
            itemSnapshot.data() as Map<String, dynamic>;

        if (itemData['status'] != 'Available') {
          throw Exception('Alat sudah tidak tersedia');
        }

        final borrowingData = {
          'borrowing_id': borrowingRef.id,
          'user_id': user.uid,
          'user_name': userData['name'] ?? 'Siswa',
          'user_email': user.email ?? '',
          'item_id': documentId,
          'item_name': data['item_name'] ?? '',
          'category': data['category'] ?? '',
          'code': data['code'] ?? '',
          'image': data['image'] ?? '',
          'tanggal_peminjaman':
              DateTime.now().toIso8601String(),
          'status': 'Menunggu Persetujuan',
        };

        transaction.update(itemRef, {
          'status': 'Pending',
        });

        transaction.set(borrowingRef, borrowingData);
        transaction.set(studentBorrowingRef, borrowingData);
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengajuan berhasil! Menunggu persetujuan Admin.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nama = data['item_name'] ?? 'Nama Barang';
    final String kategori = data['category'] ?? '-';
    final String kode = data['code'] ?? '-';
    final String status = data['status'] ?? 'Available';
    final String spesifikasi = data['spesification'] ?? '-';
    final String gambar = data['image'] ?? '';

    final bool tersedia = status == 'Available';

    return Scaffold(
      backgroundColor: AppColor.cream,
      appBar: AppBar(
        title: const Text('Detail Inventaris'),
        backgroundColor: AppColor.dark,
        foregroundColor: AppColor.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 230,
              decoration: BoxDecoration(
                color: AppColor.sage,
                borderRadius: BorderRadius.circular(15),
              ),
              child: gambar.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        gambar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            size: 60,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2,
                      size: 60,
                      color: AppColor.dark,
                    ),
            ),

            const SizedBox(height: 20),

            Text(
              nama,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColor.dark,
              ),
            ),

            const SizedBox(height: 15),

            detailInfo('Kategori', kategori),
            detailInfo('Kode Serial', kode),
            detailInfo(
              'Status',
              status == 'Pending'
                  ? 'Menunggu Persetujuan'
                  : status,
            ),
            detailInfo('Spesifikasi', spesifikasi),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: tersedia
                    ? () => ajukanPinjam(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.red,
                  foregroundColor: AppColor.white,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.all(15),
                ),
                child: Text(
                  tersedia
                      ? 'Ajukan Peminjaman'
                      : status == 'Pending'
                          ? 'Menunggu Persetujuan'
                          : 'Alat Sedang Dipinjam',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailInfo(String judul, String isi) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              color: AppColor.darkRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isi,
            style: const TextStyle(
              color: AppColor.dark,
            ),
          ),
        ],
      ),
    );
  }
}
