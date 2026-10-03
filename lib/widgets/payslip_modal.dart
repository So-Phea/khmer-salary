import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payroll_model.dart';
import '../models/user_model.dart';
import '../services/localization_service.dart';

class PayslipModal extends StatelessWidget {
  final AppUser user;
  final DateTime month;
  final SalaryConfig config;
  final PayrollCalculation calc;
  final AppLanguage language;
  final CurrencyType activeCurrency;

  const PayslipModal({
    super.key,
    required this.user,
    required this.month,
    required this.config,
    required this.calc,
    required this.language,
    required this.activeCurrency,
  });

  void _copyPayslipText(BuildContext context) {
    final regDurationStr =
        '${calc.regularHoursPart}시간 ${calc.regularMinutesPart}분 (${calc.regularHoursPart}ម៉ ${calc.regularMinutesPart}ន)';
    final otDurationStr =
        '${calc.otHoursPart}시간 ${calc.otMinutesPart}분 (${calc.otHoursPart}ម៉ ${calc.otMinutesPart}ន)';

    final text = '''
========================================
📋 급여명세서 / វិក្កយបត្រប្រាក់ខែ (Khmer Salary)
========================================
👤 성명 / ឈ្មោះបុគ្គលិក: ${user.name}
📅 귀속연월 / ប្រចាំខែ: ${month.year}년 ${month.month}월 (${month.month}/${month.year})
----------------------------------------
⏱️ 근태 및 근무내역 (정밀 근무시간):
- 총 근무일수 / ចំនួនថ្ងៃធ្វើការ: ${calc.totalWorkingDays}일 (ថ្ងៃ)
- 기본근무시간 / ម៉ោងធម្មតា: $regDurationStr
- 연장근로(OT) / ថែមម៉ោង: $otDurationStr
- 무단결근 / អវត្តមានឥតច្បាប់: ${calc.totalAbsences}일 (ថ្ងៃ)
- 유급휴가 / ឈប់មានច្បាប់: ${calc.totalLeaves}일 (ថ្ងៃ)
- 지각시간 / មកយឺតសរុប: ${calc.totalLateMinutes}분 (នាទី)
----------------------------------------
💵 지급내역 / ប្រាក់ចំណូល:
+ 기본급 / ប្រាក់ខែគោល: ${calc.formattedBaseWon}
+ 연장근로수당(OT) / ប្រាក់ OT: ${calc.formattedOtWon}
----------------------------------------
🔻 공제내역 / ប្រាក់កាត់កង:
- 결근/지각 공제 / កាត់អវត្តមាន-យឺត: -${calc.formattedDeductionsWon}
========================================
💰 실수령액 / ប្រាក់ខែជាក់ស្តែង (NET PAY):
🇰🇷 원화 (KRW): ${calc.formattedNetWon}
🇰🇭 캄보디아 리엘 (KHR): ${calc.formattedNetKhr} (환율 1₩ = ${config.krwToKhrRate}៛)
🇺🇸 미국 달러 (USD): ${calc.formattedNetUsd}
========================================
발행: Khmer Salary (한국-캄보دي아 근로자 급여관리)
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ បានចម្លងវិក្កយបត្រប្រាក់ខែ (한국어/ខ្មែរ) ទៅ Clipboard រួចរាល់!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = language;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: Color(0xFF4F46E5), size: 24),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '급여명세서 / វិក្កយបត្រប្រាក់ខែ',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${month.year}년 ${month.month}월 • ខែ ${month.month} ឆ្នាំ ${month.year}',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Employee Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF4F46E5),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : 'U',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('성명 / ឈ្មោះ: ${user.name}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(user.email,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Attendance & Hours Summary
              const Text('근무내역 / សេចក្តីសង្ខេបម៉ោងការងារ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildRow('총 근무일수 / ចំនួនថ្ងៃធ្វើការ', '${calc.totalWorkingDays} ថ្ងៃ (일)'),
              _buildRow('기본근무 / ម៉ោងធម្មតា',
                  '${calc.regularHoursPart}h ${calc.regularMinutesPart}m (${calc.regularHoursPart}ម៉ ${calc.regularMinutesPart}ន)'),
              _buildRow('연장근로(OT) / ថែមម៉ោង',
                  '${calc.otHoursPart}h ${calc.otMinutesPart}m (${calc.otHoursPart}ម៉ ${calc.otMinutesPart}ន)',
                  isHighlight: true),
              _buildRow('무단결근 / អវត្តមានឥតច្បាប់', '${calc.totalAbsences} ថ្ងៃ (일)',
                  isWarning: calc.totalAbsences > 0),
              _buildRow('유급휴가 / ឈប់មានច្បាប់', '${calc.totalLeaves} ថ្ងៃ (일)'),
              if (calc.totalLateMinutes > 0)
                _buildRow('지각 / មកយឺត', '${calc.totalLateMinutes} នាទី (분)',
                    isWarning: true),
              const Divider(height: 20),

              // Salary Breakdown
              const Text('급여내역 / គណនាប្រាក់ខែ (KRW ₩)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildRow(
                '기본급 / ប្រាក់ខែគោល',
                calc.formatAmount(calc.baseSalaryKrw, CurrencyType.krw),
              ),
              _buildRow(
                '연장수당(OT) / ប្រាក់ថែមម៉ោង',
                '+ ${calc.formatAmount(calc.otPayKrw, CurrencyType.krw)}',
                isHighlight: true,
              ),
              _buildRow(
                '공제액 / ប្រាក់កាត់កង',
                '- ${calc.formatAmount(calc.deductionsKrw, CurrencyType.krw)}',
                isWarning: calc.deductionsKrw > 0,
              ),
              const Divider(height: 20),

              // Korean Won Net Pay Total Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '실수령액 / ប្រាក់ខែជាក់ស្តែង:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'NET PAY (KRW ₩)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      calc.formattedNetWon,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Color(0xFF1D4ED8),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Remittance estimate in KHR & USD
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🇰🇭 ប៉ាន់ស្មានផ្ញើទៅផ្ទះ (Remittance):',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                        Text(
                          '1 ₩ = ${config.krwToKhrRate} ៛ (1\$ = ${(1.0 / config.krwToUsdRate).round()} ₩)',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          calc.formattedNetKhr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF047857),
                          ),
                        ),
                        Text(
                          '≈ ${calc.formattedNetUsd}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Share & Copy Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyPayslipText(context),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(
                        LocalizationService.tr('btn_copy', lang),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _copyPayslipText(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '📲 បានចម្លង និងត្រៀមរួចរាល់សម្រាប់ផ្ញើទៅ Telegram / KakaoTalk!'),
                            backgroundColor: Color(0xFF2563EB),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        LocalizationService.tr('btn_telegram', lang),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isHighlight = false, bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isWarning
                  ? Colors.red
                  : (isHighlight ? const Color(0xFFD97706) : null),
            ),
          ),
        ],
      ),
    );
  }
}
