import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class AdminMenuManager extends StatefulWidget {
  const AdminMenuManager({super.key});

  @override
  State<AdminMenuManager> createState() => _AdminMenuManagerState();
}

class _AdminMenuManagerState extends State<AdminMenuManager> {
  final _menuRef = FirebaseFirestore.instance
      .collection(AppConstants.menuCollection);

  Future<void> _ensureMenuInitialized() async {
    final snap = await _menuRef.get();
    if (snap.docs.isEmpty) {
      for (final item in AppConstants.defaultMenu) {
        await _menuRef.add(item);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureMenuInitialized();
  }

  Future<String?> _uploadToImgBB(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': 'c884094eab963194499ec526484bbddc',
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showAddItemDialog({DocumentSnapshot? existing}) {
    final nameController = TextEditingController(
        text: existing != null ? (existing.data() as Map)['name'] ?? '' : '');
    final priceController = TextEditingController(
        text: existing != null
            ? (existing.data() as Map)['price'].toString()
            : '');
    String _safeCategory(String? cat) {
      const valid = ['Starters','Biryani','Curries','Rotis','Snacks','Drinks','Sweets','Ice Creams'];
      return valid.contains(cat) ? cat! : 'Snacks';
    }
    
String selectedCategory = existing != null
        ? _safeCategory((existing.data() as Map)['category'])
        : 'Snacks';

    bool available = existing != null
        ? (existing.data() as Map)['available'] ?? true
        : true;
    String existingImageUrl =
        existing != null ? (existing.data() as Map)['image'] ?? '' : '';

    File? pickedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Menu Item' : 'Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image preview
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70,
                      maxWidth: 800,
                    );
                    if (picked != null) {
                      setDialogState(() {
                        pickedFile = File(picked.path);
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.deepOrange.withOpacity(0.4),
                          width: 1.5),
                    ),
                    child: pickedFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              pickedFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : existingImageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  existingImageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(),
                                ),
                              )
                            : _imagePlaceholder(),
                  ),
                ),

                const SizedBox(height: 8),

                // Pick image button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                        maxWidth: 800,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          pickedFile = File(picked.path);
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library,
                        color: Colors.deepOrange),
                    label: Text(
                      pickedFile != null
                          ? 'Change Image'
                          : 'Pick from Gallery',
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepOrange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price (₹)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: AppConstants.categories
                      .where((c) => c != 'All')
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedCategory = v!),
                ),

                const SizedBox(height: 10),

                SwitchListTile(
                  title: const Text('Available'),
                  value: available,
                  activeColor: Colors.deepOrange,
                  onChanged: (v) => setDialogState(() => available = v),
                ),

                if (isUploading) ...[
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.deepOrange),
                      ),
                      SizedBox(width: 10),
                      Text('Uploading image...',
                          style: TextStyle(color: Colors.deepOrange)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange),
              onPressed: isUploading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final price =
                          int.tryParse(priceController.text.trim()) ?? 0;
                      if (name.isEmpty || price == 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Name and price are required')),
                        );
                        return;
                      }

                      String imageUrl = existingImageUrl;

                      // Upload new image if picked
                      if (pickedFile != null) {
                        setDialogState(() => isUploading = true);
                        final uploaded =
                            await _uploadToImgBB(pickedFile!);
                        setDialogState(() => isUploading = false);

                        if (uploaded == null) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Image upload failed. Check internet connection.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                        imageUrl = uploaded;
                      }

                      final data = {
                        'name': name,
                        'price': price,
                        'image': imageUrl,
                        'category': selectedCategory,
                        'available': available,
                      };

                      if (existing == null) {
                        await _menuRef.add(data);
                      } else {
                        await _menuRef.doc(existing.id).update(data);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: Text(
                existing == null ? 'Add' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate,
            color: Colors.deepOrange, size: 50),
        const SizedBox(height: 8),
        Text(
          'Tap to pick image from gallery',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _menuRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(child: Text('No menu items yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final data = item.data() as Map<String, dynamic>;
              final available = data['available'] ?? true;
              final image = data['image'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: available
                      ? BorderSide.none
                      : const BorderSide(color: Colors.red, width: 1),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image.isNotEmpty
                        ? Image.network(
                            image,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color:
                                  Colors.deepOrange.withOpacity(0.1),
                              child: const Icon(Icons.restaurant,
                                  color: Colors.deepOrange),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.deepOrange.withOpacity(0.1),
                            child: const Icon(Icons.restaurant,
                                color: Colors.deepOrange),
                          ),
                  ),
                  title: Text(
                    data['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: available ? Colors.black : Colors.grey,
                      decoration:
                          available ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    '₹${data['price']}  •  ${data['category'] ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: available,
                        activeColor: Colors.green,
                        onChanged: (v) =>
                            _menuRef.doc(item.id).update({'available': v}),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showAddItemDialog(existing: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Item?'),
                              content: Text(
                                  'Remove "${data['name']}" from menu?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _menuRef.doc(item.id).delete();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
