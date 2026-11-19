import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/settings_model.dart';
import '../../services/locale_service.dart';
import 'settings_sub_page_mixin.dart';

class ProfileSubPage extends StatefulWidget {
  final SettingsModel settings;
  const ProfileSubPage({super.key, required this.settings});

  @override
  State<ProfileSubPage> createState() => _ProfileSubPageState();
}

class _ProfileSubPageState extends State<ProfileSubPage>
    with SettingsSubPageMixin {
  final _formKey = GlobalKey<FormState>();
  late final SettingsModel _s;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _alamatCtrl;
  late final TextEditingController _npwpCtrl;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
    _namaCtrl = TextEditingController(text: _s.namaToko);
    _alamatCtrl = TextEditingController(text: _s.alamat);
    _npwpCtrl = TextEditingController(text: _s.npwp);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _npwpCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(tr('settings.gallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(tr('settings.camera')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_s.hasLogo)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(tr('settings.delete_logo'),
                    style: const TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _s.logoBytes = null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _s.logoBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.store_profile'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Logo
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant, width: 0.8),
                        image: _s.hasLogo
                            ? DecorationImage(
                                image: MemoryImage(_s.logoBytes!),
                                fit: BoxFit.contain)
                            : null,
                      ),
                      child: _s.hasLogo
                          ? null
                          : Icon(Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            buildField(controller: _namaCtrl, label: tr('settings.store_name'), required: true),
            const SizedBox(height: 14),
            buildField(controller: _npwpCtrl, label: 'NPWP', hint: 'cth: 00.000.000.0-000.000', keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            buildField(controller: _alamatCtrl, label: tr('settings.address'), maxLines: 3),
            const SizedBox(height: 32),
            buildSaveButton(theme, () {
              if (!_formKey.currentState!.validate()) return;
              _s
                ..namaToko = _namaCtrl.text
                ..alamat = _alamatCtrl.text
                ..npwp = _npwpCtrl.text;
              saveSettings(_s);
            }),
          ],
        ),
      ),
    );
  }
}
