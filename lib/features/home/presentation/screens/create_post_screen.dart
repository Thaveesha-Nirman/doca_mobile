import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/community_post.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    this.onSubmit,
    this.parentPost,
    this.editingPost,
    super.key,
  });

  final ValueChanged<CommunityPost>? onSubmit;
  final CommunityPost? parentPost;
  final CommunityPost? editingPost;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const _statusOptions = [
    {'value': 'Asking', 'label': 'Just Asking'},
    {'value': 'Ongoing', 'label': 'Ongoing Treatment'},
    {'value': 'Healed', 'label': 'Healed'},
  ];
  static const int _maxPhotos = 3;

  String _selectedStatus = 'Asking';
  bool _isSensitive = false;
  bool _isSubmitting = false;

  final List<Uint8List> _photoBytes = [];
  final List<String> _photoBase64 = [];

  bool get _isEditing => widget.editingPost != null;
  bool get _isAddingUpdate => widget.parentPost != null && !_isEditing;

  @override
  void initState() {
    super.initState();
    final edit = widget.editingPost;
    if (edit != null) {
      _titleController.text = edit.title;
      _bodyController.text = edit.body;
      _selectedStatus = edit.status;
      _isSensitive = edit.isSensitive;
      for (final raw in edit.images) {
        try {
          final clean = raw.contains(',') ? raw.split(',').last : raw;
          _photoBytes.add(base64Decode(clean));
          _photoBase64.add(clean);
        } catch (_) {}
      }
    } else if (_isAddingUpdate) {
      _selectedStatus = 'Ongoing';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photoBytes.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can attach up to 3 photos.')),
      );
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        imageQuality: 65,
      );

      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes.add(bytes);
        _photoBase64.add(base64Encode(bytes));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick photo: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoBytes.removeAt(index);
      _photoBase64.removeAt(index);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      Map<String, dynamic> result;
      if (_isEditing) {
        result = await ApiService.instance.updatePost(
          postId: widget.editingPost!.id,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          status: _selectedStatus,
          images: _photoBase64,
          isSensitive: _isSensitive,
        );
      } else {
        result = await ApiService.instance.createPost(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          status: _selectedStatus,
          images: _photoBase64,
          isSensitive: _isSensitive,
          parentPostId: widget.parentPost?.id,
        );
      }

      final postJson = result['post'] as Map<String, dynamic>;
      final savedPost = CommunityPost.fromJson(postJson);

      if (!mounted) return;
      widget.onSubmit?.call(savedPost);
      Navigator.of(context).pop(savedPost);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Failed to save post: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle = _isEditing
        ? 'Edit Post'
        : _isAddingUpdate
            ? 'Add Journey Update'
            : 'Create Post';

    final buttonLabel = _isSubmitting
        ? 'Saving...'
        : _isEditing
            ? 'Save Changes'
            : _isAddingUpdate
                ? 'Publish Update'
                : 'Publish Post';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          screenTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              if (_isAddingUpdate) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Linked to journey: "${widget.parentPost!.title}"',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _buildPrivacyNotice(),
              const SizedBox(height: AppSpacing.xl),
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                hint: _isAddingUpdate
                    ? 'e.g. Week 2 update — redness going down'
                    : 'What would you like to ask or share?',
                maxLength: 100,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Please enter a title';
                  if (text.length < 5) {
                    return 'Title must contain at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _bodyController,
                label: 'Description',
                hint: 'Share symptoms, treatments, or recovery details.',
                maxLength: 1000,
                maxLines: 6,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Please enter a description';
                  if (text.length < 10) {
                    return 'Description must contain at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Status',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _statusOptions.map((opt) {
                  final val = opt['value']!;
                  final label = opt['label']!;
                  return ChoiceChip(
                    label: Text(label),
                    selected: _selectedStatus == val,
                    onSelected: (_) => setState(() => _selectedStatus = val),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Photos (Optional)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPhotoPickerSection(),
              const SizedBox(height: AppSpacing.xl),
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  value: _isSensitive,
                  onChanged: (value) => setState(() => _isSensitive = value),
                  activeThumbColor: AppColors.primary,
                  title: const Text(
                    'Sensitive medical content',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Blur photos until the viewer taps to reveal.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _photoBytes.length >= _maxPhotos ? null : _pickPhoto,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            _photoBytes.isEmpty
                ? 'Add photo'
                : 'Add another photo (${_photoBytes.length}/$_maxPhotos)',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
        if (_photoBytes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photoBytes.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.memory(
                        _photoBytes[index],
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.secondary),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Avoid sharing real names, addresses, or contact details.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLength,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}