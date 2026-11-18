import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/utils/app_color.dart';

class BorrowingRequestsScreen extends StatelessWidget {
  const BorrowingRequestsScreen({super.key});

  Future<void> approveBorrowing(
    BuildContext context,
    String borrowingId,
    Map<String, dynamic> data,
  ) async {
    try {
      final db = FirebaseFirestore.instance;

      final borrowingRef = db.collection('borrowings').doc(borrowingId);

      final itemRef = db.collection('items').doc(data['item_id']);

      final studentBorrowingRef = db
          .collection('users')
          .doc(data['user_id'])
          .collection('borrowings')
          .doc(borrowingId);

      await db.runTransaction((transaction) async {
        final borrowingSnapshot = await transaction.get(borrowingRef);

        final itemSnapshot = await transaction.get(itemRef);

        if (!borrowingSnapshot.exists || !itemSnapshot.exists) {
          throw Exception('Data peminjaman atau barang tidak ditemukan');
        }

        if (borrowingSnapshot.data()?['status'] != 'Menunggu Persetujuan') {
          throw Exception('Pengajuan sudah diproses');
        }

        if (itemSnapshot.data()?['status'] != 'Pending') {
          throw Exception('Status barang sudah berubah');
        }

        transaction.update(itemRef, {
          'status': 'Borrowed',
          'active_borrowing_id': borrowingId,
        });

        transaction.update(borrowingRef, {
          'status': 'Dipinjam',
          'tanggal_disetujui': DateTime.now().toIso8601String(),
        });

        transaction.update(studentBorrowingRef, {
          'status': 'Dipinjam',
          'tanggal_disetujui': DateTime.now().toIso8601String(),
        });
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peminjaman berhasil disetujui')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyetujui: $e')));
    }
  }

  Future<void> rejectBorrowing(
    BuildContext context,
    String borrowingId,
    Map<String, dynamic> data,
  ) async {
    try {
      final db = FirebaseFirestore.instance;

      final borrowingRef = db.collection('borrowings').doc(borrowingId);

      final itemRef = db.collection('items').doc(data['item_id']);

      final studentBorrowingRef = db
          .collection('users')
          .doc(data['user_id'])
          .collection('borrowings')
          .doc(borrowingId);

      await db.runTransaction((transaction) async {
        final borrowingSnapshot = await transaction.get(borrowingRef);

        final itemSnapshot = await transaction.get(itemRef);

        if (!borrowingSnapshot.exists) {
          throw Exception('Pengajuan tidak ditemukan');
        }

        if (borrowingSnapshot.data()?['status'] != 'Menunggu Persetujuan') {
          throw Exception('Pengajuan sudah diproses');
        }

        transaction.update(borrowingRef, {'status': 'Ditolak'});

        transaction.update(studentBorrowingRef, {'status': 'Ditolak'});

        if (itemSnapshot.exists &&
            itemSnapshot.data()?['status'] == 'Pending') {
          transaction.update(itemRef, {'status': 'Available'});
        }
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil ditolak')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menolak: $e')));
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString());

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColor.white,
        appBar: AppBar(
          title: const Text('Data Peminjaman'),
          backgroundColor: AppColor.dark,
          foregroundColor: AppColor.white,
          bottom: const TabBar(
            indicatorColor: AppColor.sage,
            labelColor: AppColor.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: 'Pengajuan'),
              Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: 'Belum Kembali',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [PendingBorrowingTab(), ActiveBorrowingTab()],
        ),
      ),
    );
  }
}

// ================= PENGAJUAN =================

class PendingBorrowingTab extends StatelessWidget {
  const PendingBorrowingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = const BorrowingRequestsScreen();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('borrowings')
          .where('status', isEqualTo: 'Menunggu Persetujuan')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Gagal mengambil pengajuan: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada pengajuan peminjaman'));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColor.cream.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColor.sage),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['item_name'] ?? 'Nama Barang',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColor.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Nama siswa: ${data['user_name'] ?? '-'}'),
                  Text('Email: ${data['user_email'] ?? '-'}'),
                  Text('Kode barang: ${data['code'] ?? '-'}'),
                  const SizedBox(height: 10),
                  const Text(
                    'Status: Menunggu Persetujuan',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              screen.approveBorrowing(context, doc.id, data),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Setujui'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              screen.rejectBorrowing(context, doc.id, data),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ================= BARANG BELUM KEMBALI =================

class ActiveBorrowingTab extends StatelessWidget {
  const ActiveBorrowingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('borrowings')
          .where('status', isEqualTo: 'Dipinjam')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal mengambil data: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Semua barang sudah dikembalikan'));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColor.cream.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColor.sage),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColor.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['item_name'] ?? 'Nama Barang',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColor.dark,
                          ),
                        ),
                      ),
                      const Icon(Icons.circle, size: 9, color: Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Nama siswa: ${data['user_name'] ?? '-'}'),
                  Text('Email: ${data['user_email'] ?? '-'}'),
                  Text('Kode barang: ${data['code'] ?? '-'}'),
                  Text(
                    'Tanggal pinjam: ${_formatDate(data['tanggal_peminjaman'])}',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Status: Belum Dikembalikan',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return value.toString();
    }
  }
}
