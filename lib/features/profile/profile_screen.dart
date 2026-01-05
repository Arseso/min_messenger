import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:typed_data';
import '../../data/services/user_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/validation_service.dart';
import '../chat_room/widgets/avatar.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _oldPasswordController = TextEditingController();

  final _nameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _isPasswordChanging = false;
  bool _isSaving = false;

  bool _obscureNewPassword = true;
  bool _obscureOldPassword = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = AuthService.currentUser?['username'] ?? "";
  }

  void _save() async {
    if (!_nameFormKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final error = await UserService.updateProfile(
      _nameController.text.trim(),
      AuthService.currentUser?['avatar_url']
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Профиль обновлен"), backgroundColor: Colors.green)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red)
      );
      _nameController.text = AuthService.currentUser?['username'] ?? "";
    }
  }

  void _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isPasswordChanging = true);
    bool success = await UserService.changePassword(
      _oldPasswordController.text,
      _newPasswordController.text
    );
    setState(() => _isPasswordChanging = false);

    if (success) {
      _newPasswordController.clear();
      _oldPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пароль успешно изменен!"), backgroundColor: Colors.green)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка: неверный старый пароль"), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _pickAndEditAvatar() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Редактор аватара',
          toolbarColor: Colors.blueAccent,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        WebUiSettings(
          context: context,
          size: const CropperSize(width: 500, height: 500),
        ),
      ],
    );

    if (croppedFile != null) {
      _showConfirmDialog(XFile(croppedFile.path));
    }
  }

  void _showConfirmDialog(XFile imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
             child: Text("Новый аватар", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 80, backgroundImage: MemoryImage(bytes)),
            const SizedBox(height: 15),
            const Text("Установить это фото?"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              String? newUrl = await UserService.uploadAvatar(imageFile);
              if (newUrl != null) setState(() {});
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Профиль", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAndEditAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 4),
                      ),
                      child: buildAvatar(AuthService.currentUser?['avatar_url'], radius: 70),
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 20,
                      child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Form(
              key: _nameFormKey,
              child: _buildSectionCard(
                title: "Личные данные",
                child: Column(
                  children: [
                    _buildTextFormField(
                      controller: _nameController,
                      label: "Никнейм",
                      icon: Icons.alternate_email,
                      validator: ValidationService.validateUsername,
                    ),
                    const SizedBox(height: 20),
                    _buildPrimaryButton(
                      text: "Сохранить изменения",
                      onPressed: _isSaving ? null : _save,
                      color: Colors.blueAccent,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Form(
              key: _passwordFormKey,
              child: _buildSectionCard(
                title: "Безопасность",
                child: Column(
                  children: [
                    _buildTextFormField(
                      controller: _newPasswordController,
                      label: "Новый пароль",
                      icon: Icons.lock_outline,
                      isPassword: _obscureNewPassword,
                      validator: ValidationService.validatePassword,
                      onChanged: (v) => setState(() {}),
                      suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(
                              _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.black38,
                            ),
                            onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                          ),
                      ),
                    ),
                    if (_newPasswordController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _oldPasswordController,
                        label: "Старый пароль",
                        icon: Icons.verified_user_outlined,
                        isPassword: _obscureOldPassword,
                        fillColor: Colors.orange.shade50,
                        validator: (v) => (v == null || v.isEmpty) ? "Введите старый пароль" : null,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Icon(
                              _obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.black38,
                            ),
                            onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildPrimaryButton(
                      text: "Обновить пароль",
                      onPressed: _newPasswordController.text.isEmpty || _isPasswordChanging ? null : _changePassword,
                      color: Colors.orangeAccent,
                      isLoading: _isPasswordChanging,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    Color? fillColor,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor ?? const Color(0xFFF1F3F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        errorStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    required Color color,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}