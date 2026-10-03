import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../models/user_model.dart';
import '../services/localization_service.dart';
import '../services/storage_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/korea_minimum_wage_service.dart';
import 'work_log_sheet.dart';
import '../widgets/payslip_modal.dart';

enum WorkViewMode { calendar, list }

class PayrollScreen extends StatefulWidget {
  final AppUser user;
  final AppLanguage language;
  final SalaryConfig salaryConfig;
  final Function(SalaryConfig) onUpdateSalaryConfig;

  const PayrollScreen({
    super.key,
    required this.user,
    required this.language,
    required this.salaryConfig,
    required this.onUpdateSalaryConfig,
  });

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  DateTime _currentMonth = DateTime.now();
  Map<String, WorkLog> _workLogs = {};
  WorkViewMode _viewMode = WorkViewMode.calendar;
  CurrencyType _activeCurrency = CurrencyType.krw;
  WeekStartDay _weekStartDay = WeekStartDay.sunday; // Default Sunday (អាទិត្យ ដល់ សៅរ៍)
  List<Employee> _employees = [];
  Employee? _activeEmployee;
  bool _isLoading = true;
  bool _isFetchingRates = false;
  bool _isRatesLive = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchLiveRates(showFeedback: false);
  }

  Future<void> _fetchLiveRates({bool showFeedback = false}) async {
    if (_isFetchingRates) return;
    setState(() => _isFetchingRates = true);

    try {
      final res = await ExchangeRateService.fetchLiveRates();
      final currentConfig = _activeEmployee?.config ?? widget.salaryConfig;
      final updated = SalaryConfig(
        salaryType: currentConfig.salaryType,
        baseRate: currentConfig.baseRate,
        otHourlyRate: currentConfig.otHourlyRate,
        lateDeductionPerHour: currentConfig.lateDeductionPerHour,
        krwToKhrRate: res.krwToKhr,
        krwToUsdRate: res.krwToUsd,
      );

      widget.onUpdateSalaryConfig(updated);
      if (_activeEmployee != null) {
        final updatedEmp = _activeEmployee!.copyWith(config: updated);
        final idx = _employees.indexWhere((e) => e.id == updatedEmp.id);
        if (idx != -1) {
          _employees[idx] = updatedEmp;
          await StorageService.saveEmployees(_employees);
        }
      }

      if (mounted) {
        setState(() {
          _isRatesLive = res.isLive;
          _isFetchingRates = false;
        });

        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res.isLive
                    ? '✅ បានទាញយកហាងឆេងថ្ងៃនេះផ្ទាល់ (1 ₩ = ${res.formattedKhrRate} ៛)'
                    : 'ℹ️ ${res.errorMessage ?? 'ប្រើប្រាស់ហាងឆេងចុងក្រោយ'}',
              ),
              backgroundColor: res.isLive ? const Color(0xFF10B981) : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFetchingRates = false);
      }
    }
  }

  Future<void> _loadData() async {
    final emps = await StorageService.loadEmployees();
    final activeId = await StorageService.loadActiveEmployeeId();
    final weekStart = await StorageService.loadWeekStartDay();

    final currentEmp = emps.firstWhere(
      (e) => e.id == activeId,
      orElse: () => emps.isNotEmpty
          ? emps.first
          : Employee(
              id: 'emp_me',
              name: 'ខ្ញុំ (Me)',
              role: 'ពលករ/បុគ្គលិក',
              config: widget.salaryConfig,
            ),
    );

    final logs = await StorageService.loadEmployeeWorkLogs(currentEmp.id);

    setState(() {
      _employees = emps;
      _activeEmployee = currentEmp;
      _weekStartDay = weekStart;
      _workLogs = logs;
      _isLoading = false;
    });
  }

  void _switchEmployee(Employee emp) async {
    if (_activeEmployee?.id == emp.id) return;
    setState(() => _isLoading = true);

    await StorageService.saveActiveEmployeeId(emp.id);
    final logs = await StorageService.loadEmployeeWorkLogs(emp.id);

    setState(() {
      _activeEmployee = emp;
      _workLogs = logs;
      _isLoading = false;
    });
  }

  String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _onSaveWorkLog(WorkLog log) async {
    setState(() {
      _workLogs[log.dateKey] = log;
    });
    if (_activeEmployee != null) {
      await StorageService.saveEmployeeWorkLogs(_activeEmployee!.id, _workLogs);
    } else {
      await StorageService.saveWorkLogs(_workLogs);
    }
  }

  void _onDeleteWorkLog(String dateKey) async {
    setState(() {
      _workLogs.remove(dateKey);
    });
    if (_activeEmployee != null) {
      await StorageService.saveEmployeeWorkLogs(_activeEmployee!.id, _workLogs);
    } else {
      await StorageService.saveWorkLogs(_workLogs);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.tr('deleted_success', widget.language),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearMonthRecords() async {
    final monthPrefix =
        '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';

    setState(() {
      _workLogs.removeWhere((key, _) => key.startsWith(monthPrefix));
    });
    if (_activeEmployee != null) {
      await StorageService.saveEmployeeWorkLogs(_activeEmployee!.id, _workLogs);
    } else {
      await StorageService.saveWorkLogs(_workLogs);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.tr('month_cleared_success', widget.language),
          ),
          backgroundColor: const Color(0xFF2563EB),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmClearMonth() {
    final lang = widget.language;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
            SizedBox(width: 8),
            Text('សម្អាតទិន្នន័យខែនេះ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          LocalizationService.tr('confirm_clear_month', lang),
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
              _clearMonthRecords();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(LocalizationService.tr('btn_clear_month', lang)),
          ),
        ],
      ),
    );
  }

  void _openWorkLogSheet(DateTime date) {
    final key = _formatDateKey(date);
    final existing = _workLogs[key];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => WorkLogSheet(
        selectedDate: date,
        existingLog: existing,
        language: widget.language,
        config: _activeEmployee?.config ?? widget.salaryConfig,
        onSave: _onSaveWorkLog,
        onDelete: _onDeleteWorkLog,
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  PayrollCalculation _calculatePayroll() {
    int totalWorkingDays = 0;
    int totalRegularMinutes = 0;
    int totalOtMinutes = 0;
    int totalAbsences = 0;
    int totalLeaves = 0;
    int totalLateMinutes = 0;

    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final key = _formatDateKey(date);
      final log = _workLogs[key];

      if (log != null) {
        if (log.status == AttendanceStatus.present ||
            log.status == AttendanceStatus.overtime) {
          totalWorkingDays++;
          totalRegularMinutes += log.regularMinutesTotal;
          totalOtMinutes += log.otMinutesTotal;
          totalLateMinutes += log.lateMinutes;
        } else if (log.status == AttendanceStatus.absentUnpaid) {
          totalAbsences++;
        } else if (log.status == AttendanceStatus.leavePaid) {
          totalLeaves++;
        }
      }
    }

    final cfg = _activeEmployee?.config ?? widget.salaryConfig;
    final year = _currentMonth.year;
    final effectiveBaseRate = cfg.getEffectiveBaseRate(year);
    final effectiveOtRate = cfg.getEffectiveOtRate(year);

    double baseSalaryKrw = 0.0;
    switch (cfg.salaryType) {
      case SalaryType.monthly:
        baseSalaryKrw = cfg.autoMinistryWage
            ? KoreaMinimumWageService.getMonthlyStandard(year)
            : cfg.baseRate;
        break;
      case SalaryType.daily:
        baseSalaryKrw = totalWorkingDays * effectiveBaseRate;
        break;
      case SalaryType.hourly:
        baseSalaryKrw = (totalRegularMinutes / 60.0) * effectiveBaseRate;
        break;
    }

    // Minute-precision OT Pay in Korean Won (1.5x)
    final otPayKrw = (totalOtMinutes / 60.0) * effectiveOtRate;

    // Deductions in Korean Won
    double deductionsKrw = 0.0;
    if (cfg.salaryType == SalaryType.monthly && totalAbsences > 0) {
      final dailyRate = baseSalaryKrw / 26.0;
      deductionsKrw += totalAbsences * dailyRate;
    }
    if (totalLateMinutes > 0) {
      deductionsKrw += (totalLateMinutes / 60.0) * cfg.lateDeductionPerHour;
    }

    final netSalaryKrw =
        (baseSalaryKrw + otPayKrw - deductionsKrw).clamp(0.0, 999999999.0);

    final effectiveConfig = cfg.copyWith(
      baseRate: effectiveBaseRate,
      otHourlyRate: effectiveOtRate,
    );

    return PayrollCalculation(
      totalWorkingDays: totalWorkingDays,
      totalRegularMinutes: totalRegularMinutes,
      totalOtMinutes: totalOtMinutes,
      totalAbsences: totalAbsences,
      totalLeaves: totalLeaves,
      totalLateMinutes: totalLateMinutes,
      baseSalaryKrw: baseSalaryKrw,
      otPayKrw: otPayKrw,
      deductionsKrw: deductionsKrw,
      netSalaryKrw: netSalaryKrw,
      config: effectiveConfig,
    );
  }

  void _openSalaryConfigDialog() {
    final cfg = _activeEmployee?.config ?? widget.salaryConfig;
    bool tempAutoMinistry = cfg.autoMinistryWage;
    int tempYear = cfg.statutoryYear ?? _currentMonth.year;

    final initialBase = tempAutoMinistry
        ? KoreaMinimumWageService.getHourlyRate(tempYear)
        : cfg.baseRate;
    final initialOt = tempAutoMinistry
        ? KoreaMinimumWageService.getOtHourlyRate(tempYear)
        : cfg.otHourlyRate;

    final rateController =
        TextEditingController(text: initialBase.round().toString());
    final otRateController =
        TextEditingController(text: initialOt.round().toString());
    final lateController =
        TextEditingController(text: cfg.lateDeductionPerHour.round().toString());
    SalaryType tempType = cfg.salaryType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final ministryInfo = KoreaMinimumWageService.getInfoForYear(tempYear);

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'អត្រាប្រាក់ខែ ${_activeEmployee?.name ?? ""}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ministry Statutory Minimum Wage Auto-Sync Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tempAutoMinistry
                          ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tempAutoMinistry
                            ? const Color(0xFF2563EB).withValues(alpha: 0.4)
                            : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_rounded,
                                color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'ប្រាក់ម៉ោងស្វ័យប្រវត្តិតាមក្រសួង (MOEL)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: tempAutoMinistry,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (val) {
                                setModalState(() {
                                  tempAutoMinistry = val;
                                  if (val) {
                                    rateController.text =
                                        KoreaMinimumWageService.getHourlyRate(tempYear)
                                            .round()
                                            .toString();
                                    otRateController.text =
                                        KoreaMinimumWageService.getOtHourlyRate(tempYear)
                                            .round()
                                            .toString();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        Text(
                          'កំណត់ និងកែសម្រួលប្រាក់ម៉ោងដោយស្វ័យប្រវត្តិ ទៅតាមការប្រកាសផ្លូវការរបស់ក្រសួងការងារកូរ៉េ (고용노동부)',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (tempAutoMinistry) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ឆ្នាំកំណត់ដោយក្រសួង:',
                                style: TextStyle(
                                    fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                              DropdownButton<int>(
                                value: tempYear,
                                isDense: true,
                                underline: const SizedBox(),
                                items: KoreaMinimumWageService.supportedYears
                                    .map((y) => DropdownMenuItem(
                                          value: y,
                                          child: Text(
                                            'ឆ្នាំ $y ${y == 2026 ? '(បច្ចុប្បន្ន)' : ''}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      tempYear = val;
                                      rateController.text =
                                          KoreaMinimumWageService.getHourlyRate(val)
                                              .round()
                                              .toString();
                                      otRateController.text =
                                          KoreaMinimumWageService.getOtHourlyRate(val)
                                              .round()
                                              .toString();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                  alpha: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.05
                                      : 0.8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('• ប្រាក់ម៉ោងគោល (Base):',
                                        style: TextStyle(fontSize: 11)),
                                    Text(
                                      ministryInfo.formattedHourly,
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('• ថែមម៉ោង OT (1.5x):',
                                        style: TextStyle(fontSize: 11)),
                                    Text(
                                      ministryInfo.formattedOt,
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF59E0B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('• ប្រាក់ខែស្តង់ដារ (២០៩h):',
                                        style: TextStyle(fontSize: 11)),
                                    Text(
                                      ministryInfo.formattedMonthly,
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('ប្រភេទប្រាក់ខែ (Salary Type):',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<SalaryType>(
                    value: tempType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: SalaryType.hourly,
                          child: Text('គិតជាម៉ោង (Hourly - Korea Standard)')),
                      DropdownMenuItem(
                          value: SalaryType.monthly,
                          child: Text('ប្រចាំខែ (Monthly)')),
                      DropdownMenuItem(
                          value: SalaryType.daily,
                          child: Text('គិតជាថ្ងៃ (Daily)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => tempType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: rateController,
                    enabled: !tempAutoMinistry,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ប្រាក់ឈ្នួលគោល KRW (₩/hr)',
                      helperText: tempAutoMinistry
                          ? '✅ កំណត់ស្វ័យប្រវត្តិតាមក្រសួង: ${ministryInfo.formattedHourly}'
                          : 'បញ្ចូលអត្រាជាក់ស្តែង',
                      prefixText: '₩ ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: otRateController,
                    enabled: !tempAutoMinistry,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'អត្រា OT ក្នុង ១ ម៉ោង KRW (₩/hr)',
                      helperText: tempAutoMinistry
                          ? '✅ ស្តង់ដារច្បាប់ 1.5x: ${ministryInfo.formattedOt}'
                          : '1.5x នៃប្រាក់គោល',
                      prefixText: '₩ ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: lateController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'កាត់យឺត ១ ម៉ោង KRW (₩/hr)',
                      prefixText: '₩ ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                  final double baseVal = tempAutoMinistry
                      ? KoreaMinimumWageService.getHourlyRate(tempYear)
                      : (double.tryParse(rateController.text) ?? cfg.baseRate);
                  final double otVal = tempAutoMinistry
                      ? KoreaMinimumWageService.getOtHourlyRate(tempYear)
                      : (double.tryParse(otRateController.text) ?? cfg.otHourlyRate);

                  final newConfig = SalaryConfig(
                    salaryType: tempType,
                    baseRate: baseVal,
                    otHourlyRate: otVal,
                    lateDeductionPerHour:
                        double.tryParse(lateController.text) ?? cfg.lateDeductionPerHour,
                    krwToKhrRate: cfg.krwToKhrRate,
                    krwToUsdRate: cfg.krwToUsdRate,
                    autoMinistryWage: tempAutoMinistry,
                    statutoryYear: tempAutoMinistry ? tempYear : null,
                  );

                  if (_activeEmployee != null) {
                    final updatedEmp = _activeEmployee!.copyWith(config: newConfig);
                    final idx = _employees.indexWhere((e) => e.id == updatedEmp.id);
                    if (idx != -1) {
                      _employees[idx] = updatedEmp;
                      await StorageService.saveEmployees(_employees);
                    }
                    setState(() => _activeEmployee = updatedEmp);
                  }

                  widget.onUpdateSalaryConfig(newConfig);
                  await StorageService.saveSalaryConfig(newConfig);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('រក្សាទុក'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openExchangeRateDialog() {
    final cfg = widget.salaryConfig;
    final khrController =
        TextEditingController(text: cfg.krwToKhrRate.toString());
    final usdController =
        TextEditingController(text: cfg.krwToUsdRate.toString());
    bool isDialogFetching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.currency_exchange_rounded,
                  color: Color(0xFF10B981), size: 24),
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
                  onPressed: isDialogFetching
                      ? null
                      : () async {
                          setDialogState(() => isDialogFetching = true);
                          final result =
                              await ExchangeRateService.fetchLiveRates();
                          setDialogState(() {
                            isDialogFetching = false;
                            khrController.text =
                                result.krwToKhr.toStringAsFixed(2);
                            usdController.text =
                                result.krwToUsd.toStringAsFixed(6);
                          });
                        },
                  icon: isDialogFetching
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 16),
                  label: Text(
                    isDialogFetching
                        ? 'កំពុងទាញយក...'
                        : '🔄 ទាញយកហាងឆេងថ្ងៃនេះ (Live Rate)',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: khrController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '1 KRW (₩) = ? KHR (៛)',
                    helperText: 'ហាងឆេងរៀល: ~3.00 ៛',
                    prefixIcon: const Icon(Icons.currency_exchange),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: usdController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '1 KRW (₩) = ? USD (\$)',
                    helperText: 'ហាងឆេងដុល្លារ: ~0.00074 \$',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                    double.tryParse(khrController.text) ?? cfg.krwToKhrRate;
                final newUsd =
                    double.tryParse(usdController.text) ?? cfg.krwToUsdRate;

                final updated = SalaryConfig(
                  salaryType: cfg.salaryType,
                  baseRate: cfg.baseRate,
                  otHourlyRate: cfg.otHourlyRate,
                  lateDeductionPerHour: cfg.lateDeductionPerHour,
                  krwToKhrRate: newKhr,
                  krwToUsdRate: newUsd,
                );

                await ExchangeRateService.saveManualRates(newKhr, newUsd);
                widget.onUpdateSalaryConfig(updated);
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
                backgroundColor: const Color(0xFF2563EB),
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

  void _showPayslipModal(PayrollCalculation calc) {
    showDialog(
      context: context,
      builder: (ctx) => PayslipModal(
        user: widget.user,
        month: _currentMonth,
        config: widget.salaryConfig,
        calc: calc,
        language: widget.language,
        activeCurrency: _activeCurrency,
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final lang = widget.language;
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'ពលករ/បុគ្គលិក');
    final moelRate = KoreaMinimumWageService.getHourlyRate(_currentMonth.year).round();
    final baseRateCtrl = TextEditingController(
      text: (_activeEmployee?.config.autoMinistryWage ?? true)
          ? moelRate.toString()
          : (_activeEmployee?.config.baseRate ?? widget.salaryConfig.baseRate)
              .round()
              .toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.person_add_rounded,
                color: Color(0xFF2563EB), size: 24),
            const SizedBox(width: 8),
            Text(
              LocalizationService.tr('add_employee', lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: LocalizationService.tr('emp_name_label', lang),
                  hintText: 'ឧ. សុខា, បូណា, ធីតា...',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: roleCtrl,
                decoration: InputDecoration(
                  labelText: LocalizationService.tr('emp_role_label', lang),
                  hintText: 'ឧ. រោងចក្រ, កសិកម្ម, សំណង់...',
                  prefixIcon: const Icon(Icons.work_outline_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: baseRateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ប្រាក់ឈ្នួលគោល (₩ វ៉ុន/ម៉ោង)',
                  prefixText: '₩ ',
                  helperText: 'ស្តង់ដារក្រសួងការងារ ${_currentMonth.year}: $moelRate ₩/ម៉ោង',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  baseRateCtrl.text = moelRate.toString();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 13, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        'ប្រើអត្រាក្រសួង ${_currentMonth.year}: $moelRate ₩',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('btn_cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final role = roleCtrl.text.trim().isEmpty
                  ? 'បុគ្គលិក'
                  : roleCtrl.text.trim();
              final rate = double.tryParse(baseRateCtrl.text) ?? 9860.0;
              final otRate = (rate * 1.5).roundToDouble();

              final newConfig =
                  (_activeEmployee?.config ?? widget.salaryConfig).copyWith(
                baseRate: rate,
                otHourlyRate: otRate,
                lateDeductionPerHour: rate,
              );

              final newEmp = Employee(
                id: 'emp_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                role: role,
                config: newConfig,
              );

              final updatedList = [..._employees, newEmp];
              await StorageService.saveEmployees(updatedList);
              await StorageService.saveActiveEmployeeId(newEmp.id);

              setState(() {
                _employees = updatedList;
                _activeEmployee = newEmp;
                _workLogs = {};
              });

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(LocalizationService.tr('btn_save', lang)),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(Employee emp) {
    final lang = widget.language;
    final nameCtrl = TextEditingController(text: emp.name);
    final roleCtrl = TextEditingController(text: emp.role);
    final baseRateCtrl =
        TextEditingController(text: emp.config.baseRate.round().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded,
                color: Color(0xFF2563EB), size: 24),
            const SizedBox(width: 8),
            Text(
              LocalizationService.tr('edit_employee', lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: LocalizationService.tr('emp_name_label', lang),
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: roleCtrl,
                decoration: InputDecoration(
                  labelText: LocalizationService.tr('emp_role_label', lang),
                  prefixIcon: const Icon(Icons.work_outline_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: baseRateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ប្រាក់ឈ្នួលគោល (₩ វ៉ុន/ម៉ោង)',
                  prefixText: '₩ ',
                  helperText: 'ស្តង់ដារក្រសួងការងារ ${_currentMonth.year}: ${KoreaMinimumWageService.getHourlyRate(_currentMonth.year).round()} ₩/ម៉ោង',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  baseRateCtrl.text = KoreaMinimumWageService.getHourlyRate(_currentMonth.year).round().toString();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 13, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        'កំណត់តាមក្រសួង ${_currentMonth.year}: ${KoreaMinimumWageService.getHourlyRate(_currentMonth.year).round()} ₩',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_employees.length > 1) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmDeleteEmployee(emp);
                  },
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 18),
                  label: Text(
                    LocalizationService.tr('delete_employee', lang),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('btn_cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final role = roleCtrl.text.trim().isEmpty
                  ? 'បុគ្គលិក'
                  : roleCtrl.text.trim();
              final rate =
                  double.tryParse(baseRateCtrl.text) ?? emp.config.baseRate;
              final otRate = (rate * 1.5).roundToDouble();

              final updatedEmp = emp.copyWith(
                name: name,
                role: role,
                config: emp.config.copyWith(
                  baseRate: rate,
                  otHourlyRate: otRate,
                  lateDeductionPerHour: rate,
                ),
              );

              final idx = _employees.indexWhere((e) => e.id == emp.id);
              if (idx != -1) {
                _employees[idx] = updatedEmp;
                await StorageService.saveEmployees(_employees);
                setState(() {
                  if (_activeEmployee?.id == emp.id) {
                    _activeEmployee = updatedEmp;
                  }
                });
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(LocalizationService.tr('btn_save', lang)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEmployee(Employee emp) {
    if (_employees.length <= 1) return;
    final lang = widget.language;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('លុบบុគ្គលិក',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          '${LocalizationService.tr('confirm_delete_emp', lang)}\n("${emp.name}")',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.tr('btn_cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updated =
                  _employees.where((e) => e.id != emp.id).toList();
              await StorageService.saveEmployees(updated);
              final nextEmp = updated.first;
              await StorageService.saveActiveEmployeeId(nextEmp.id);
              final nextLogs =
                  await StorageService.loadEmployeeWorkLogs(nextEmp.id);
              setState(() {
                _employees = updated;
                _activeEmployee = nextEmp;
                _workLogs = nextLogs;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(LocalizationService.tr('btn_delete', lang)),
          ),
        ],
      ),
    );
  }

  void _showWeekStartDialog() {
    final lang = widget.language;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.calendar_view_week_rounded,
                  color: Color(0xFF2563EB), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LocalizationService.tr('week_start_title', lang),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: WeekStartDay.values.map((w) {
              final isSelected = _weekStartDay == w;
              return RadioListTile<WeekStartDay>(
                value: w,
                groupValue: _weekStartDay,
                title: Text(
                  w.localizedTitle(lang),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF2563EB) : null,
                  ),
                ),
                subtitle: Text(
                  w == WeekStartDay.sunday
                      ? 'អាទិត្យ -> ច័ន្ទ -> អង្គារ... -> សៅរ៍'
                      : (w == WeekStartDay.saturday
                          ? 'សៅរ៍ -> អាទិត្យ -> ច័ន្ទ... -> សុក្រ'
                          : 'ច័ន្ទ -> អង្គារ -> ពុធ... -> អាទិត្យ'),
                  style: const TextStyle(fontSize: 11),
                ),
                onChanged: (val) async {
                  if (val != null) {
                    await StorageService.saveWeekStartDay(val);
                    setState(() => _weekStartDay = val);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LocalizationService.tr('btn_cancel', lang)),
            ),
          ],
        ),
      ),
    );
  }

  void _showScreenshotModal(PayrollCalculation calc) {
    final lang = widget.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthTitle = DateFormat('MMMM yyyy').format(_currentMonth);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startingOffset = _weekStartDay.getStartingOffset(firstDayOfMonth);
    final totalCells = startingOffset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();
    final weekdays = _weekStartDay.weekdays(lang);

    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        child: SafeArea(
          child: Column(
            children: [
              // Modal Top Navigation Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.camera_alt_rounded,
                            color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'របាយការណ៍ថតចម្លង (Screenshot Statement)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // The Printable / Screenshot Card Container
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.4 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/logo.jpg',
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 38,
                                      height: 38,
                                      color: const Color(0xFF2563EB),
                                      child: const Icon(Icons.payments_rounded,
                                          color: Colors.white, size: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Khmer Salary',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF2563EB),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      monthTitle,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Employee Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_rounded,
                                          size: 14, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 4),
                                      Text(
                                        _activeEmployee?.name ?? 'ខ្ញុំ (Me)',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _activeEmployee?.role ?? 'បុគ្គលិក',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // Ministry Statutory Minimum Wage Official Badge
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_rounded,
                                  color: Color(0xFF2563EB), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '🏛️ ស្តង់ដារក្រសួងការងារកូរ៉េ ${_currentMonth.year} (MOEL): ${calc.config.baseRate.round()} ₩/h • OT: ${calc.config.otHourlyRate.round()} ₩/h',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Full Calendar Grid - Entire Month Displayed
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Weekday headers
                              Row(
                                children:
                                    weekdays.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  Color headerColor;
                                  if (_weekStartDay ==
                                      WeekStartDay.saturday) {
                                    headerColor = idx == 0
                                        ? const Color(0xFF0284C7)
                                        : (idx == 1
                                            ? Colors.redAccent.shade200
                                            : (isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600));
                                  } else if (_weekStartDay ==
                                      WeekStartDay.sunday) {
                                    headerColor = idx == 0
                                        ? Colors.redAccent.shade200
                                        : (idx == 6
                                            ? const Color(0xFF0284C7)
                                            : (isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600));
                                  } else {
                                    headerColor = idx == 5
                                        ? const Color(0xFF0284C7)
                                        : (idx == 6
                                            ? Colors.redAccent.shade200
                                            : (isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600));
                                  }

                                  return Expanded(
                                    child: Center(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: headerColor,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 6),

                              // Month Days 1-31
                              for (int row = 0; row < totalRows; row++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 1.5),
                                  child: Row(
                                    children: [
                                      for (int col = 0; col < 7; col++) ...[
                                        Expanded(
                                          child: Builder(
                                            builder: (_) {
                                              final index = row * 7 + col;
                                              final dayNum =
                                                  index - startingOffset + 1;
                                              if (dayNum < 1 ||
                                                  dayNum > daysInMonth) {
                                                return const SizedBox(
                                                    height: 42);
                                              }
                                              final date = DateTime(
                                                  _currentMonth.year,
                                                  _currentMonth.month,
                                                  dayNum);
                                              final key =
                                                  _formatDateKey(date);
                                              final log = _workLogs[key];

                                              Color cellBg =
                                                  Colors.transparent;
                                              Color borderC = isDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade200;

                                              if (log != null) {
                                                cellBg = log.status.color
                                                    .withValues(alpha: 0.12);
                                                borderC = log.status.color
                                                    .withValues(alpha: 0.4);
                                              }

                                              return Container(
                                                margin:
                                                    const EdgeInsets.all(1.0),
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: cellBg,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: borderC,
                                                      width: 0.8),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    Text(
                                                      '$dayNum',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    if (log != null)
                                                      _buildCellContent(log)
                                                    else
                                                      Text('-',
                                                          style: TextStyle(
                                                              fontSize: 8,
                                                              color: Colors.grey
                                                                  .shade400)),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Quick Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('សរុបម៉ោងការងារ',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      calc.formatTotalDuration(lang),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('ថែមម៉ោង OT',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      calc.formatOtDuration(lang),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF59E0B)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('ថ្ងៃធ្វើការ',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${calc.totalWorkingDays} ថ្ងៃ',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Net Salary Summary Box (Multi-Currency: KRW ₩, KHR ៛, USD $)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ប្រាក់ខែសុទ្ធសរុប (NET SALARY):',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    calc.formattedNetWon,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '(KRW ₩)',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '🇰🇭 ${calc.formattedNetKhr}',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '🇺🇸 ${calc.formattedNetUsd}',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
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
                ),
              ),

              // Bottom Instruction Tip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '📸 ថត Screenshot អេក្រង់នេះ (Power + Volume Down) ដើម្បីរក្សាទុក ឬផ្ញើឱ្យថៅកែ / គ្រួសារ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeBar(bool isDark, AppLanguage lang) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 2, bottom: 2),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ..._employees.map((emp) {
            final isActive = _activeEmployee?.id == emp.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (!isActive) {
                      _switchEmployee(emp);
                    } else {
                      _showEditEmployeeDialog(emp);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF2563EB)
                          : (isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF2563EB)
                            : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 15,
                          color: isActive
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          emp.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.w500,
                            color: isActive
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _showEditEmployeeDialog(emp),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          // Add Employee Button
          InkWell(
            onTap: _showAddEmployeeDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.person_add_rounded,
                      size: 14, color: Color(0xFF2563EB)),
                  SizedBox(width: 5),
                  Text(
                    'បន្ថែមបុគ្គលិក',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = widget.language;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    final calc = _calculatePayroll();
    final monthTitle = DateFormat('MMMM yyyy').format(_currentMonth);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF2563EB),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Khmer Salary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          // Screenshot Card Modal (📸 Full Statement View)
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: LocalizationService.tr('screenshot_mode', lang),
            onPressed: () => _showScreenshotModal(calc),
          ),
          // View Mode Switcher (Calendar vs List)
          IconButton(
            icon: Icon(
              _viewMode == WorkViewMode.calendar
                  ? Icons.format_list_bulleted_rounded
                  : Icons.calendar_month_rounded,
            ),
            tooltip: _viewMode == WorkViewMode.calendar
                ? LocalizationService.tr('view_list', lang)
                : LocalizationService.tr('view_calendar', lang),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == WorkViewMode.calendar
                    ? WorkViewMode.list
                    : WorkViewMode.calendar;
              });
            },
          ),
          // More Menu: Settings, Payslip, Week Start, Employees, Clear Month
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'settings') {
                _openSalaryConfigDialog();
              } else if (val == 'employees') {
                _showAddEmployeeDialog();
              } else if (val == 'week_start') {
                _showWeekStartDialog();
              } else if (val == 'exchange_rate') {
                _openExchangeRateDialog();
              } else if (val == 'payslip') {
                _showPayslipModal(calc);
              } else if (val == 'clear_month') {
                _confirmClearMonth();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'payslip',
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 10),
                    Text(LocalizationService.tr('payslip_btn', lang)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'employees',
                child: Row(
                  children: [
                    const Icon(Icons.group_add_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 10),
                    Text(LocalizationService.tr('add_employee', lang)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'week_start',
                child: Row(
                  children: [
                    const Icon(Icons.calendar_view_week_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 10),
                    Text(LocalizationService.tr('week_start_title', lang)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'exchange_rate',
                child: Row(
                  children: [
                    const Icon(Icons.currency_exchange_rounded,
                        color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    Text(LocalizationService.tr('rate_setting_title', lang)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined,
                        color: Colors.blueGrey, size: 20),
                    const SizedBox(width: 10),
                    Text(LocalizationService.tr('btn_wage_settings', lang)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear_month',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded,
                        color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      LocalizationService.tr('btn_clear_month', lang),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Exchange Rate Bar
          _buildLiveExchangeRateBar(isDark, lang),

          // Multi-Employee Chip Selector Bar
          _buildEmployeeBar(isDark, lang),

          // Month Switcher Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  monthTitle,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Main Content: Calendar Grid or List View with Swipe-to-Delete
          Expanded(
            child: _viewMode == WorkViewMode.calendar
                ? _buildCalendarView(isDark)
                : _buildListView(isDark, lang),
          ),

          // Clean Minimalist Bottom Summary Bar (Exclusively KRW ₩)
          _buildCleanSummaryBar(calc, isDark, lang),
        ],
      ),
    );
  }

  Widget _buildCalendarView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      children: [
        _buildCalendarGrid(isDark),
        const SizedBox(height: 10),
        // Clean Legend
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AttendanceStatus.values.map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.localizedTitle(widget.language),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(bool isDark, AppLanguage lang) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final List<WorkLog> loggedDays = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final key = _formatDateKey(date);
      final log = _workLogs[key];
      if (log != null) {
        loggedDays.add(log);
      }
    }

    if (loggedDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'គ្មានទិន្នន័យការងារក្នុងខែនេះទេ',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.swipe_left_rounded,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                LocalizationService.tr('swipe_to_delete_hint', lang),
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: loggedDays.length,
            itemBuilder: (ctx, index) {
              final log = loggedDays[index];
              final dateParts = log.dateKey.split('-');
              final dt = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
              final dateLabel = DateFormat('EEE, d MMM').format(dt);

              return Dismissible(
                key: Key(log.dateKey),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text('លុប',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 24),
                    ],
                  ),
                ),
                onDismissed: (_) => _onDeleteWorkLog(log.dateKey),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                  child: ListTile(
                    onTap: () => _openWorkLogSheet(dt),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: log.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      dateLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${log.checkIn} - ${log.checkOut} • ${log.status.localizedTitle(lang)}',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${log.regularHours}h ${log.regularMinutes > 0 ? '${log.regularMinutes}m' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        if (log.otMinutesTotal > 0)
                          Text(
                            '+${log.otHours}h ${log.otMinutes > 0 ? '${log.otMinutes}m' : ''} OT',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    final startingOffset = _weekStartDay.getStartingOffset(firstDayOfMonth);
    final totalCells = startingOffset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    final weekdays = _weekStartDay.weekdays(widget.language);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Weekday Headers (Saturday & Sunday Accented)
          Row(
            children: weekdays.asMap().entries.map((entry) {
              final idx = entry.key;
              Color headerColor;
              if (_weekStartDay == WeekStartDay.saturday) {
                if (idx == 0) {
                  headerColor = const Color(0xFF0284C7); // Sat (Cyan/Sky blue)
                } else if (idx == 1) {
                  headerColor = Colors.redAccent.shade200; // Sun (Red)
                } else {
                  headerColor =
                      isDark ? Colors.grey.shade400 : Colors.grey.shade600;
                }
              } else if (_weekStartDay == WeekStartDay.sunday) {
                if (idx == 0) {
                  headerColor = Colors.redAccent.shade200; // Sun (Red)
                } else if (idx == 6) {
                  headerColor = const Color(0xFF0284C7); // Sat
                } else {
                  headerColor =
                      isDark ? Colors.grey.shade400 : Colors.grey.shade600;
                }
              } else {
                if (idx == 5) {
                  headerColor = const Color(0xFF0284C7); // Sat
                } else if (idx == 6) {
                  headerColor = Colors.redAccent.shade200; // Sun
                } else {
                  headerColor =
                      isDark ? Colors.grey.shade400 : Colors.grey.shade600;
                }
              }

              return Expanded(
                child: Center(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // Days Grid
          for (int row = 0; row < totalRows; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                children: [
                  for (int col = 0; col < 7; col++) ...[
                    Expanded(
                      child: _buildCalendarCell(
                          row, col, startingOffset, daysInMonth, isDark),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(int row, int col, int startingOffset,
      int daysInMonth, bool isDark) {
    final index = row * 7 + col;
    final dayNum = index - startingOffset + 1;

    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 48);
    }

    final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
    final key = _formatDateKey(date);
    final log = _workLogs[key];

    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    Color cellBg = Colors.transparent;
    Color borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    if (log != null) {
      cellBg = log.status.color.withValues(alpha: 0.10);
      borderColor = log.status.color.withValues(alpha: 0.35);
    }

    if (isToday) {
      cellBg = const Color(0xFF2563EB).withValues(alpha: 0.15);
      borderColor = const Color(0xFF2563EB);
    }

    return GestureDetector(
      onTap: () => _openWorkLogSheet(date),
      child: Container(
        margin: const EdgeInsets.all(1.0),
        height: 48,
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isToday ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Day Number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
              decoration: isToday
                  ? BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                  color: isToday
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),

            // Exact Hours & Minutes inside Calendar Cell
            if (log != null)
              _buildCellContent(log)
            else
              Text(
                '-',
                style: TextStyle(
                  fontSize: 8.5,
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCellContent(WorkLog log) {
    if (log.status == AttendanceStatus.overtime) {
      // 2-row layout: Row 1 = Regular Hours & Mins, Row 2 = OT Hours & Mins
      final regStr = log.regularMinutes > 0
          ? '${log.regularHours}h${log.regularMinutes}'
          : '${log.regularHours}h';
      final otStr = log.otMinutes > 0
          ? '+${log.otHours}h${log.otMinutes}'
          : '+${log.otHours}h';

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Regular Hours (Blue badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              regStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 1),
          // Row 2: OT Hours (Amber/Yellow badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              otStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
        ],
      );
    } else if (log.status == AttendanceStatus.present) {
      // Regular Work: e.g. "8h 30m" in Royal Blue badge
      final timeStr = log.regularMinutes > 0
          ? '${log.regularHours}h ${log.regularMinutes}m'
          : '${log.regularHours}h';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          timeStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    } else {
      // Day Off, Leave, Absent
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
        decoration: BoxDecoration(
          color: log.status.color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          log.status.shortBadgeText(widget.language),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }

  Widget _buildLiveExchangeRateBar(bool isDark, AppLanguage lang) {
    final rateStr = widget.salaryConfig.krwToKhrRate.toStringAsFixed(2);
    final usdRateVal = widget.salaryConfig.krwToUsdRate > 0
        ? (1.0 / widget.salaryConfig.krwToUsdRate).round()
        : 1350;

    return InkWell(
      onTap: () => _openExchangeRateDialog(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isRatesLive
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRatesLive ? const Color(0xFF10B981) : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${LocalizationService.tr('live_rate_title', lang)}: ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '1 ₩ = $rateStr ៛',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(1\$ ≈ $usdRateVal ₩)',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  Text(
                    _isRatesLive
                        ? '🟢 ហាងឆេងផ្ទាល់ថ្ងៃនេះ (Live Exchange Rate)'
                        : 'ℹ️ ហាងឆេងចុងក្រោយ • ចុចដើម្បីកំណត់ ឬ Refresh',
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: _isFetchingRates
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF2563EB)),
                    )
                  : const Icon(Icons.sync_rounded,
                      size: 20, color: Color(0xFF2563EB)),
              tooltip: LocalizationService.tr('refresh_rate', lang),
              onPressed: _isFetchingRates
                  ? null
                  : () => _fetchLiveRates(showFeedback: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyTab(CurrencyType type, String label, bool isDark) {
    final isSelected = _activeCurrency == type;
    final activeColor = type == CurrencyType.khr
        ? const Color(0xFF10B981)
        : (type == CurrencyType.usd
            ? const Color(0xFF0D9488)
            : const Color(0xFF2563EB));

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeCurrency = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? activeColor.withValues(alpha: 0.25) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
            border: isSelected
                ? Border.all(
                    color: activeColor.withValues(alpha: 0.5), width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Minimalist, Clean Bottom Summary Bar with Currency Switcher
  Widget _buildCleanSummaryBar(
      PayrollCalculation calc, bool isDark, AppLanguage lang) {
    String netDisplay;
    String netLabel;
    String netSubtitle;
    Color netColor;

    switch (_activeCurrency) {
      case CurrencyType.krw:
        netDisplay = calc.formattedNetWon;
        netLabel = LocalizationService.tr('est_salary', lang);
        netSubtitle = calc.config.autoMinistryWage
            ? '🏛️ ស្តង់ដារក្រសួងការងារ ${_currentMonth.year} (${calc.config.baseRate.round()} ₩/ម៉ោង)'
            : 'គិតតាមអត្រា ${calc.config.baseRate.round()} ₩/ម៉ោង';
        netColor = const Color(0xFF2563EB);
        break;
      case CurrencyType.khr:
        netDisplay = calc.formattedNetKhr;
        netLabel = 'ប៉ាន់ស្មានផ្ញើទៅផ្ទះ (KHR ៛)';
        netSubtitle =
            'ហាងឆេងថ្ងៃនេះ 1 ₩ = ${widget.salaryConfig.krwToKhrRate} ៛';
        netColor = const Color(0xFF10B981);
        break;
      case CurrencyType.usd:
        netDisplay = calc.formattedNetUsd;
        netLabel = 'ប៉ាន់ស្មានជាដុល្លារ (USD \$)';
        netSubtitle = '1 ₩ = ${widget.salaryConfig.krwToUsdRate} \$';
        netColor = const Color(0xFF0D9488);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Currency Switcher Tabs (₩ Won, ៛ Riel, $ USD)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildCurrencyTab(CurrencyType.krw, '🇰🇷 ₩ វ៉ុន', isDark),
                  const SizedBox(width: 4),
                  _buildCurrencyTab(CurrencyType.khr, '🇰🇭 ៛ រៀល', isDark),
                  const SizedBox(width: 4),
                  _buildCurrencyTab(CurrencyType.usd, '🇺🇸 \$ USD', isDark),
                ],
              ),
            ),

            // Middle Row: Big Bold Total & Payslip Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        netLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          netDisplay,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: netColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Text(
                        netSubtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showPayslipModal(calc),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: Text(
                    LocalizationService.tr('payslip_btn', lang),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom Row: Clean 3 Pills (Total Hours, OT Hours, Workdays)
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatPill(
                    label: 'សរុប',
                    value: calc.formatTotalDuration(lang),
                    color: const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatPill(
                    label: 'ថែមម៉ោង OT',
                    value: calc.formatOtDuration(lang),
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatPill(
                    label: 'ថ្ងៃធ្វើការ',
                    value: '${calc.totalWorkingDays} ថ្ងៃ',
                    color: Colors.blueGrey,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatPill({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
