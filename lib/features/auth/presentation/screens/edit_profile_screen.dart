import 'package:material_ui/material_ui.dart';

import '../../../../core/models/doca_models.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _aliasController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();

  static const _genders = ['Male', 'Female', 'Prefer not to say'];

  late String _selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _aliasController.text = widget.profile.alias;
    _bioController.text = widget.profile.bio;
    if (widget.profile.age != null) {
      _ageController.text = '${widget.profile.age}';
    }
    _selectedGender = _genders.contains(widget.profile.gender)
        ? widget.profile.gender
        : 'Prefer not to say';
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final alias = _aliasController.text.trim();
    if (alias.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alias must be at least 3 characters.')),
      );
      return;
    }

    int? age;
    if (_ageController.text.trim().isNotEmpty) {
      age = int.tryParse(_ageController.text.trim());
      if (age == null || age < 13 || age > 120) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid age (13 - 120).')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final res = await ApiService.instance.updateMyProfile(
        alias: alias,
        bio: _bioController.text.trim(),
        gender: _selectedGender,
        age: age,
      );
      final updated = UserProfile.fromJson(res['user'] as Map<String, dynamic>);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Profile Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              controller: _aliasController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Anonymous Alias',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _bioController,
              maxLength: 200,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Short Bio (Optional)',
                hintText: 'Share a quick anonymous intro...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Gender',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genders.map((g) {
                return ChoiceChip(
                  label: Text(g),
                  selected: _selectedGender == g,
                  onSelected: (_) => setState(() => _selectedGender = g),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Age',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}