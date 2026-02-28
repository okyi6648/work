import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/validators.dart';
import '../../data/appeal_repository.dart';

class AppealFormPage extends StatefulWidget {
  const AppealFormPage({super.key});

  @override
  State<AppealFormPage> createState() => _AppealFormPageState();
}

class _AppealFormPageState extends State<AppealFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();

  final List<XFile> _evidenceImages = [];
  bool _isSubmitting = false;

  late final AppealRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = AppealRepository(
      apiClient: ApiClient(secureStorage: SecureStorage()),
    );
  }

  @override
  void dispose() {
    _accountIdController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (images.isNotEmpty) {
      setState(() => _evidenceImages.addAll(images));
    }
  }

  void _removeEvidence(int index) {
    setState(() => _evidenceImages.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await _repository.submitAppeal({
        'account_id': _accountIdController.text.trim(),
        'phone': _phoneController.text.trim(),
        'reason': _reasonController.text.trim(),
      });

      if (mounted) {
        final appealId = result['id'] as String? ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('申诉提交成功'),
            backgroundColor: AppColors.riskSafe,
          ),
        );
        context.go('/appeal/$appealId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('提交失败，请重试'),
            backgroundColor: AppColors.riskHigh,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发起申诉'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertInfo.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.alertInfo.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: AppColors.alertInfo),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '如果您的账号被误标记，可以通过此表单提交申诉。',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account ID
              TextFormField(
                controller: _accountIdController,
                validator: Validators.required,
                decoration: const InputDecoration(
                  labelText: '被标记的账号ID',
                  hintText: '请输入被标记的账号',
                  prefixIcon: Icon(Icons.account_circle),
                ),
              ),
              const SizedBox(height: 16),

              // Phone verification
              TextFormField(
                controller: _phoneController,
                validator: Validators.phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '手机号（用于验证身份）',
                  hintText: '请输入注册手机号',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),

              // Reason
              TextFormField(
                controller: _reasonController,
                validator: Validators.required,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: '申诉理由',
                  hintText: '请详细说明您认为标记有误的原因...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.edit_note),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Evidence upload
              const Text(
                '证据材料',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._evidenceImages.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                            color: AppColors.background,
                          ),
                          child: const Center(
                            child:
                                Icon(Icons.image, color: AppColors.textHint),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => _removeEvidence(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.riskHigh,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: _pickEvidence,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        color: AppColors.background,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              color: AppColors.textHint),
                          SizedBox(height: 4),
                          Text(
                            '添加',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('提交申诉'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
