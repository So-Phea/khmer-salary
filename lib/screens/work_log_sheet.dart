import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../services/localization_service.dart';

class WorkLogSheet extends StatefulWidget {
  final DateTime selectedDate;
  final WorkLog? existingLog;
  final AppLanguage language;
  final SalaryConfig? config;
  final Function(WorkLog) onSave;
  final Function(String dateKey)? onDelete;

  const WorkLogSheet({
    super.key,
    required this.selectedDate,
    this.existingLog,
    required this.language,
    this.config,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<WorkLogSheet> createState() => _WorkLogSheetState();
}

class _WorkLogSheetState extends State<WorkLogSheet> {
  late AttendanceStatus _status;
  late String _checkIn;
  late String _checkOut;
  late int _regHours;
  late int _regMinutes;
  late int _otHours;
  late int _otMinutes;
  late int _lateMinutes;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final log = widget.existingLog;
    _status = log?.status ?? AttendanceStatus.present;
    _checkIn = log?.checkIn ?? '08:00';
    _checkOut = log?.checkOut ?? '17:00';

    if (log != null) {
      _regHours = log.regularHours;
      _regMinutes = log.regularMinutes;
      _otHours = log.otHours;
      _otMinutes = log.otMinutes;
    } else {
      _regHours = 8;
      _regMinutes = 0;
      _otHours = 0;
      _otMinutes = 0;
    }

    _lateMinutes = log?.lateMinutes ?? 0;
    _noteController = TextEditingController(text: log?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _applyQuickPreset(AttendanceStatus status, int regH, int regM, int otH, int otM) {
    setState(() {
      _status = status;
      _regHours = regH;
      _regMinutes = regM;
      _otHours = otH;
      _otMinutes = otM;
      if (status == AttendanceStatus.dayOff) {
        _noteController.text = 'ថ្ងៃសម្រាក (휴무)';
      } else if (otH > 0 || otM > 0) {
        _checkOut = '19:30';
      }
    });
  }

  Future<void> _pickTime(bool isCheckIn) async {
    final currentStr = isCheckIn ? _checkIn : _checkOut;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isCheckIn) {
          _checkIn = formatted;
        } else {
          _checkOut = formatted;
        }
      });
      _autoCalculateFromTimes();
    }
  }

  void _autoCalculateFromTimes() {
    try {
      final inParts = _checkIn.split(':');
      final outParts = _checkOut.split(':');
      final inMins = int.parse(inParts[0]) * 60 + int.parse(inParts[1]);
      var outMins = int.parse(outParts[0]) * 60 + int.parse(outParts[1]);

      if (outMins < inMins) {
        outMins += 24 * 60; // Overnight shift
      }

      int totalWorkMins = outMins - inMins;
      // Deduct 1 hour lunch break if worked 5+ hours
      if (totalWorkMins >= 300) {
        totalWorkMins -= 60;
      }

      if (totalWorkMins <= 0) totalWorkMins = 0;

      setState(() {
        if (totalWorkMins <= 480) {
          _regHours = totalWorkMins ~/ 60;
          _regMinutes = totalWorkMins % 60;
          _otHours = 0;
          _otMinutes = 0;
          _status = AttendanceStatus.present;
        } else {
          _regHours = 8;
          _regMinutes = 0;
          final otMins = totalWorkMins - 480;
          _otHours = otMins ~/ 60;
          _otMinutes = otMins % 60;
          _status = AttendanceStatus.overtime;
        }
      });
    } catch (_) {}
  }

  double _calculateDailyEarned() {
    final baseRate = widget.config?.baseRate ?? 9860.0;
    final otRate = widget.config?.otHourlyRate ?? 14790.0;

    if (_status == AttendanceStatus.absentUnpaid || _status == AttendanceStatus.dayOff) {
      return 0.0;
    }

    final regDec = _regHours + (_regMinutes / 60.0);
    final otDec = _otHours + (_otMinutes / 60.0);

    return (regDec * baseRate) + (otDec * otRate);
  }

  void _confirmDelete() {
    final lang = widget.language;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 26),
            SizedBox(width: 8),
            Text('លុបទិន្នន័យ (Delete)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          LocalizationService.tr('confirm_delete_day', lang),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('btn_cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final dateKey = _formatDateKey(widget.selectedDate);
              widget.onDelete?.call(dateKey);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(LocalizationService.tr('btn_delete', lang)),
          ),
        ],
      ),
    );
  }

  void _save() {
    final isNoWork = _status == AttendanceStatus.absentUnpaid ||
        _status == AttendanceStatus.dayOff;

    final regTotal = isNoWork ? 0 : (_regHours * 60 + _regMinutes);
    final otTotal = isNoWork ? 0 : (_otHours * 60 + _otMinutes);

    final log = WorkLog(
      dateKey: _formatDateKey(widget.selectedDate),
      status: _status,
      checkIn: _checkIn,
      checkOut: _checkOut,
      regularMinutesTotal: regTotal,
      otMinutesTotal: otTotal,
      lateMinutes: _lateMinutes,
      note: _noteController.text.trim(),
    );

    widget.onSave(log);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = widget.language;
    final formattedDate =
        DateFormat('EEEE, d MMMM yyyy').format(widget.selectedDate);

    final dailyEarned = _calculateDailyEarned();
    final hasExistingLog = widget.existingLog != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Date, Status Badge & Delete Icon
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.tr('quick_log_title', lang),
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _status.localizedTitle(lang),
                    style: TextStyle(
                      color: _status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                if (hasExistingLog && widget.onDelete != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 22),
                    tooltip: LocalizationService.tr('btn_delete', lang),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Daily Estimated Earnings Preview Banner (Clean KRW only)
            if (_status != AttendanceStatus.absentUnpaid &&
                _status != AttendanceStatus.dayOff)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ប្រាក់ឈ្នួលប៉ាន់ស្មានថ្ងៃនេះ (Today\'s Earning):',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                '₩${_formatNumber(dailyEarned.round())}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '≈ ${_formatNumber((dailyEarned * (widget.config?.krwToKhrRate ?? 3.05)).round())} ៛',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
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

            const SizedBox(height: 12),

            // Quick Action Presets
            Text(
              LocalizationService.tr('quick_presets', lang),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip(
                    title: '8h 00m',
                    subtitle: 'ពេញម៉ោង',
                    color: const Color(0xFF2563EB),
                    isSelected: _status == AttendanceStatus.present &&
                        _regHours == 8 &&
                        _regMinutes == 0 &&
                        _otHours == 0 &&
                        _otMinutes == 0,
                    onTap: () => _applyQuickPreset(
                        AttendanceStatus.present, 8, 0, 0, 0),
                  ),
                  const SizedBox(width: 6),
                  _buildPresetChip(
                    title: '8h 30m',
                    subtitle: '+30ន',
                    color: const Color(0xFF3B82F6),
                    isSelected: _status == AttendanceStatus.present &&
                        _regHours == 8 &&
                        _regMinutes == 30,
                    onTap: () => _applyQuickPreset(
                        AttendanceStatus.present, 8, 30, 0, 0),
                  ),
                  const SizedBox(width: 6),
                  _buildPresetChip(
                    title: '8h 45m',
                    subtitle: '+45ន',
                    color: const Color(0xFF0284C7),
                    isSelected: _status == AttendanceStatus.present &&
                        _regHours == 8 &&
                        _regMinutes == 45,
                    onTap: () => _applyQuickPreset(
                        AttendanceStatus.present, 8, 45, 0, 0),
                  ),
                  const SizedBox(width: 6),
                  _buildPresetChip(
                    title: '10h 15m',
                    subtitle: '+2h15 OT',
                    color: const Color(0xFFF59E0B),
                    isSelected: _status == AttendanceStatus.overtime &&
                        _otHours == 2 &&
                        _otMinutes == 15,
                    onTap: () => _applyQuickPreset(
                        AttendanceStatus.overtime, 8, 0, 2, 15),
                  ),
                  const SizedBox(width: 6),
                  _buildPresetChip(
                    title: 'ថ្ងៃសម្រាក',
                    subtitle: '휴무일',
                    color: Colors.grey,
                    isSelected: _status == AttendanceStatus.dayOff,
                    onTap: () => _applyQuickPreset(
                        AttendanceStatus.dayOff, 0, 0, 0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AttendanceStatus.values.map((s) {
                  final isSelected = _status == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      selectedColor: s.color,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon,
                              size: 13,
                              color: isSelected ? Colors.white : s.color),
                          const SizedBox(width: 4),
                          Text(s.localizedTitle(lang)),
                        ],
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _status = s;
                            if (s == AttendanceStatus.overtime &&
                                _otHours == 0 &&
                                _otMinutes == 0) {
                              _otHours = 2;
                              _otMinutes = 0;
                            }
                            if (s == AttendanceStatus.absentUnpaid ||
                                s == AttendanceStatus.dayOff) {
                              _regHours = 0;
                              _regMinutes = 0;
                              _otHours = 0;
                              _otMinutes = 0;
                            } else if (_regHours == 0 && _regMinutes == 0) {
                              _regHours = 8;
                              _regMinutes = 0;
                            }
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Check In / Check Out with Auto-Calculate
            if (_status != AttendanceStatus.absentUnpaid &&
                _status != AttendanceStatus.dayOff) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerTile(
                      label: LocalizationService.tr('check_in', lang),
                      time: _checkIn,
                      onTap: () => _pickTime(true),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTimePickerTile(
                      label: LocalizationService.tr('check_out', lang),
                      time: _checkOut,
                      onTap: () => _pickTime(false),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Auto Calculate Button
              InkWell(
                onTap: _autoCalculateFromTimes,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_fix_high_rounded,
                          color: Color(0xFF2563EB), size: 15),
                      const SizedBox(width: 6),
                      Text(
                        LocalizationService.tr('auto_calc_btn', lang),
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Regular Work Duration Input (Hours & Minutes)
              _buildDurationPicker(
                title: LocalizationService.tr('regular_work_time', lang),
                hours: _regHours,
                minutes: _regMinutes,
                color: const Color(0xFF2563EB),
                onHoursChanged: (h) => setState(() => _regHours = h.clamp(0, 24)),
                onMinutesChanged: (m) => setState(() => _regMinutes = m.clamp(0, 59)),
                isDark: isDark,
              ),

              const SizedBox(height: 10),

              // OT Work Duration Input (Hours & Minutes)
              _buildDurationPicker(
                title: LocalizationService.tr('ot_work_time', lang),
                hours: _otHours,
                minutes: _otMinutes,
                color: const Color(0xFFF59E0B),
                onHoursChanged: (h) {
                  setState(() {
                    _otHours = h.clamp(0, 24);
                    if (_otHours > 0 || _otMinutes > 0) {
                      _status = AttendanceStatus.overtime;
                    }
                  });
                },
                onMinutesChanged: (m) {
                  setState(() {
                    _otMinutes = m.clamp(0, 59);
                    if (_otHours > 0 || _otMinutes > 0) {
                      _status = AttendanceStatus.overtime;
                    }
                  });
                },
                isDark: isDark,
              ),

              const SizedBox(height: 10),

              // Late Minutes Stepper
              Row(
                children: [
                  Text(LocalizationService.tr('late_mins', lang),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12.5)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    onPressed: _lateMinutes > 0
                        ? () => setState(() => _lateMinutes -= 5)
                        : null,
                  ),
                  Text(
                    '$_lateMinutes នាទី',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: _lateMinutes > 0 ? Colors.redAccent : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    onPressed: () => setState(() => _lateMinutes += 5),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),

            // Note Field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: LocalizationService.tr('note', lang),
                hintText: 'ឧ. ថែមម៉ោងបន្ទាន់, កម្ម៉ង់លើស...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons: Save & Red Delete Button
            Row(
              children: [
                if (hasExistingLog && widget.onDelete != null) ...[
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete_forever_rounded,
                            color: Colors.redAccent, size: 18),
                        label: Text(
                          LocalizationService.tr('btn_delete', lang),
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        LocalizationService.tr('btn_save', lang),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: isSelected ? Colors.white : color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required String time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10.5,
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 15, color: Color(0xFF2563EB)),
                const SizedBox(width: 5),
                Text(time,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationPicker({
    required String title,
    required int hours,
    required int minutes,
    required Color color,
    required Function(int) onHoursChanged,
    required Function(int) onMinutesChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${hours}h ${minutes}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              // Hours input
              Expanded(
                child: Row(
                  children: [
                    const Text('ម៉ោង: ',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 17),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: hours > 0 ? () => onHoursChanged(hours - 1) : null,
                    ),
                    const SizedBox(width: 5),
                    Text('$hours h',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 17),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onHoursChanged(hours + 1),
                    ),
                  ],
                ),
              ),

              // Minutes input
              Expanded(
                child: Row(
                  children: [
                    const Text('នាទី: ',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 17),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: minutes >= 5 ? () => onMinutesChanged(minutes - 5) : null,
                    ),
                    const SizedBox(width: 5),
                    Text('$minutes m',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 17),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: minutes <= 54 ? () => onMinutesChanged(minutes + 5) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Quick Minute Chips
          Row(
            children: [0, 15, 30, 45].map((m) {
              final isCur = minutes == m;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => onMinutesChanged(m),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCur
                          ? color
                          : (isDark ? Colors.grey.shade800 : Colors.white),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCur ? color : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '$m នាទី',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                        color: isCur ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(num n) {
    final str = n.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }
}
