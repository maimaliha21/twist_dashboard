import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twist_dashboard/theme/AppColors.dart';

class TerminalsDashboard extends StatefulWidget {
  const TerminalsDashboard({super.key});

  @override
  State<TerminalsDashboard> createState() => _TerminalsDashboardState();
}

class _TerminalsDashboardState extends State<TerminalsDashboard> {
  String _terminalSearch = "";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search terminals...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _terminalSearch = val.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showAddTerminalDialog(context),
                icon: const Icon(Icons.add),
                label: const Text("Add Terminal"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("terminals").snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("No terminals found",
                          style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }

                  final terminals = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? "").toString().toLowerCase();
                    return name.contains(_terminalSearch);
                  }).toList();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: DataTable(
                              headingRowColor:
                                  MaterialStateProperty.all(AppColors.surface),
                              dataRowHeight: 70,
                              columnSpacing: 32,
                              columns: const [
                                DataColumn(label: Text("Name")),
                                DataColumn(label: Text("Serial Number")),
                                DataColumn(label: Text("Company")),
                                DataColumn(label: Text("Branch")),
                                DataColumn(label: Text("Status")),
                                DataColumn(label: Text("Actions")),
                              ],
                              rows: terminals.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final companyRef =
                                    data['companyId'] as DocumentReference?;
                                final branchRef =
                                    data['branchId'] as DocumentReference?;

                                return DataRow(cells: [
                                  DataCell(Text(data['name'] ?? '')),
                                  DataCell(Text(data['serialNumber'] ?? '')),
                                  DataCell(StreamBuilder<DocumentSnapshot>(
                                    stream: companyRef?.snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final compData = snapshot.data!.data()
                                            as Map<String, dynamic>?;
                                        return Text(compData?['name'] ?? 'Unknown');
                                      }
                                      return const Text("-");
                                    },
                                  )),
                                  DataCell(StreamBuilder<DocumentSnapshot>(
                                    stream: branchRef?.snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final branchData = snapshot.data!.data()
                                            as Map<String, dynamic>?;
                                        return Text(branchData?['name'] ?? 'Unknown');
                                      }
                                      return const Text("-");
                                    },
                                  )),
                                  DataCell(Text(data['status'] ?? '')),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: AppColors.warning),
                                        onPressed: () => _showEditTerminalDialog(
                                            context, doc.id, data),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: AppColors.error),
                                        onPressed: () => _confirmDeleteTerminal(
                                            context, doc.id, data['name']),
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

Future _showAddTerminalDialog(BuildContext context) {
  final nameCtrl = TextEditingController();
  final serialCtrl = TextEditingController();
  final statusCtrl = TextEditingController();

  String? selectedCompanyId;
  String? selectedBranchId;

  String? nameError;
  String? serialError;
  String? statusError;
  String? companyError;
  String? branchError;

  return showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("Add Terminal"),
        content: SingleChildScrollView(
          child: Column(
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
                controller: serialCtrl,
                decoration: InputDecoration(
                  labelText: "Serial Number",
                  errorText: serialError,
                ),
              ),
              TextField(
                controller: statusCtrl,
                decoration: InputDecoration(
                  labelText: "Status",
                  errorText: statusError,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("companies").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final companies = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Company",
                      errorText: companyError,
                    ),
                    items: companies.map((doc) {
                      final cData = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(cData['name'] ?? ""),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCompanyId = val;
                        selectedBranchId = null;
                      });
                    },
                    value: selectedCompanyId,
                  );
                },
              ),
              const SizedBox(height: 10),
              if (selectedCompanyId != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("branches")
                      .where(
                        "companyId",
                        isEqualTo: FirebaseFirestore.instance
                            .collection("companies")
                            .doc(selectedCompanyId),
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final branches = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Branch",
                        errorText: branchError,
                      ),
                      items: branches.map((doc) {
                        final bData = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(bData['name'] ?? ""),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedBranchId = val),
                      value: selectedBranchId,
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              // تحقق من الحقول
              setState(() {
                nameError = nameCtrl.text.trim().isEmpty ? "Please enter a name" : null;
                serialError = serialCtrl.text.trim().isEmpty ? "Please enter a serial number" : null;
                statusError = statusCtrl.text.trim().isEmpty ? "Please enter a status" : null;
                companyError = selectedCompanyId == null ? "Please select a company" : null;
                branchError = selectedBranchId == null ? "Please select a branch" : null;
              });

              if (nameError == null &&
                  serialError == null &&
                  statusError == null &&
                  companyError == null &&
                  branchError == null) {
                await FirebaseFirestore.instance.collection("terminals").add({
                  "name": nameCtrl.text.trim(),
                  "serialNumber": serialCtrl.text.trim(),
                  "status": statusCtrl.text.trim(),
                  "companyId": FirebaseFirestore.instance
                      .collection("companies")
                      .doc(selectedCompanyId),
                  "branchId": FirebaseFirestore.instance
                      .collection("branches")
                      .doc(selectedBranchId),
                  "createdAt": FieldValue.serverTimestamp(),
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


  Future _showEditTerminalDialog(
      BuildContext context, String id, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name']);
    final serialCtrl = TextEditingController(text: data['serialNumber']);
    final statusCtrl = TextEditingController(text: data['status']);

    DocumentReference? selectedCompanyRef = data['companyId'] as DocumentReference?;
    DocumentReference? selectedBranchRef = data['branchId'] as DocumentReference?;

    return showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Terminal"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Name")),
                TextField(
                    controller: serialCtrl,
                    decoration:
                        const InputDecoration(labelText: "Serial Number")),
                TextField(
                    controller: statusCtrl,
                    decoration: const InputDecoration(labelText: "Status")),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("companies")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final companies = snapshot.data!.docs;
                    return DropdownButtonFormField<DocumentReference>(
                      decoration: const InputDecoration(labelText: "Company"),
                      items: companies.map((doc) {
                        final cData = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(cData['name'] ?? ""),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCompanyRef = val;
                          selectedBranchRef = null;
                        });
                      },
                      value: selectedCompanyRef,
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (selectedCompanyRef != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("branches")
                        .where("companyId", isEqualTo: selectedCompanyRef)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final branches = snapshot.data!.docs;
                      return DropdownButtonFormField<DocumentReference>(
                        decoration: const InputDecoration(labelText: "Branch"),
                        items: branches.map((doc) {
                          final bData = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.reference,
                            child: Text(bData['name'] ?? ""),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedBranchRef = val),
                        value: selectedBranchRef,
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("terminals")
                    .doc(id)
                    .update({
                  "name": nameCtrl.text,
                  "serialNumber": serialCtrl.text,
                  "status": statusCtrl.text,
                  "companyId": selectedCompanyRef,
                  "branchId": selectedBranchRef,
                });
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTerminal(BuildContext context, String id, String? name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Terminal"),
        content: Text("Are you sure you want to delete $name?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection("terminals").doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
