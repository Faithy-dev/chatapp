import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../../../core/constants/cloudinary_config.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mediaServiceProvider = Provider((ref) => MediaService());

class MediaService {
  final _cloudinary = CloudinaryPublic(
    CloudinaryConfig.cloudName,
    CloudinaryConfig.uploadPreset,
    cache: false,
  );
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return null;

    return _compressImage(File(pickedFile.path));
  }

  Future<File?> pickVideo() async {
    final pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (pickedFile == null) return null;

    return _compressVideo(File(pickedFile.path));
  }

  Future<File> _compressVideo(File file) async {
    final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.DefaultQuality,
      deleteOrigin: false,
    );

    if (mediaInfo != null && mediaInfo.file != null) {
      return mediaInfo.file!;
    }
    return file;
  }

  Future<File> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/${const Uuid().v4()}.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
      format: CompressFormat.jpeg,
    );

    return File(result!.path);
  }

  Future<String> uploadFile(File file, String folder, {Function(double)? onProgress}) async {
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        folder: folder,
        resourceType: CloudinaryResourceType.Auto,
      ),
      onProgress: (count, total) {
        if (onProgress != null) {
          onProgress(count / total);
        }
      },
    );

    return response.secureUrl;
  }
}
