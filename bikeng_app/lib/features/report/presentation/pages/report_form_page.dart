import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/validators.dart';
import '../../data/report_repository.dart';
import '../cubit/report_cubit.dart';
import '../cubit/report_state.dart';

class ReportFormPage extends StatelessWidget {
  const ReportFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportCubit(
        reportRepository: ReportRepository(
          apiClient: ApiClient(secureStorage: SecureStorage()),
        ),
      ),
      child: const _ReportFormContent(),
    );
  }
}

class _ReportFormContent extends StatefulWidget {
  const _ReportFormContent();

  @override
  State<_ReportFormContent> createState() => _ReportFormContentState();
}

class _ReportFormContentState extends State<_ReportFormContent> {
  int _currentStep = 0;

  // Step 1: Account info
  String _accountType = 'phone';
  final _accountValueController = TextEditingController();

  // Step 2: Scam details
  String _scamType = 'investment';
  final _descriptionController = TextEditingController();
  final _lossAmountController = TextEditingController();
  DateTime? _incidentDate;

  // Step 3: Evidence
  final List<XFile> _evidenceImages = [];
  final List<String> _uploadedUrls = [];
  final bool _isUploading = false;

  // Step 4: Confirm
  bool _liabilityAgreed = false;

  final _accountTypes = {
    'phone': '手机号',
    'qq': 'QQ',
    'wechat': '微信',
    'alipay': '支付宝',
    'bank_card': '银行卡',
  };

  final _scamTypes = {
    'investment': '投资理财诈骗',
    'shopping': '网购诈骗',
    'impersonation': '冒充客服/公检法',
    'romance': '杀猪盘/交友诈骗',
    'loan': '贷款诈骗',
    'gambling': '赌博诈骗',
    'other': '其他',
  };

  @override
  void dispose() {
    _accountValueController.dispose();
    _descriptionController.dispose();
    _lossAmountController.dispose();
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
    setState(() {
      _evidenceImages.removeAt(index);
      if (index < _uploadedUrls.length) {
        _uploadedUrls.removeAt(index);
      }
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _incidentDate = date);
    }
  }

  Future<void> _submitReport() async {
    if (!_liabilityAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先同意责任声明')),
      );
      return;
    }

    final data = {
      'account_type': _accountType,
      'account_value': _accountValueController.text.trim(),
      'scam_type': _scamType,
      'description': _descriptionController.text.trim(),
      'loss_amount': double.tryParse(_lossAmountController.text) ?? 0,
      'incident_date': _incidentDate?.toIso8601String(),
      'evidence_urls': _uploadedUrls,
    };

    context.read<ReportCubit>().submitReport(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('举报'),
      ),
      body: BlocListener<ReportCubit, ReportState>(
        listener: (context, state) {
          if (state is ReportSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('举报提交成功'),
                backgroundColor: AppColors.riskSafe,
              ),
            );
            context.pop();
          } else if (state is ReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.riskHigh,
              ),
            );
          }
        },
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _submitReport();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 3 ? '提交举报' : '下一步'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(_currentStep == 0 ? '取消' : '上一步'),
                  ),
                ],
              ),
            );
          },
          steps: [
            // Step 1: Account info
            Step(
              title: const Text('账号信息'),
              subtitle: const Text('填写被举报账号'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _accountType,
                    decoration: const InputDecoration(
                      labelText: '账号类型',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _accountTypes.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _accountType = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accountValueController,
                    validator: Validators.required,
                    decoration: const InputDecoration(
                      labelText: '账号/号码',
                      hintText: '请输入被举报的账号',
                      prefixIcon: Icon(Icons.account_circle),
                    ),
                  ),
                ],
              ),
            ),

            // Step 2: Scam details
            Step(
              title: const Text('诈骗详情'),
              subtitle: const Text('描述受骗经过'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _scamType,
                    decoration: const InputDecoration(
                      labelText: '诈骗类型',
                      prefixIcon: Icon(Icons.warning_amber),
                    ),
                    items: _scamTypes.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _scamType = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: '详细描述',
                      hintText: '请描述受骗经过...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 64),
                        child: Icon(Icons.description),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lossAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: '损失金额 (元)',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      _incidentDate != null
                          ? DateFormat('yyyy-MM-dd').format(_incidentDate!)
                          : '选择受骗日期',
                      style: TextStyle(
                        color: _incidentDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectDate,
                  ),
                ],
              ),
            ),

            // Step 3: Evidence upload
            Step(
              title: const Text('上传证据'),
              subtitle: const Text('聊天截图、转账记录等'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                border:
                                    Border.all(color: AppColors.border),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder<List<int>>(
                                  future: entry.value.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data! as dynamic,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                ),
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
                      // Add button
                      GestureDetector(
                        onTap: _pickEvidence,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border,
                              style: BorderStyle.solid,
                            ),
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
                  if (_isUploading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 4),
                    const Text(
                      '正在上传...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    '支持上传聊天截图、转账记录、合同等证据图片',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),

            // Step 4: Review and confirm
            Step(
              title: const Text('确认提交'),
              subtitle: const Text('核对信息并提交'),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(
                    label: '账号类型',
                    value: _accountTypes[_accountType] ?? '',
                  ),
                  _SummaryRow(
                    label: '账号',
                    value: _accountValueController.text,
                  ),
                  _SummaryRow(
                    label: '诈骗类型',
                    value: _scamTypes[_scamType] ?? '',
                  ),
                  _SummaryRow(
                    label: '描述',
                    value: _descriptionController.text.isNotEmpty
                        ? _descriptionController.text
                        : '未填写',
                  ),
                  _SummaryRow(
                    label: '损失金额',
                    value: _lossAmountController.text.isNotEmpty
                        ? '${_lossAmountController.text} 元'
                        : '未填写',
                  ),
                  _SummaryRow(
                    label: '受骗日期',
                    value: _incidentDate != null
                        ? DateFormat('yyyy-MM-dd').format(_incidentDate!)
                        : '未选择',
                  ),
                  _SummaryRow(
                    label: '证据图片',
                    value: '${_evidenceImages.length} 张',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _liabilityAgreed,
                          onChanged: (v) =>
                              setState(() => _liabilityAgreed = v ?? false),
                          activeColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '我保证以上提交的信息真实有效，如有虚假举报，愿承担相应法律责任。',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
