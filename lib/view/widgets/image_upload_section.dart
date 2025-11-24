import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

class ImageUploadSection extends StatelessWidget {
  final TagTransaksi tag;

  /// PERUBAHAN PENTING: sekarang mengirim XFile, bukan bool
  final Function(TagTransaksi, XFile) onImageUpload;

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
          Text(
            'Bukti ${tag.nama}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: hasImage ? Colors.green[50] : Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildImagePreview(hasImage, context),
                  SizedBox(width: 12),
                  Expanded(child: _buildActionButtons(tag, hasImage, context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(bool hasImage, BuildContext context) {
    final imagePath = uploadedImages[tag.id];

    return GestureDetector(
      onTap: hasImage
          ? () => _showImageZoomDialog(context, imagePath!)
          : null,
      onHorizontalDragEnd: hasImage
          ? (_) => _showReplaceImageDialog(context)
          : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? Colors.green : Colors.grey[400]!,
            width: hasImage ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasImage && imagePath != null
              ? Image.file(File(imagePath), fit: BoxFit.cover)
              : Center(
            child: Icon(
              Icons.photo_camera_outlined,
              color: Colors.grey[500],
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  void _showImageZoomDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1,
          maxScale: 4,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }

  /// PERBAIKAN: sekarang ambil foto, lalu kirim XFile ke parent
  void _showReplaceImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ganti Foto'),
        content: Text('Pilih sumber untuk mengganti foto ${tag.nama}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final picker = ImagePicker();
              final XFile? foto = await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 70,
              );

              if (foto != null) {
                onImageUpload(tag, foto);
              }
            },
            child: Text('Kamera'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      TagTransaksi tag,
      bool hasImage,
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasImage)
          _buildUploadButton(
            icon: Icons.camera_alt,
            text: 'Ambil Foto',
            color: Colors.blue,
            onTap: () async {
              final picker = ImagePicker();
              final XFile? foto = await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 70,
              );

              if (foto != null) {
                print('📸 FOTO DIAMBIL untuk tag ${tag.nama}: ${foto.path}');
                await onImageUpload(tag, foto);
              }
            },
          )
        else ...[
          Text(
            'Bukti foto sudah diupload',
            style: TextStyle(
              color: Colors.green[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildSmallButton(
                icon: Icons.camera_alt,
                text: 'Ganti Foto',
                onTap: () => _showReplaceImageDialog(context),
              ),
              SizedBox(width: 8),
              _buildSmallButton(
                icon: Icons.delete,
                text: 'Hapus',
                color: Colors.red,
                onTap: () {
                  print('🗑️ HAPUS FOTO untuk tag ${tag.nama}');
                  onRemoveImage(tag);
                },
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
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String text,
    Color color = Colors.blue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
