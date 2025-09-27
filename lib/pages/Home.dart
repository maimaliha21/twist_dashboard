// lib/pages/home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twist_dashboard/theme/AppColors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // عدد الكاردات بالصف افتراضي

    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان
          Text(
            "Welcome to Twist Dashboard",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // فقرة
          Text(
            "Monitor the latest statistics of banks, terminals, companies, and branches at a glance. "
            "Everything you need is just here.",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Stats Cards (GridView أصغر وأقرب)
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5, // أصغر الكاردات
            ),
            children: [
              StatCardStream(
                collection: "banks",
                title: "Total Banks",
                icon: Icons.account_balance,
                color: AppColors.primary,
              ),
              StatCardStream(
                collection: "terminals",
                title: "Active Terminals",
                icon: Icons.check_circle,
                color: AppColors.success,
                queryFilter: {"status": "active"},
              ),
              StatCardStream(
                collection: "terminals",
                title: "All Terminals",
                icon: Icons.devices,
                color: AppColors.warning,
              ),
              StatCardStream(
                collection: "companies",
                title: "Total Companies",
                icon: Icons.business,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// StatCardStream كما هي
class StatCardStream extends StatelessWidget {
  final String collection;
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, dynamic>? queryFilter;

  const StatCardStream({
    super.key,
    required this.collection,
    required this.title,
    required this.icon,
    required this.color,
    this.queryFilter,
  });

  @override
  Widget build(BuildContext context) {
    Query collectionRef = FirebaseFirestore.instance.collection(collection);
    if (queryFilter != null) {
      queryFilter!.forEach((key, value) {
        collectionRef = collectionRef.where(key, isEqualTo: value);
      });
    }

    return StreamBuilder<QuerySnapshot>(
      stream: collectionRef.snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return StatCard(
          title: title,
          value: count.toString(),
          icon: icon,
          color: color,
        );
      },
    );
  }
}

// StatCard مع تصغير padding داخلي
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
