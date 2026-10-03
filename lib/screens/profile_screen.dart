import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/payroll_model.dart';
import '../services/localization_service.dart';
import '../services/exchange_rate_service.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser user;
  final bool isDarkMode;
  final AppLanguage language;
  final SalaryConfig salaryConfig;
  final Function(bool) onToggleDarkMode;
  final Function(AppUser) onUpdateUser;
  final Function(AppLanguage) onLanguageChanged;
  final Function(SalaryConfig) onUpdateSalaryConfig;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.language,
    required this.salaryConfig,
    required this.onToggleDarkMode,
    required this.onUpdateUser,
    required this.onLanguageChanged,
    required this.onUpdateSalaryConfig,
  });

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Tica Premium ✨', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'បង្កើនសមត្ថភាពផលិតភាពរបស់អ្នកជាមួយ Premium (\$2.99 / ខែ)៖',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildBenefitRow('⚡ ភ្ជាប់ទិន្នន័យផ្ទាល់ជាមួយ Google Calendar'),
            _buildBenefitRow('🎨 ប្ដូរពណ៌ Theme និងរូបតំណាងតាមចិត្ត'),
            _buildBenefitRow('📊 របាយការណ៍ Analytics លម្អិតជា PDF/Excel'),
            _buildBenefitRow('🚫 គ្មានផ្ទាំងពាណិជ្ជកម្មរំខាន (No Ads)'),
            _buildBenefitRow('☁️ Cloud Backup & ស្វ័យប្រវត្តិកម្មឆ្លងឧបករណ៍'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ទុកពេលក្រោយ'),
          ),
          ElevatedButton(
            onPressed: () {
              onUpdateUser(user.copyWith(isPremium: true));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 សូមអបអរសាទរ! គណនីរបស់អ្នកបានក្លាយជា Premium ហើយ!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ជាវឥឡូវនេះ (\$2.99)'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('កែប្រែព័ត៌មានគណនី'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'ឈ្មោះ (Full Name)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'អ៊ីមែល (Email)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            onPressed: () {
              onUpdateUser(user.copyWith(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('រក្សាទុក'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.language_rounded, color: Color(0xFF4F46E5), size: 26),
            SizedBox(width: 8),
            Text('ជ្រើសរើសភាសា / 언어 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context: context,
              title: 'ភាសាខ្មែរ (Khmer)',
              flag: '🇰🇭',
              subtitle: 'កម្ពុជា',
              lang: AppLanguage.khmer,
            ),
            const SizedBox(height: 6),
            _buildLanguageOption(
              context: context,
              title: '한국어 (Korean)',
              flag: '🇰🇷',
              subtitle: '대한민국',
              lang: AppLanguage.korean,
            ),
            const SizedBox(height: 6),
            _buildLanguageOption(
              context: context,
              title: 'English (US)',
              flag: '🇺🇸',
              subtitle: 'International',
              lang: AppLanguage.english,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String flag,
    required String subtitle,
    required AppLanguage lang,
  }) {
    final isSelected = language == lang;
    return InkWell(
      onTap: () {
        onLanguageChanged(lang);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌐 បានប្តូរភាសាទៅ $title រួចរាល់'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF4F46E5),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF4F46E5) : null,
                    ),
                  ),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4F46E5), size: 20),
          ],
        ),
      ),
    );
  }

  void _showExchangeRateDialog(BuildContext context) {
    final khrController =
        TextEditingController(text: salaryConfig.krwToKhrRate.toString());
    final usdController =
        TextEditingController(text: salaryConfig.krwToUsdRate.toString());
    bool isFetching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.currency_exchange_rounded,
                  color: Color(0xFF10B981), size: 26),
              SizedBox(width: 8),
              Text('ហាងឆេង និងអត្រាប្តូរប្រាក់',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'អត្រាប្តូរប្រាក់ពី វ៉ុនកូរ៉េ (KRW ₩) ទៅកាន់ រៀលខ្មែរ (KHR ៛) និង ដុល្លារ (USD \$)៖',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isFetching
                      ? null
                      : () async {
                          setDialogState(() => isFetching = true);
                          final result = await ExchangeRateService.fetchLiveRates();
                          setDialogState(() {
                            isFetching = false;
                            khrController.text = result.krwToKhr.toStringAsFixed(2);
                            usdController.text = result.krwToUsd.toStringAsFixed(6);
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.isLive
                                      ? '✅ បានទាញយកហាងឆេងថ្ងៃនេះផ្ទាល់ (1 ₩ = ${result.formattedKhrRate} ៛)'
                                      : 'ℹ️ ប្រើប្រាស់ហាងឆេងដែលបានរក្សាទុក (Offline)',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                  icon: isFetching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    isFetching
                        ? 'កំពុងទាញយក...'
                        : '🔄 ទាញយកហាងឆេងថ្ងៃនេះ (Live Rate)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: khrController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '1 KRW (₩) = ? KHR (៛)',
                    helperText: 'ហាងឆេងរៀល: ~3.00 ៛ (1 ម៉ឺនវ៉ុន ≈ 30,000 ៛)',
                    prefixIcon: const Icon(Icons.currency_exchange),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: usdController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '1 KRW (₩) = ? USD (\$)',
                    helperText: 'ហាងឆេងដុល្លារ: ~0.00074 \$',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('បោះបង់'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newKhr =
                    double.tryParse(khrController.text) ?? salaryConfig.krwToKhrRate;
                final newUsd =
                    double.tryParse(usdController.text) ?? salaryConfig.krwToUsdRate;

                final updated = SalaryConfig(
                  salaryType: salaryConfig.salaryType,
                  baseRate: salaryConfig.baseRate,
                  otHourlyRate: salaryConfig.otHourlyRate,
                  lateDeductionPerHour: salaryConfig.lateDeductionPerHour,
                  krwToKhrRate: newKhr,
                  krwToUsdRate: newUsd,
                );

                await ExchangeRateService.saveManualRates(newKhr, newUsd);
                onUpdateSalaryConfig(updated);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ បានរក្សាទុកអត្រាប្តូរប្រាក់ដោយជោគជ័យ'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('រក្សាទុក'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final langString = language == AppLanguage.khmer
        ? '🇰🇭 ភាសាខ្មែរ (Khmer)'
        : (language == AppLanguage.korean
            ? '🇰🇷 한국어 (Korean)'
            : '🇺🇸 English (US)');

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.tr('tab_profile', language),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF4F46E5),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isPremium) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade400,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditProfileDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Premium Subscription Banner
          if (!user.isPremium)
            GestureDetector(
              onTap: () => _showUpgradeDialog(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'ដំឡើងទៅ Tica Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ដោះសោ Sync Calendar, No Ads និងច្រើនទៀត',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Localization & Currency Settings Section
          Text(
            language == AppLanguage.korean
                ? '언어 및 환율 설정'
                : (language == AppLanguage.english
                    ? 'Language & Currency'
                    : 'ភាសា និងការគណនាប្រាក់ខែ'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Language Switcher Tile
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: isDark ? Colors.grey.shade900 : Colors.white,
            leading: const Icon(Icons.language_rounded,
                color: Color(0xFF4F46E5)),
            title: Text(LocalizationService.tr('language_setting', language)),
            subtitle: Text(langString),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
          const SizedBox(height: 8),

          // Exchange Rate Settings Tile
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: isDark ? Colors.grey.shade900 : Colors.white,
            leading: const Icon(Icons.currency_exchange_rounded,
                color: Color(0xFF10B981)),
            title: Text(LocalizationService.tr('rate_setting_title', language)),
            subtitle: Text(
                '1 ₩ = ${salaryConfig.krwToKhrRate} ៛ (1\$ = ${(1.0 / salaryConfig.krwToUsdRate).round()} ₩)'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showExchangeRateDialog(context),
          ),
          const SizedBox(height: 16),

          // General Settings Section
          Text(
            language == AppLanguage.korean
                ? '일반 설정'
                : (language == AppLanguage.english ? 'Preferences' : 'ការកំណត់ទូទៅ'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Offline Status Indicator
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: isDark ? Colors.grey.shade900 : Colors.white,
            leading: const Icon(Icons.cloud_done_rounded, color: Colors.green),
            title: const Text('មុខងារក្រៅបណ្តាញ (Offline Mode)'),
            subtitle: const Text('ទិន្នន័យត្រូវបានរក្សាទុកលើឧបករណ៍ដោយសុវត្ថិភាព'),
            trailing: const Icon(Icons.check, color: Colors.green, size: 20),
          ),
          const SizedBox(height: 8),

          // Dark Mode Toggle
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: isDark ? Colors.grey.shade900 : Colors.white,
            leading: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: const Color(0xFF4F46E5),
            ),
            title: const Text('រូបរាងងងឹត (Dark Theme)'),
            subtitle: Text(isDarkMode ? 'បើកដំណើរការ' : 'បិទដំណើរការ'),
            trailing: Switch(
              value: isDarkMode,
              activeColor: const Color(0xFF4F46E5),
              onChanged: onToggleDarkMode,
            ),
          ),
          const SizedBox(height: 8),

          // Authentication integrations
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: isDark ? Colors.grey.shade900 : Colors.white,
            leading:
                const Icon(Icons.security_rounded, color: Colors.blueAccent),
            title: const Text('ប្រព័ន្ធគណនី (Authentication)'),
            subtitle: const Text('Email, Google, Apple ID'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ភ្ជាប់គណនី Google/Apple ID រួចរាល់'),
                  backgroundColor: Color(0xFF4F46E5),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // About Khmer Salary
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: isDark ? Colors.grey.shade900 : Colors.white,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.info_outline_rounded, color: Colors.purple),
              ),
            ),
            title: const Text('អំពី Khmer Salary (ប្រាក់ខែខ្មែរ)'),
            subtitle: const Text('កំណែ ១.០.០ • Minute-Precision Payroll'),
          ),
        ],
      ),
    );
  }
}
