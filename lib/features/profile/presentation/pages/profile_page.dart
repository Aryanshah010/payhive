import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/app/theme/theme_notifier.dart';
import 'package:payhive/core/api/api_endpoints.dart';
import 'package:payhive/core/services/notifications/notification_push_service.dart';
import 'package:payhive/core/utils/snackbar_util.dart';
import 'package:payhive/core/widgets/main_text_form_field.dart';
import 'package:payhive/core/widgets/primary_button_widget.dart';
import 'package:payhive/features/auth/presentation/pages/login_page.dart';
import 'package:payhive/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:payhive/core/services/storage/biometric_storage_service.dart';
import 'package:payhive/features/dashboard/presentation/widgets/menu_item_widgets.dart';
import 'package:payhive/features/profile/domain/usecases/verify_pin_usecase.dart';
import 'package:payhive/features/profile/presentation/pages/fingerprint_setup_sheet.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/pages/pin_management_page.dart';
import 'package:payhive/features/profile/presentation/pages/update_profile_page.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/devices/presentation/pages/manage_devices_page.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfilePage> {
  XFile? _localPreviewImage;
  final ImagePicker _imagePicker = ImagePicker();

  Future<bool> _verifyPinBeforeSensitiveNavigation() async {
    final hasPin = ref.read(profileViewModelProvider).hasPin;
    if (!hasPin) {
      SnackbarUtil.showError(context, 'Please set your PIN first.');
      AppRoutes.push(context, const PinManagementPage(hasPin: false));
      return false;
    }

    final allowed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return const _PinVerificationSheet();
      },
    );
    return allowed ?? false;
  }

  Future<bool> _askPermissionFromUser(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) {
      return true;
    }
    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return false;
    }
    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "This feature requires permission to access your  gallery. Please enable it in your device settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _localPreviewImage = image);

        await ref
            .read(profileViewModelProvider.notifier)
            .uploadImage(File(image.path));
      }
    } catch (e) {
      debugPrint("Gallery error $e");
      if (mounted) {
        SnackbarUtil.showError(context, 'Unable to access gallery');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final double scale = isTablet ? 1.25 : 1.0;

    ref.listen(profileViewModelProvider, (prev, next) {
      if (next.status == ProfileStatus.updated) {
        setState(() => _localPreviewImage = null);
      }

      if (next.status == ProfileStatus.error) {
        SnackbarUtil.showError(
          context,
          next.errorMessage ?? 'Something went wrong',
        );
      }
    });

    final fullName = profileState.fullName ?? '';
    final phone = profileState.phoneNumber ?? '';
    final email = profileState.email ?? '';
    final backendImage = profileState.imageUrl;
    final biometricEnabled = ref
        .watch(biometricStorageServiceProvider)
        .isEnabled();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20 * scale,
                  24 * scale,
                  20 * scale,
                  32 * scale,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 28 * scale),

                    // AVATAR
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 120 * scale,
                          height: 120 * scale,
                          padding: EdgeInsets.all(3 * scale),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5 * scale,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: SizedBox(
                                width: 112 * scale,
                                height: 112 * scale,
                                child: _localPreviewImage != null
                                    ? Image.file(
                                        File(_localPreviewImage!.path),
                                        fit: BoxFit.cover,
                                      )
                                    : backendImage != null
                                    ? Image.network(
                                        ApiEndpoints.mediaServerUrl +
                                            backendImage,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return _buildInitialAvatar(
                                                fullName,
                                                scale,
                                              );
                                            },
                                      )
                                    : _buildInitialAvatar(fullName, scale),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            bool granted = await _askPermissionFromUser(
                              Permission.photos,
                            );
                            if (!granted) return;
                            await _pickFromGallery();
                          },
                          child: Container(
                            padding: EdgeInsets.all(6 * scale),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1 * scale,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 18 * scale,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16 * scale),
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24 * scale),

              // MENU CARD
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8 * scale),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.12),
                        blurRadius: 20 * scale,
                        offset: Offset(0, 8 * scale),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      MenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Update Profile',
                        onTap: () async {
                          final isVerified =
                              await _verifyPinBeforeSensitiveNavigation();
                          if (!context.mounted || !isVerified) return;
                          AppRoutes.push(context, const UpdateProfilePage());
                        },
                      ),
                      _divider(context),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                0,
                                12 * scale,
                                0,
                                8 * scale,
                              ),
                              child: Text(
                                'Security',
                                style: TextStyle(
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            MenuItem(
                              icon: Icons.fingerprint_rounded,
                              title: 'Fingerprint',
                              trailing: biometricEnabled
                                  ? Text(
                                      'Enabled',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14 * scale,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (sheetContext) {
                                    return const FingerprintSetupSheet();
                                  },
                                );
                              },
                            ),
                            MenuItem(
                              icon: Icons.pin_rounded,
                              title: 'PIN',
                              onTap: () {
                                final hasPin = profileState.hasPin;
                                AppRoutes.push(
                                  context,
                                  PinManagementPage(hasPin: hasPin),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      _divider(context),
                      Consumer(
                        builder: (context, ref, _) {
                          final mode = ref.watch(themeNotifierProvider);
                          final isDark = mode == ThemeMode.dark;

                          return MenuItem(
                            icon: isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            title: isDark ? 'Light Mode' : 'Dark Mode',
                            trailing: Switch.adaptive(
                              value: isDark,
                              onChanged: (value) {
                                ref
                                    .read(themeNotifierProvider.notifier)
                                    .setTheme(
                                      value ? ThemeMode.dark : ThemeMode.light,
                                    );
                              },
                            ),
                            onTap: () {
                              ref.read(themeNotifierProvider.notifier).toggle();
                            },
                          );
                        },
                      ),

                      _divider(context),
                      MenuItem(
                        icon: Icons.devices_rounded,
                        title: 'Manage Devices',
                        onTap: () async {
                          final isVerified =
                              await _verifyPinBeforeSensitiveNavigation();
                          if (!context.mounted || !isVerified) return;
                          AppRoutes.push(context, const ManageDevicesPage());
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20 * scale),

              // LOGOUT
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: MenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  iconColor: AppColors.danger,
                  titleColor: AppColors.danger,
                  onTap: () => _showLogoutDialog(context),
                ),
              ),

              SizedBox(height: 32 * scale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String fullName, double scale) {
    return Center(
      child: Text(
        fullName.isNotEmpty ? fullName[0].toUpperCase() : '',
        style: TextStyle(
          fontSize: 44 * scale,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: colorScheme.outlineVariant),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(
                  dialogContext,
                ).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(notificationPushServiceProvider)
                  .clearServerFcmTokenOnLogout();
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) {
                AppRoutes.pushAndRemoveUntil(context, const LoginPage());
              }
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinVerificationSheet extends ConsumerStatefulWidget {
  const _PinVerificationSheet();

  @override
  ConsumerState<_PinVerificationSheet> createState() =>
      _PinVerificationSheetState();
}

class _PinVerificationSheetState extends ConsumerState<_PinVerificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_isLoading) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(verifyPinUsecaseProvider)(
      VerifyPinParams(pin: _pinController.text.trim()),
    );

    if (!mounted) return;

    result.fold((failure) {
      setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      });
    }, (_) => Navigator.of(context).pop(true));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Enter PIN',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify your 4-digit PIN to continue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 16),
                MainTextFormField(
                  controller: _pinController,
                  prefixIcon: Icons.lock_outline,
                  hintText: 'Enter PIN',
                  label: 'PIN',
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    final cleaned = value?.trim() ?? '';
                    if (cleaned.isEmpty) {
                      return 'Please enter your PIN';
                    }
                    if (!RegExp(r'^\d{4}$').hasMatch(cleaned)) {
                      return 'PIN must be exactly 4 digits.';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility_off : Icons.visibility,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                PrimaryButtonWidget(
                  onPressed: _isLoading ? () {} : _handleVerify,
                  isLoading: _isLoading,
                  text: 'Verify PIN',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
