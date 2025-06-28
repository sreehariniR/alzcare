// lib/familytree.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

// --- UI Constants ---
const Color kBackgroundColor = Color(0xFFF8F5F1); // Warm, gentle off-white
const Color kAppBarColor = Color(0xFF7C9A92); // Muted, calming green
const Color kFabColor = Color(0xFFE4A99B); // Soft, warm pink/coral

// A palette of very light pastels for the card backgrounds
const List<Color> kPastelCardColors = [
  Color(0xFFE9F3FB), // Very Light Blue
  Color(0xFFFFF2EC), // Very Light Peach
  Color(0xFFEFF7EE), // Very Light Mint
  Color(0xFFFFFBEA), // Very Light Yellow
  Color(0xFFF4EFFF), // Very Light Lavender
];


// 1. Data Model
class FamilyMember {
  final String name;
  final String relation;
  final String imagePath;

  FamilyMember({
    required this.name,
    required this.relation,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'relation': relation,
    'imagePath': imagePath,
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      name: json['name'],
      relation: json['relation'],
      imagePath: json['imagePath'],
    );
  }
}

// 2. The Main Screen Widget
class FamilyTreeScreen extends StatefulWidget {
  final bool isReadOnly;
  const FamilyTreeScreen({super.key, this.isReadOnly = false});

  @override
  _FamilyTreeScreenState createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final List<FamilyMember> _familyMembers = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  // --- UI Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('The Family Tree', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        backgroundColor: kAppBarColor,
        elevation: 0,
      ),
      floatingActionButton: widget.isReadOnly
          ? null
          : FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: 'Add Family Member',
        backgroundColor: kFabColor,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      body: _familyMembers.isEmpty
          ? _buildEmptyState()
          : _buildPolishedGridView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Your family tree is empty.',
            style: GoogleFonts.nunito(fontSize: 22, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the "+" button to add a member.',
            style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPolishedGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.85, // Aspect ratio for the polished card
      ),
      itemCount: _familyMembers.length,
      itemBuilder: (context, index) {
        final member = _familyMembers[index];
        return PolishedFamilyCard(
          member: member,
          color: kPastelCardColors[index % kPastelCardColors.length],
          onTap: widget.isReadOnly
              ? () {} // Do nothing if read-only
              : () => _showAddEditDialog(existingMember: member, existingMemberIndex: index),
          onLongPress: widget.isReadOnly
              ? () {} // Do nothing if read-only
              : () => _confirmDelete(member, index),
        );
      },
    );
  }
}

// 3. The "Best of Both Worlds" Polished Card Widget
class PolishedFamilyCard extends StatelessWidget {
  final FamilyMember member;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PolishedFamilyCard({
    super.key,
    required this.member,
    required this.color,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final imageFile = File(member.imagePath);

    return Card(
      color: color,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular Avatar for the image
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white.withOpacity(0.7),
                child: ClipOval(
                  child: SizedBox.fromSize(
                    size: const Size.fromRadius(42), // Slightly smaller than avatar for border effect
                    child: FutureBuilder<bool>(
                      future: imageFile.exists(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
                          );
                        }
                        return const Icon(Icons.person, size: 40, color: Colors.grey);
                      },
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Text information
              Text(
                member.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey[850],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                member.relation,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

// --- DATA & LOGIC METHODS (Organized in an extension) ---
extension on _FamilyTreeScreenState {

  // --- Data Persistence ---
  Future<void> _loadFamilyMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? membersJson = prefs.getStringList('familyMembers');
    if (membersJson != null) {
      setState(() {
        _familyMembers.clear();
        for (var jsonString in membersJson) {
          _familyMembers.add(FamilyMember.fromJson(jsonDecode(jsonString)));
        }
      });
    }
  }

  Future<void> _saveFamilyMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> membersJson =
    _familyMembers.map((member) => jsonEncode(member.toJson())).toList();
    await prefs.setStringList('familyMembers', membersJson);
  }

  // --- Add/Edit Dialog ---
  Future<void> _showAddEditDialog({FamilyMember? existingMember, int? existingMemberIndex}) async {
    final nameController = TextEditingController(text: existingMember?.name ?? '');
    final relationController = TextEditingController(text: existingMember?.relation ?? '');
    String? imagePath = existingMember?.imagePath;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              existingMember == null ? 'Add Family Member' : 'Edit Member',
              style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: kAppBarColor),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (image != null) {
                        setDialogState(() => imagePath = image.path);
                      }
                    },
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: kPastelCardColors[2],
                      backgroundImage: imagePath != null ? FileImage(File(imagePath!)) : null,
                      child: imagePath == null
                          ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: relationController, decoration: const InputDecoration(labelText: 'Relation')),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel', style: GoogleFonts.nunito(color: Colors.grey[600])),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kAppBarColor),
                child: Text(existingMember == null ? 'Add' : 'Save', style: GoogleFonts.nunito()),
                onPressed: () async {
                  if (nameController.text.isNotEmpty && relationController.text.isNotEmpty && imagePath != null) {
                    Navigator.of(context).pop({
                      'name': nameController.text,
                      'relation': relationController.text,
                      'imagePath': imagePath,
                    });
                  }
                },
              ),
            ],
          );
        });
      },
    );

    if (result != null) {
      String finalImagePath;
      if (result['imagePath'] != existingMember?.imagePath) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${result['name'].replaceAll(' ', '_')}-${DateTime.now().millisecondsSinceEpoch}.png';
        final savedImageFile = File(path.join(appDir.path, fileName));
        await File(result['imagePath']!).copy(savedImageFile.path);
        finalImagePath = savedImageFile.path;

        if (existingMember?.imagePath != null) {
          final oldFile = File(existingMember!.imagePath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }
      } else {
        finalImagePath = existingMember!.imagePath;
      }

      final newMember = FamilyMember(
          name: result['name'],
          relation: result['relation'],
          imagePath: finalImagePath
      );

      setState(() {
        if (existingMember != null && existingMemberIndex != null) {
          _familyMembers[existingMemberIndex] = newMember;
        } else {
          _familyMembers.add(newMember);
        }
      });
      _saveFamilyMembers();
    }
  }

  // --- Delete Confirmation ---
  void _confirmDelete(FamilyMember member, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete ${member.name}?', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.red[700])),
          content: Text('Are you sure? This action cannot be undone.', style: GoogleFonts.nunito()),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: GoogleFonts.nunito(color: Colors.grey[600])),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: Text('Delete', style: GoogleFonts.nunito()),
              onPressed: () async {
                final imageFile = File(member.imagePath);
                if (await imageFile.exists()) {
                  await imageFile.delete();
                }
                setState(() {
                  _familyMembers.removeAt(index);
                });
                _saveFamilyMembers();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}