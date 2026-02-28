import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/analysis_repository.dart';
import '../cubit/analysis_cubit.dart';
import '../cubit/analysis_state.dart';

class AnalysisUploadPage extends StatelessWidget {
  const AnalysisUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalysisCubit(
        analysisRepository: AnalysisRepository(
          apiClient: ApiClient(secureStorage: SecureStorage()),
        ),
      ),
      child: const _AnalysisUploadContent(),
    );
  }
}

class _AnalysisUploadContent extends StatefulWidget {
  const _AnalysisUploadContent();

  @override
  State<_AnalysisUploadContent> createState() => _AnalysisUploadContentState();
}

class _AnalysisUploadContentState extends State<_AnalysisUploadContent> {
  final ImagePicker _picker = ImagePicker();
  final List<_ImageEntry> _chatImages = [];
  final List<_ImageEntry> _accountImages = [];
  final List<_ImageEntry> _transferImages = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnalysisCubit, AnalysisState>(
      listener: (context, state) {
        if (state is AnalysisCompleted) {
          final session = state.result['data']?['session'] ?? state.result['session'];
          final id = session?['id']?.toString();
          if (id != null) {
            context.push('/analysis/result/$id');
          }
        } else if (state is AnalysisError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.riskHigh),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('综合分析')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield, color: AppColors.textOnPrimary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '智能反诈分析',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '上传聊天截图、账号信息和转账记录，系统将综合分析诈骗风险',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textOnPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Chat screenshots (required)
              _buildImageSection(
                title: '聊天截图',
                subtitle: '必选，可多张',
                icon: Icons.chat_bubble_outline,
                images: _chatImages,
                imageType: 'chat',
                required: true,
              ),
              const SizedBox(height: 16),

              // Account info screenshots (optional)
              _buildImageSection(
                title: '账号信息截图',
                subtitle: '可选，对方资料页等',
                icon: Icons.person_outline,
                images: _accountImages,
                imageType: 'account_info',
                required: false,
              ),
              const SizedBox(height: 16),

              // Transfer record screenshots (optional)
              _buildImageSection(
                title: '转账记录截图',
                subtitle: '可选，转账/付款截图',
                icon: Icons.account_balance_wallet_outlined,
                images: _transferImages,
                imageType: 'transfer',
                required: false,
              ),
              const SizedBox(height: 32),

              // Submit button
              BlocBuilder<AnalysisCubit, AnalysisState>(
                builder: (context, state) {
                  final isSubmitting = state is AnalysisSubmitting || _isUploading;
                  return ElevatedButton(
                    onPressed: isSubmitting || _chatImages.isEmpty
                        ? null
                        : _onSubmit,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Text('开始分析'),
                  );
                },
              ),
              const SizedBox(height: 16),

              // History link
              Center(
                child: TextButton.icon(
                  onPressed: () => context.push('/analysis/history'),
                  icon: const Icon(Icons.history),
                  label: const Text('查看分析历史'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_ImageEntry> images,
    required String imageType,
    required bool required,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (required)
                  const Text(' *', style: TextStyle(color: AppColors.riskHigh)),
                const Spacer(),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...images.asMap().entries.map((entry) => _buildImageTile(
                      entry.value,
                      () => setState(() => images.removeAt(entry.key)),
                    )),
                _buildAddButton(() => _pickImage(images, imageType)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(_ImageEntry image, VoidCallback onRemove) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            image: image.path != null
                ? DecorationImage(
                    image: AssetImage(image.path!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: image.path == null
              ? const Center(child: Icon(Icons.image, color: AppColors.textHint))
              : null,
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.riskHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary, style: BorderStyle.solid),
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: const Center(
          child: Icon(Icons.add_photo_alternate, color: AppColors.primary),
        ),
      ),
    );
  }

  Future<void> _pickImage(List<_ImageEntry> targetList, String imageType) async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        for (final file in picked) {
          targetList.add(_ImageEntry(
            path: file.path,
            imageType: imageType,
          ));
        }
      });
    }
  }

  Future<void> _onSubmit() async {
    if (_chatImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少上传一张聊天截图')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final repository = AnalysisRepository(
        apiClient: ApiClient(secureStorage: SecureStorage()),
      );

      // Upload all images and collect URLs.
      final List<Map<String, String>> imageInputs = [];

      for (final images in [_chatImages, _accountImages, _transferImages]) {
        for (final img in images) {
          // Get presigned URL.
          final ext = img.path?.split('.').last ?? 'jpg';
          final presignResult = await repository.getPresignedUrl(ext);
          final uploadUrl = presignResult['data']?['upload_url'] as String? ?? '';
          final fileUrl = presignResult['data']?['file_url'] as String? ?? '';

          if (fileUrl.isNotEmpty) {
            imageInputs.add({
              'image_url': fileUrl,
              'image_type': img.imageType,
            });
          }
        }
      }

      if (!mounted) return;

      // Submit analysis.
      context.read<AnalysisCubit>().submitAnalysis(imageInputs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败: $e'), backgroundColor: AppColors.riskHigh),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _ImageEntry {
  final String? path;
  final String imageType;

  _ImageEntry({this.path, required this.imageType});
}
