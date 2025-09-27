// lib/pages/companies_dashboard.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twist_dashboard/theme/AppColors.dart';

class CompaniesDashboard extends StatefulWidget {
  const CompaniesDashboard({super.key});

  @override
  State<CompaniesDashboard> createState() => _CompaniesDashboardState();
}

class _CompaniesDashboardState extends State<CompaniesDashboard> {
  String _companySearch = "";
  String _branchSearch = "";

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header + Tabs
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Companies & Branches",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _showAddCompanyDialog(context),
                            icon: const Icon(Icons.business, size: 20),
                            label: const Text("Add Company"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _showAddBranchDialog(context, null),
                            icon: const Icon(Icons.store, size: 20),
                            label: const Text("Add Branch"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: const [
                        Tab(text: "Companies"),
                        Tab(text: "Branches"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      // Search Companies
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Search Companies...",
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) {
                          setState(() => _companySearch = val.toLowerCase());
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return _buildCompaniesTable(maxWidth: constraints.maxWidth);
                          },
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      // Search Branches
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Search Branches...",
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) {
                          setState(() => _branchSearch = val.toLowerCase());
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return _buildBranchesTable(maxWidth: constraints.maxWidth);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- Companies Table -----------------
  Widget _buildCompaniesTable({required double maxWidth}) {
    return _styledTable(
      stream: FirebaseFirestore.instance
          .collection("companies")
          .orderBy("name")
          .snapshots(),
      emptyIcon: Icons.business,
      emptyText: "No companies found",
      columns: const [
        DataColumn(label: Text("Name")),
        DataColumn(label: Text("Description")),
        DataColumn(label: Text("Branches Count")),
        DataColumn(label: Text("Created At")),
        DataColumn(label: Text("Actions")),
      ],
      maxWidth: maxWidth,
      rowBuilder: (doc, data, context) {
        final name = (data['name'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? '').toString().toLowerCase();

        if (_companySearch.isNotEmpty &&
            !name.contains(_companySearch) &&
            !desc.contains(_companySearch)) {
          return null;
        }

        return DataRow(
          cells: [
            DataCell(Text(data['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(data['description'] ?? '-')),
            DataCell(StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("branches")
                  .where("companyId", isEqualTo: doc.reference)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Text(count.toString());
              },
            )),
            DataCell(Text(
              data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0]
                  : '-',
            )),
            DataCell(Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.warning, size: 20),
                  onPressed: () => _showEditCompanyDialog(context, doc.id, data),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: AppColors.error, size: 20),
                  onPressed: () => _confirmDeleteCompany(context, doc.id, data['name']),
                ),
                IconButton(
                  icon: Icon(Icons.add_business, color: AppColors.primary, size: 20),
                  onPressed: () => _showAddBranchDialog(context, doc.id),
                  tooltip: "Add Branch",
                ),
              ],
            )),
          ],
        );
      },
    );
  }

  // ----------------- Branches Table -----------------
  Widget _buildBranchesTable({required double maxWidth}) {
    return _styledTable(
      stream: FirebaseFirestore.instance
          .collection("branches")
          .orderBy("name")
          .snapshots(),
      emptyIcon: Icons.store,
      emptyText: "No branches found",
      columns: const [
        DataColumn(label: Text("Name")),
        DataColumn(label: Text("Company")),
        DataColumn(label: Text("Address")),
        DataColumn(label: Text("Terminals Count")),
        DataColumn(label: Text("Manager")),
        DataColumn(label: Text("Actions")),
      ],
      maxWidth: maxWidth,
      rowBuilder: (doc, data, context) {
        final name = (data['name'] ?? '').toString().toLowerCase();
        final manager = (data['manager'] ?? '').toString().toLowerCase();
        final address = (data['address'] ?? '').toString().toLowerCase();

        if (_branchSearch.isNotEmpty &&
            !name.contains(_branchSearch) &&
            !manager.contains(_branchSearch) &&
            !address.contains(_branchSearch)) {
          return null;
        }

        return DataRow(
          cells: [
            DataCell(Text(data['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(StreamBuilder<DocumentSnapshot>(
              stream: (data['companyId'] as DocumentReference).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final company = snapshot.data!.data() as Map<String, dynamic>?;
                  return Text(company?['name'] ?? 'Unknown');
                }
                return const Text('-');
              },
            )),
            DataCell(Text(data['address'] ?? '-')),
            DataCell(StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("terminals")
                  .where("branchId", isEqualTo: doc.reference)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Text(count.toString());
              },
            )),
            DataCell(Text(data['manager'] ?? '-')),
            DataCell(Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.warning, size: 20),
                  onPressed: () => _showEditBranchDialog(context, doc.id, data),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: AppColors.error, size: 20),
                  onPressed: () => _confirmDeleteBranch(context, doc.id, data['name']),
                ),
              ],
            )),
          ],
        );
      },
    );
  }

  // ----------------- Styled Table Template -----------------
  Widget _styledTable({
    required Stream<QuerySnapshot> stream,
    required IconData emptyIcon,
    required String emptyText,
    required List<DataColumn> columns,
    required DataRow? Function(QueryDocumentSnapshot doc,
            Map<String, dynamic> data, BuildContext context)
        rowBuilder,
    double? maxWidth,
  }) {
    return Container(
      width: maxWidth ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 64, color: AppColors.greyLight),
                  const SizedBox(height: 16),
                  Text(emptyText,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          final rows = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return rowBuilder(doc, data, context);
          }).whereType<DataRow>().toList();

          if (rows.isEmpty) {
            return Center(
              child: Text("No matching results",
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: maxWidth ?? double.infinity,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(AppColors.surface),
                  dataRowHeight: 65,
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  dataTextStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  columns: columns,
                  rows: rows,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------- Dialogs -----------------
  

 void _showAddCompanyDialog(BuildContext context) {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String? nameError;
  String? descError;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text("Add Company"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Name",
                errorText: nameError, // رسالة الخطأ تحت الحقل
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: "Description",
                errorText: descError,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // تحقق من الحقول
              setState(() {
                nameError = nameCtrl.text.trim().isEmpty ? "Please enter a name" : null;
                descError = descCtrl.text.trim().isEmpty ? "Please enter a description" : null;
              });

              // إذا كل شيء تمام
              if (nameError == null && descError == null) {
                await FirebaseFirestore.instance.collection("companies").add({
                  "name": nameCtrl.text.trim(),
                  "description": descCtrl.text.trim(),
                  "createdAt": Timestamp.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    ),
  );
}


Future _showAddBranchDialog(BuildContext context, String? companyId) {
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final managerCtrl = TextEditingController();
  String? selectedCompany;

  String? nameError;
  String? addressError;
  String? managerError;
  String? companyError;

  return showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text("Add Branch"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Name",
                errorText: nameError,
              ),
            ),
            TextField(
              controller: addressCtrl,
              decoration: InputDecoration(
                labelText: "Address",
                errorText: addressError,
              ),
            ),
            TextField(
              controller: managerCtrl,
              decoration: InputDecoration(
                labelText: "Manager",
                errorText: managerError,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("companies").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final companies = snapshot.data!.docs;
                if (companies.isEmpty) return const Text("No companies available");
                selectedCompany ??= companyId ?? companies.first.id;

                return DropdownButtonFormField<String>(
                  value: selectedCompany,
                  decoration: InputDecoration(
                    labelText: "Company",
                    errorText: companyError,
                  ),
                  items: companies.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: doc.id, child: Text(data['name'] ?? ''));
                  }).toList(),
                  onChanged: (val) => selectedCompany = val,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // تحقق من الحقول
              setState(() {
                nameError = nameCtrl.text.trim().isEmpty ? "Please enter a name" : null;
                addressError = addressCtrl.text.trim().isEmpty ? "Please enter an address" : null;
                managerError = managerCtrl.text.trim().isEmpty ? "Please enter a manager" : null;
                companyError = selectedCompany == null ? "Please select a company" : null;
              });

              if (nameError == null && addressError == null && managerError == null && companyError == null) {
                await FirebaseFirestore.instance.collection("branches").add({
                  "name": nameCtrl.text.trim(),
                  "address": addressCtrl.text.trim(),
                  "manager": managerCtrl.text.trim(),
                  "companyId": FirebaseFirestore.instance.collection("companies").doc(selectedCompany),
                  "createdAt": Timestamp.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    ),
  );
}


  void _showEditCompanyDialog(BuildContext context, String id, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name']);
    final descCtrl = TextEditingController(text: data['description']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Company"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("companies").doc(id).update({
                "name": nameCtrl.text.trim(),
                "description": descCtrl.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showEditBranchDialog(BuildContext context, String id, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name']);
    final addressCtrl = TextEditingController(text: data['address']);
    final managerCtrl = TextEditingController(text: data['manager']);
    String? selectedCompany = (data['companyId'] as DocumentReference).id;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Branch"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Address")),
            TextField(controller: managerCtrl, decoration: const InputDecoration(labelText: "Manager")),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("companies").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final companies = snapshot.data!.docs;
                if (companies.isEmpty) return const Text("No companies available");

                return DropdownButtonFormField<String>(
                  value: selectedCompany,
                  decoration: const InputDecoration(labelText: "Company"),
                  items: companies.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: doc.id, child: Text(d['name'] ?? ''));
                  }).toList(),
                  onChanged: (val) => selectedCompany = val,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("branches").doc(id).update({
                "name": nameCtrl.text.trim(),
                "address": addressCtrl.text.trim(),
                "manager": managerCtrl.text.trim(),
                "companyId": FirebaseFirestore.instance.collection("companies").doc(selectedCompany),
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // ----------------- Confirm Delete -----------------
  void _confirmDeleteCompany(BuildContext context, String id, String? name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Company"),
        content: Text("Are you sure you want to delete $name and all its branches & terminals?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              // حذف الفروع والتيرمينالات التابعة للشركة
              final branchesSnapshot = await FirebaseFirestore.instance
                  .collection("branches")
                  .where("companyId", isEqualTo: FirebaseFirestore.instance.collection("companies").doc(id))
                  .get();

              for (var branchDoc in branchesSnapshot.docs) {
                // حذف التيرمينالات التابعة للفرع
                final terminalsSnapshot = await FirebaseFirestore.instance
                    .collection("terminals")
                    .where("branchId", isEqualTo: branchDoc.reference)
                    .get();

                for (var tDoc in terminalsSnapshot.docs) {
                  await tDoc.reference.delete();
                }

                // حذف الفرع
                await branchDoc.reference.delete();
              }

              // حذف الشركة نفسها
              await FirebaseFirestore.instance.collection("companies").doc(id).delete();

              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBranch(BuildContext context, String id, String? name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Branch"),
        content: Text("Are you sure you want to delete $name and all its terminals?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              // حذف التيرمينالات التابعة للفرع
              final terminalsSnapshot = await FirebaseFirestore.instance
                  .collection("terminals")
                  .where("branchId", isEqualTo: FirebaseFirestore.instance.collection("branches").doc(id))
                  .get();

              for (var tDoc in terminalsSnapshot.docs) {
                await tDoc.reference.delete();
              }

              // حذف الفرع نفسه
              await FirebaseFirestore.instance.collection("branches").doc(id).delete();

              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
