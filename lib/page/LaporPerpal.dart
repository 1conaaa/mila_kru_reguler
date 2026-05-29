import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/main.dart';
import 'package:mila_kru_reguler/api/ApiHelperSaveLaporPerpal.dart';
import 'package:image_picker/image_picker.dart';

class LaporKondisiBus extends StatefulWidget {
  const LaporKondisiBus({Key? key}) : super(key: key);

  @override
  _LaporKondisiBusState createState() => _LaporKondisiBusState();
}

class _LaporKondisiBusState extends State<LaporKondisiBus> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String selectedKategori = '1';
  List<File> _imageFiles = [];
  int? idUser;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('idUser');
    });
  }

  @override
  void dispose() {
    _lokasiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.camera_alt, color: Colors.blue),
            SizedBox(width: 10),
            Text('Ambil Foto', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue.shade700),
              ),
              title: const Text('Ambil Foto', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 2048 * 1024; // 2MB in bytes

        if (fileSize > maxSize) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ukuran file melebihi 2MB. Silakan pilih file yang lebih kecil.'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }

        setState(() {
          _imageFiles.add(file);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _clearForm() {
    _lokasiController.clear();
    _keteranganController.clear();
    setState(() {
      _imageFiles.clear();
      selectedKategori = '1';
    });
  }

  Future<void> _submitForm(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      await SaveKondisiBus.saveLaporanKondisiBus(
        context: context,
        lokasi: _lokasiController.text.trim(),
        kategori: selectedKategori,
        keterangan: _keteranganController.text.trim(),
        imageFiles: _imageFiles,
      ).then((_) {
        if (mounted) {
          _clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Laporan berhasil disimpan'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade300],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: idUser != null
                          ? () => _scaffoldKey.currentState?.openDrawer()
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Laporan Armada',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Laporkan kondisi armada dengan mudah',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bus_alert, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade50, Colors.blue.shade100],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.edit_note, color: Colors.blue.shade800, size: 28),
                              ),
                              const SizedBox(width: 15),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Form Laporan',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Isi data laporan dengan lengkap',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Form Section
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Lokasi Field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade200,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _lokasiController,
                                  decoration: InputDecoration(
                                    labelText: 'Lokasi',
                                    hintText: 'Masukkan lokasi kejadian',
                                    prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade700),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  validator: (value) =>
                                  value?.isEmpty ?? true ? 'Lokasi harus diisi' : null,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Kategori Dropdown
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade200,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Kategori',
                                    prefixIcon: Icon(Icons.category, color: Colors.blue.shade700),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  initialValue: selectedKategori,
                                  items: const [
                                    DropdownMenuItem(value: '1', child: Text('🚌 Operasi')),
                                    DropdownMenuItem(value: '2', child: Text('🔧 Kerusakan')),
                                    DropdownMenuItem(value: '3', child: Text('⚠️ Kecelakaan')),
                                    DropdownMenuItem(value: '4', child: Text('👥 Penumpang')),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => selectedKategori = value ?? '1'),
                                  validator: (value) =>
                                  value == null ? 'Pilih Kategori harus diisi' : null,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Keterangan Field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade200,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _keteranganController,
                                  decoration: InputDecoration(
                                    labelText: 'Keterangan',
                                    hintText: 'Jelaskan detail kejadian...',
                                    prefixIcon: Icon(Icons.description, color: Colors.blue.shade700),
                                    alignLabelWithHint: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  maxLines: 4,
                                  validator: (value) =>
                                  value?.isEmpty ?? true ? 'Keterangan harus diisi' : null,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Image Upload Section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade50,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.photo_camera, color: Colors.blue.shade700),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Dokumentasi Foto',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (_imageFiles.isNotEmpty) ...[
                                      SizedBox(
                                        height: 120,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _imageFiles.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              margin: const EdgeInsets.only(right: 12),
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    width: 120,
                                                    height: 120,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Image.file(
                                                        _imageFiles[index],
                                                        width: 120,
                                                        height: 120,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: GestureDetector(
                                                      onTap: () => _removeImage(index),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.red,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    ElevatedButton.icon(
                                      onPressed: _showImageSourceDialog,
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Ambil Foto'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade200,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : () => _submitForm(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save),
                                      SizedBox(width: 10),
                                      Text(
                                        'Simpan Laporan',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: idUser != null ? buildDrawer(context, idUser!) : null,
    );
  }
}