import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/community_post.dart';
import '../../data/repositories/community_post_repository.dart';
import '../../data/repositories/temporary_local_community_post_repository.dart';
import 'post_preview_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    this.repository = const TemporaryLocalCommunityPostRepository(),
    this.onSubmit,
    super.key,
  });

  final CommunityPostRepository repository;
  final ValueChanged<CommunityPost>? onSubmit;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  static const List<String> _topics = [
    'General health',
    'Skin irritation',
    'Viral / flu',
    'Allergies',
    'Chronic care',
    'Recovery journey',
  ];

  static const List<String> _statuses = ['Asking', 'Ongoing', 'Healed'];

  String _selectedTopic = _topics.first;
  String _selectedStatus = _statuses.first;
  bool _isSensitive = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final CommunityPost draft = CommunityPost(
      alias: 'Anonymous',
      timeAgo: 'Just now',
      topic: _selectedTopic,
      status: _selectedStatus,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      votes: 0,
      comments: 0,
      isSensitive: _isSensitive,
    );

    final bool? published = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => PostPreviewScreen(post: draft),
      ),
    );

    if (!mounted) {
      return;
    }

    if (published != true) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    try {
      final CommunityPost post = await widget.repository.createPost(
        topic: _selectedTopic,
        status: _selectedStatus,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        isSensitive: _isSensitive,
      );

      if (!mounted) {
        return;
      }

      widget.onSubmit?.call(post);
      Navigator.of(context).pop(post);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to publish post. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Create post',
          style: TextStyle(fontWeight: FontWeight.w700),
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
              _buildPrivacyNotice(),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionTitle(
                title: 'Share anonymously',
                subtitle:
                    'Your real name and exact location will never be shown.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'What would you like to ask or share?',
                maxLength: 100,
                validator: (value) {
                  final String text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Please enter a title';
                  }

                  if (text.length < 5) {
                    return 'Title must contain at least 5 characters';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _bodyController,
                label: 'Post',
                hint: 'Describe your question, experience, or recovery update.',
                maxLength: 1000,
                maxLines: 7,
                validator: (value) {
                  final String text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Please enter your post';
                  }

                  if (text.length < 10) {
                    return 'Post must contain at least 10 characters';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionTitle(
                title: 'Topic',
                subtitle: 'Choose the topic that best matches your post.',
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _topics.map((topic) {
                  return ChoiceChip(
                    label: Text(topic),
                    selected: _selectedTopic == topic,
                    onSelected: (_) {
                      setState(() {
                        _selectedTopic = topic;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionTitle(
                title: 'Status',
                subtitle: 'Help others understand the purpose of your post.',
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _statuses.map((status) {
                  return ChoiceChip(
                    label: Text(status),
                    selected: _selectedStatus == status,
                    onSelected: (_) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                  );
                }).toList(),
              ),
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
                  onChanged: (value) {
                    setState(() {
                      _isSensitive = value;
                    });
                  },
                  activeThumbColor: AppColors.primary,
                  title: const Text(
                    'Sensitive medical content',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Enable this if the post may include sensitive details '
                    'or medical images.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitPost,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.visibility_outlined),
                label: Text(_isSubmitting ? 'Preparing...' : 'Preview post'),
              ),
            ],
          ),
        ),
      ),
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
              'Avoid sharing names, addresses, contact details, or other '
              'information that could identify you.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ],
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
