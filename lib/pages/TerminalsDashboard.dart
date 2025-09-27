import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:twist_dashboard/theme/AppColors.dart';

class TerminalsPage extends StatefulWidget {
  const TerminalsPage({super.key});

  @override
  State<TerminalsPage> createState() => _TerminalsPageState();
}

class _TerminalsPageState extends State<TerminalsPage> {
  String _terminalSearch = "";

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();
  String? _selectedCompanyId;
  String? _selectedBranchId;
  LatLng? _selectedPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terminals Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  icon: const Icon(Icons.add),
                  label: const Text("Add Terminal"),
                  onPressed: () => _showAddTerminalPage(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("terminals").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final terminals = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? "").toString().toLowerCase();
                    return name.contains(_terminalSearch);
                  }).toList();

                  return ListView.builder(
                    itemCount: terminals.length,
                    itemBuilder: (context, index) {
                      final data = terminals[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['name'] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Serial: ${data['serialNumber'] ?? ""}"),
                            Text("Status: ${data['status'] ?? ""}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColors.warning),
                              onPressed: () => _showEditTerminalPage(context, terminals[index].id, data),
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
          ],
        ),
      ),
    );
  }

  void _showAddTerminalPage(BuildContext context) {
    _nameCtrl.clear();
    _serialCtrl.clear();
    _statusCtrl.clear();
    _selectedCompanyId = null;
    _selectedBranchId = null;
    _selectedPosition = null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Add Terminal")),
          body: _terminalForm(),
        ),
      ),
    );
  }

  void _showEditTerminalPage(BuildContext context, String id, Map<String, dynamic> data) {
    _nameCtrl.text = data['name'];
    _serialCtrl.text = data['serialNumber'];
    _statusCtrl.text = data['status'];
    _selectedCompanyId = (data['companyId'] as DocumentReference?)?.id;
    _selectedBranchId = (data['branchId'] as DocumentReference?)?.id;

    final geo = data['location'] as GeoPoint?;
    _selectedPosition = geo != null ? LatLng(geo.latitude, geo.longitude) : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Edit Terminal")),
          body: _terminalForm(terminalId: id),
        ),
      ),
    );
  }

  Widget _terminalForm({String? terminalId}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: "Terminal Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _serialCtrl,
            decoration: const InputDecoration(
              labelText: "Serial Number",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _statusCtrl,
            decoration: const InputDecoration(
              labelText: "Status",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("companies").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final companies = snapshot.data!.docs;
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Company",
                  border: OutlineInputBorder(),
                ),
                value: _selectedCompanyId,
                items: companies.map((doc) {
                  final cData = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(cData['name'] ?? ""),
                  );
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
                  decoration: const InputDecoration(
                    labelText: "Branch",
                    border: OutlineInputBorder(),
                  ),
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
          Text(
            "Select Location:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selectedPosition ?? LatLng(31.5, 35.5),
                initialZoom: 10,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedPosition = point; // حفظ الموقع عند النقر
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.app',
                ),
                if (_selectedPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPosition!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_selectedPosition != null)
            Text(
              "Selected: ${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}",
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
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
                  "name": _nameCtrl.text,
                  "serialNumber": _serialCtrl.text,
                  "status": _statusCtrl.text,
                  "companyId": FirebaseFirestore.instance.collection("companies").doc(_selectedCompanyId),
                  "branchId": FirebaseFirestore.instance.collection("branches").doc(_selectedBranchId),
                  "location": GeoPoint(_selectedPosition!.latitude, _selectedPosition!.longitude),
                  "createdAt": FieldValue.serverTimestamp(),
                };

                if (terminalId == null) {
                  await FirebaseFirestore.instance.collection("terminals").add(data);
                } else {
                  await FirebaseFirestore.instance.collection("terminals").doc(terminalId).update(data);
                }

                Navigator.pop(context);
              },
              child: Text(terminalId == null ? "Create Terminal" : "Update Terminal"),
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
