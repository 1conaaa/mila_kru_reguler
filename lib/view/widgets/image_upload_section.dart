import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

class ImageUploadSection extends StatelessWidget {
  final TagTransaksi tag;
  final Function(TagTransaksi, bool) onImageUpload;
  final Map<int, String> uploadedImages;
  final Function(TagTransaksi) onRemoveImage;

  const ImageUploadSection({
    Key? key,
    required this.tag,
    required this.onImageUpload,
    required this.uploadedImages,
    required this.onRemoveImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasImage = uploadedImages.containsKey(tag.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'Bukti ${tag.nama}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),

          // Container utama
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: hasImage ? Colors.green : Colors.grey[300]!,
                width: hasImage ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: hasImage ? Colors.green[50] : Colors.grey[50],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Preview gambar
                  _buildImagePreview(hasImage),
                  SizedBox(width: 12),

                  // Tombol aksi
                  Expanded(
                    child: _buildActionButtons(hasImage, context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(bool hasImage) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: hasImage ? Colors.green[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasImage ? Colors.green : Colors.grey[400]!,
        ),
      ),
      child: hasImage
          ? Stack(
        children: [
          // Icon sukses
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green, size: 32),
                SizedBox(height: 4),
                Text(
                  'Terupload',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Tombol hapus kecil
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemoveImage(tag),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close,
                    color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      )
          : Center(
        child: Icon(Icons.photo_camera_outlined,
            color: Colors.grey[500], size: 28),
      ),
    );
  }

  Widget _buildActionButtons(bool hasImage, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasImage) ...[
          // Tombol ambil foto
          _buildUploadButton(
            icon: Icons.camera_alt,
            text: 'Ambil Foto',
            color: Colors.blue,
            onTap: () => onImageUpload(tag, true),
          ),
          SizedBox(height: 6),
          // Tombol pilih dari galeri
          _buildUploadButton(
            icon: Icons.photo_library,
            text: 'Pilih dari Galeri',
            color: Colors.green,
            onTap: () => onImageUpload(tag, false),
          ),
        ] else ...[
          // Jika sudah ada gambar
          Text(
            'Bukti foto sudah diupload',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              // Tombol ganti foto
              _buildSmallButton(
                icon: Icons.camera_alt,
                text: 'Ganti Foto',
                onTap: () => _showImageSourceDialog(context),
              ),
              SizedBox(width: 8),
              // Tombol hapus
              _buildSmallButton(
                icon: Icons.delete,
                text: 'Hapus',
                color: Colors.red,
                onTap: () => onRemoveImage(tag),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String text,
    Color color = Colors.blue,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ganti Foto'),
          content: Text('Pilih sumber foto untuk ${tag.nama}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onImageUpload(tag, true);
              },
              child: Text('Kamera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onImageUpload(tag, false);
              },
              child: Text('Galeri'),
            ),
          ],
        );
      },
    );
  }
}