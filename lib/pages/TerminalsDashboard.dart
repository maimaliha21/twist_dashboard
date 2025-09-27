import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddTerminalPage()),
                  );
                },
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
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final terminals = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? "").toString().toLowerCase();
                    return name.contains(_terminalSearch);
                  }).toList();

                  if (terminals.isEmpty) {
                    return Center(
                        child: Text("No terminals found", style: TextStyle(color: AppColors.textSecondary)));
                  }

                  return ListView.builder(
                    itemCount: terminals.length,
                    itemBuilder: (context, index) {
                      final data = terminals[index].data() as Map<String, dynamic>;
                      final companyRef = data['companyId'] as DocumentReference?;
                      final branchRef = data['branchId'] as DocumentReference?;
                      return ListTile(
                        title: Text(data['name'] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Serial: ${data['serialNumber'] ?? ""}"),
                            Text("Status: ${data['status'] ?? ""}"),
                            StreamBuilder<DocumentSnapshot>(
                              stream: companyRef?.snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final compData = snapshot.data!.data() as Map<String, dynamic>?;
                                  return Text("Company: ${compData?['name'] ?? 'Unknown'}");
                                }
                                return const Text("Company: -");
                              },
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: branchRef?.snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final branchData = snapshot.data!.data() as Map<String, dynamic>?;
                                  return Text("Branch: ${branchData?['name'] ?? 'Unknown'}");
                                }
                                return const Text("Branch: -");
                              },
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColors.warning),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddTerminalPage(
                                      terminalId: terminals[index].id,
                                      terminalData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _confirmDeleteTerminal(context, terminals[index].id, data['name']),
                            ),
                          ],
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

  void _confirmDeleteTerminal(BuildContext context, String id, String? name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Terminal"),
        content: Text("Are you sure you want to delete $name?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
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

// ======================== Add/Edit Terminal Page ========================

class AddTerminalPage extends StatefulWidget {
  final String? terminalId;
  final Map<String, dynamic>? terminalData;

  const AddTerminalPage({super.key, this.terminalId, this.terminalData});

  @override
  State<AddTerminalPage> createState() => _AddTerminalPageState();
}

class _AddTerminalPageState extends State<AddTerminalPage> {
  final _nameCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();

  String? _selectedCompanyId;
  String? _selectedBranchId;
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    if (widget.terminalData != null) {
      final data = widget.terminalData!;
      _nameCtrl.text = data['name'] ?? '';
      _serialCtrl.text = data['serialNumber'] ?? '';
      _statusCtrl.text = data['status'] ?? '';
      _selectedCompanyId = (data['companyId'] as DocumentReference?)?.id;
      _selectedBranchId = (data['branchId'] as DocumentReference?)?.id;
      final geo = data['location'] as GeoPoint?;
      if (geo != null) {
        _selectedPosition = LatLng(geo.latitude, geo.longitude);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.terminalId == null ? "Add Terminal" : "Edit Terminal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            const SizedBox(height: 10),
            TextField(controller: _serialCtrl, decoration: const InputDecoration(labelText: "Serial Number")),
            const SizedBox(height: 10),
            TextField(controller: _statusCtrl, decoration: const InputDecoration(labelText: "Status")),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("companies").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final companies = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Company"),
                  value: _selectedCompanyId,
                  items: companies.map((doc) {
                    final cData = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: doc.id, child: Text(cData['name'] ?? ""));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCompanyId = val;
                      _selectedBranchId = null;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            if (_selectedCompanyId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("branches")
                    .where("companyId", isEqualTo: FirebaseFirestore.instance.collection("companies").doc(_selectedCompanyId))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final branches = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Branch"),
                    value: _selectedBranchId,
                    items: branches.map((doc) {
                      final bData = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(value: doc.id, child: Text(bData['name'] ?? ""));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBranchId = val),
                  );
                },
              ),
            const SizedBox(height: 20),
            const Text("Select Location:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: _selectedPosition ?? const LatLng(31.5, 35.5), zoom: 10),
                markers: _selectedPosition != null
                    ? {
                        Marker(
                          markerId: const MarkerId("selected"),
                          position: _selectedPosition!,
                          draggable: true,
                          onDragEnd: (newPos) => setState(() => _selectedPosition = newPos),
                        )
                      }
                    : {},
                onTap: (point) => setState(() => _selectedPosition = point),
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
              ),
            ),
            const SizedBox(height: 10),
            if (_selectedPosition != null)
              Text("Selected: ${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _saveTerminal,
                child: Text(widget.terminalId == null ? "Create Terminal" : "Update Terminal"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTerminal() async {
    if (_nameCtrl.text.isEmpty ||
        _serialCtrl.text.isEmpty ||
        _statusCtrl.text.isEmpty ||
        _selectedCompanyId == null ||
        _selectedBranchId == null ||
        _selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select location")),
      );
      return;
    }

    final data = {
      "name": _nameCtrl.text.trim(),
      "serialNumber": _serialCtrl.text.trim(),
      "status": _statusCtrl.text.trim(),
      "companyId": FirebaseFirestore.instance.collection("companies").doc(_selectedCompanyId),
      "branchId": FirebaseFirestore.instance.collection("branches").doc(_selectedBranchId),
      "location": GeoPoint(_selectedPosition!.latitude, _selectedPosition!.longitude),
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (widget.terminalId == null) {
      await FirebaseFirestore.instance.collection("terminals").add(data);
    } else {
      await FirebaseFirestore.instance.collection("terminals").doc(widget.terminalId).update(data);
    }

    Navigator.pop(context);
  }
}
