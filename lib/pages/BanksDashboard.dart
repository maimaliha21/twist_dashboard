// lib/pages/banks_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twist_dashboard/theme/AppColors.dart';

class BanksDashboard extends StatefulWidget {
  const BanksDashboard({super.key});

  @override
  State<BanksDashboard> createState() => _BanksDashboardState();
}

class _BanksDashboardState extends State<BanksDashboard> {
  bool _showForm = false;
  bool _isEditing = false;
  String? _editingId;

  // Controllers
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final logoCtrl = TextEditingController();
  final minCtrl = TextEditingController();
  final maxCtrl = TextEditingController();
  final instCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Banks Management",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    setState(() {
                      _showForm = true;
                      _isEditing = false;
                      _editingId = null;
                      _clearControllers();
                    });
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Add New Bank"),
                ),
              ],
            ),
          ),

          // جدول أو فورم
          Expanded(
            child: _showForm ? _buildForm(context) : _buildTable(context),
          ),
        ],
      ),
    );
  }

  /// جدول البنوك
  Widget _buildTable(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("banks").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No banks found", style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final banks = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppColors.surface),
                      dataRowHeight: 70,
                      columnSpacing: 32,
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Logo")),
                        DataColumn(label: Text("Min Loan")),
                        DataColumn(label: Text("Max Loan")),
                        DataColumn(label: Text("Installments")),
                        DataColumn(label: Text("Updated At")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: banks.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(Text(data['name'] ?? '')),
                            DataCell(
                              data['logoUrl'] != null && data['logoUrl'].toString().isNotEmpty
                                  ? Image.network(data['logoUrl'], width: 40, height: 40)
                                  : Icon(Icons.image_not_supported, color: AppColors.greyLight),
                            ),
                            DataCell(Text(data['loanLimits']?['min']?.toString() ?? '-')),
                            DataCell(Text(data['loanLimits']?['max']?.toString() ?? '-')),
                            DataCell(Text(data['maxInstallments']?.toString() ?? '-')),
                            DataCell(Text(
                              data['updatedAt'] != null
                                  ? (data['updatedAt'] as Timestamp).toDate().toString().split(' ')[0]
                                  : '-',
                            )),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: AppColors.warning),
                                    onPressed: () {
                                      setState(() {
                                        _showForm = true;
                                        _isEditing = true;
                                        _editingId = doc.id;
                                        _fillControllers(data);
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: AppColors.error),
                                    onPressed: () => _confirmDelete(context, doc.id, data['name']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// الفورم مع التحقق
  Widget _buildForm(BuildContext context) {
    String? nameError;
    String? descError;
    String? logoError;
    String? minError;
    String? maxError;
    String? instError;

    return StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRowFields([
              _buildTextField(nameCtrl, "Bank Name", Icons.account_balance, errorText: nameError),
              _buildTextField(descCtrl, "Description", Icons.description, errorText: descError),
            ]),
            _buildRowFields([
              _buildTextField(logoCtrl, "Logo URL", Icons.image, errorText: logoError),
              _buildTextField(minCtrl, "Min Loan", Icons.attach_money, type: TextInputType.number, errorText: minError),
            ]),
            _buildRowFields([
              _buildTextField(maxCtrl, "Max Loan", Icons.attach_money, type: TextInputType.number, errorText: maxError),
              _buildTextField(instCtrl, "Installments", Icons.date_range, type: TextInputType.number, errorText: instError),
            ]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelForm,
                  child: Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    setState(() {
                      nameError = nameCtrl.text.trim().isEmpty ? "Bank name is required" : null;
                      descError = descCtrl.text.trim().isEmpty ? "Description is required" : null;
                      logoError = logoCtrl.text.trim().isEmpty ? "Logo URL is required" : null;
                      minError = minCtrl.text.trim().isEmpty ? "Min loan is required" : null;
                      maxError = maxCtrl.text.trim().isEmpty ? "Max loan is required" : null;
                      instError = instCtrl.text.trim().isEmpty ? "Installments are required" : null;
                    });

                    if ([nameError, descError, logoError, minError, maxError, instError].every((e) => e == null)) {
                      final data = {
                        "name": nameCtrl.text,
                        "description": descCtrl.text,
                        "logoUrl": logoCtrl.text,
                        "loanLimits": {
                          "min": int.tryParse(minCtrl.text) ?? 1000,
                          "max": int.tryParse(maxCtrl.text) ?? 50000,
                        },
                        "maxInstallments": int.tryParse(instCtrl.text) ?? 60,
                        "updatedAt": FieldValue.serverTimestamp(),
                      };

                      if (_isEditing && _editingId != null) {
                        await FirebaseFirestore.instance.collection("banks").doc(_editingId).update(data);
                      } else {
                        data["createdAt"] = FieldValue.serverTimestamp();
                        await FirebaseFirestore.instance.collection("banks").add(data);
                      }

                      _cancelForm();
                    }
                  },
                  child: Text(_isEditing ? "Update" : "Save", style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Row helper
  Widget _buildRowFields(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: children.map((child) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: child,
        ))).toList(),
      ),
    );
  }

  /// TextField helper
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType? type, String? errorText}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        errorText: errorText,
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }

  void _clearControllers() {
    nameCtrl.clear();
    descCtrl.clear();
    logoCtrl.clear();
    minCtrl.clear();
    maxCtrl.clear();
    instCtrl.clear();
  }

  void _fillControllers(Map<String, dynamic> data) {
    nameCtrl.text = data['name'] ?? '';
    descCtrl.text = data['description'] ?? '';
    logoCtrl.text = data['logoUrl'] ?? '';
    minCtrl.text = data['loanLimits']?['min']?.toString() ?? '';
    maxCtrl.text = data['loanLimits']?['max']?.toString() ?? '';
    instCtrl.text = data['maxInstallments']?.toString() ?? '';
  }

  void _cancelForm() {
    setState(() {
      _showForm = false;
      _isEditing = false;
      _editingId = null;
      _clearControllers();
    });
  }

  void _confirmDelete(BuildContext context, String id, String? bankName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete ${bankName ?? 'this bank'}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              FirebaseFirestore.instance.collection("banks").doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
