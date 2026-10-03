enum AppLanguage { khmer, korean, english }

class LocalizationService {
  static const Map<String, Map<AppLanguage, String>> _strings = {
    // App & Navigation
    'app_title': {
      AppLanguage.khmer: 'Khmer Salary - គណនាប្រាក់ខែ និងម៉ោងការងារ',
      AppLanguage.korean: 'Khmer Salary - 크메르 샐러리 급여관리',
      AppLanguage.english: 'Khmer Salary - Precision Payroll',
    },
    'app_name_display': {
      AppLanguage.khmer: 'Khmer Salary',
      AppLanguage.korean: 'Khmer Salary',
      AppLanguage.english: 'Khmer Salary',
    },
    'app_tagline': {
      AppLanguage.khmer: 'កត់ត្រាម៉ោងការងារ និងប្រាក់ខែដល់កម្រិតនាទី',
      AppLanguage.korean: '분 단위 정밀 근태 및 급여 계산',
      AppLanguage.english: 'Minute-Precision Hours & Payroll',
    },
    'tab_dashboard': {
      AppLanguage.khmer: 'ផ្ទាំងការងារ',
      AppLanguage.korean: '대시보드',
      AppLanguage.english: 'Dashboard',
    },
    'tab_calendar': {
      AppLanguage.khmer: 'កាលវិភាគ',
      AppLanguage.korean: '일정표',
      AppLanguage.english: 'Schedule',
    },
    'tab_payroll': {
      AppLanguage.khmer: 'ម៉ោង & ប្រាក់ខែ',
      AppLanguage.korean: '근무 & 급여',
      AppLanguage.english: 'Work & Payroll',
    },
    'tab_analytics': {
      AppLanguage.khmer: 'របាយការណ៍',
      AppLanguage.korean: '통계보고서',
      AppLanguage.english: 'Analytics',
    },
    'tab_profile': {
      AppLanguage.khmer: 'គណនី & កំណត់',
      AppLanguage.korean: '설정 & 계정',
      AppLanguage.english: 'Settings',
    },

    // Payroll Screen Header & Minimalist Bar
    'payroll_title': {
      AppLanguage.khmer: 'Khmer Salary',
      AppLanguage.korean: 'Khmer Salary',
      AppLanguage.english: 'Khmer Salary',
    },
    'est_salary': {
      AppLanguage.khmer: 'សរុបប្រាក់ខែជាក់ស្តែង (Total Pay)',
      AppLanguage.korean: '총 예상 실수령액',
      AppLanguage.english: 'Total Net Salary',
    },
    'total_work_time': {
      AppLanguage.khmer: 'សរុបម៉ោងធ្វើការ',
      AppLanguage.korean: '총 근무시간',
      AppLanguage.english: 'Total Hours',
    },
    'payslip_btn': {
      AppLanguage.khmer: 'វិក្កយបត្រ',
      AppLanguage.korean: '급여명세서',
      AppLanguage.english: 'Payslip',
    },
    'btn_wage_settings': {
      AppLanguage.khmer: 'កំណត់ប្រាក់ឈ្នួល',
      AppLanguage.korean: '시급/급여 설정',
      AppLanguage.english: 'Wage Settings',
    },

    // KPIs
    'kpi_work_days': {
      AppLanguage.khmer: 'ថ្ងៃធ្វើការ',
      AppLanguage.korean: '근무일수',
      AppLanguage.english: 'Work Days',
    },
    'kpi_regular_hours': {
      AppLanguage.khmer: 'ម៉ោងធម្មតា',
      AppLanguage.korean: '기본시간',
      AppLanguage.english: 'Regular Hrs',
    },
    'kpi_ot_hours': {
      AppLanguage.khmer: 'ថែមម៉ោង OT',
      AppLanguage.korean: '연장(OT)',
      AppLanguage.english: 'Overtime',
    },
    'kpi_absences': {
      AppLanguage.khmer: 'អវត្តមាន',
      AppLanguage.korean: '결근',
      AppLanguage.english: 'Absence',
    },

    // Attendance Status
    'status_present': {
      AppLanguage.khmer: 'មកធ្វើការ (ពេញម៉ោង)',
      AppLanguage.korean: '정상근무',
      AppLanguage.english: 'Present',
    },
    'status_ot': {
      AppLanguage.khmer: 'ថែមម៉ោង (OT)',
      AppLanguage.korean: '연장근무 (OT)',
      AppLanguage.english: 'Overtime',
    },
    'status_leave': {
      AppLanguage.khmer: 'ឈប់ច្បាប់',
      AppLanguage.korean: '유급휴가',
      AppLanguage.english: 'Paid Leave',
    },
    'status_absent': {
      AppLanguage.khmer: 'អវត្តមាន (ឥតច្បាប់)',
      AppLanguage.korean: '무단결근',
      AppLanguage.english: 'Absent',
    },
    'status_dayoff': {
      AppLanguage.khmer: 'ថ្ងៃសម្រាក',
      AppLanguage.korean: '휴무일',
      AppLanguage.english: 'Day Off',
    },

    // Work Log Sheet & Minute Precision
    'quick_log_title': {
      AppLanguage.khmer: 'កត់ត្រាម៉ោងការងារ & នាទី',
      AppLanguage.korean: '출퇴근 및 근무시간 (분 단위)',
      AppLanguage.english: 'Log Work Hours & Minutes',
    },
    'quick_presets': {
      AppLanguage.khmer: 'ជ្រើសរើសរហ័ស (Quick Presets):',
      AppLanguage.korean: '빠른 선택 (Quick Presets):',
      AppLanguage.english: 'Quick Presets:',
    },
    'preset_8h': {
      AppLanguage.khmer: '8h 00m ពេញម៉ោង',
      AppLanguage.korean: '정상 8시간',
      AppLanguage.english: 'Full 8h 00m',
    },
    'preset_8h30m': {
      AppLanguage.khmer: '8h 30m (+30ន)',
      AppLanguage.korean: '8시간 30분',
      AppLanguage.english: '8h 30m',
    },
    'preset_8h45m': {
      AppLanguage.khmer: '8h 45m (+45ន)',
      AppLanguage.korean: '8시간 45분',
      AppLanguage.english: '8h 45m (+45m)',
    },
    'preset_10h15m': {
      AppLanguage.khmer: '10h 15m (+2h15 OT)',
      AppLanguage.korean: '10시간 15분 (+OT)',
      AppLanguage.english: '10h 15m (+OT)',
    },
    'preset_10h30m': {
      AppLanguage.khmer: '10h 30m (+2h30 OT)',
      AppLanguage.korean: '10시간 30분 (+2.5 OT)',
      AppLanguage.english: '10h 30m (+2.5h OT)',
    },
    'preset_dayoff': {
      AppLanguage.khmer: 'ថ្ងៃសម្រាក (휴무)',
      AppLanguage.korean: '주말/공휴일 휴무',
      AppLanguage.english: 'Day Off',
    },
    'auto_calc_btn': {
      AppLanguage.khmer: '⚡ គណនាម៉ោងស្វ័យប្រវត្តិតាមម៉ោងចូល/ចេញ',
      AppLanguage.korean: '⚡ 출퇴근 시간으로 자동 계산',
      AppLanguage.english: '⚡ Auto-Calculate from Check-in/Out',
    },
    'regular_work_time': {
      AppLanguage.khmer: 'ម៉ោងការងារធម្មតា (Regular Time):',
      AppLanguage.korean: '기본 근무시간 (Regular Time):',
      AppLanguage.english: 'Regular Work Time:',
    },
    'ot_work_time': {
      AppLanguage.khmer: 'ម៉ោងថែមម៉ោង OT (Overtime):',
      AppLanguage.korean: '연장근무 시간 (OT Time):',
      AppLanguage.english: 'Overtime Work Time (OT):',
    },
    'hours_unit': {
      AppLanguage.khmer: 'ម៉ោង',
      AppLanguage.korean: '시간',
      AppLanguage.english: 'hrs',
    },
    'minutes_unit': {
      AppLanguage.khmer: 'នាទី',
      AppLanguage.korean: '분',
      AppLanguage.english: 'mins',
    },
    'check_in': {
      AppLanguage.khmer: 'ម៉ោងចូលធ្វើការ (Check In)',
      AppLanguage.korean: '출근시간',
      AppLanguage.english: 'Check In',
    },
    'check_out': {
      AppLanguage.khmer: 'ម៉ោងចេញពីធ្វើការ (Check Out)',
      AppLanguage.korean: '퇴근시간',
      AppLanguage.english: 'Check Out',
    },
    'late_mins': {
      AppLanguage.khmer: 'មកយឺត',
      AppLanguage.korean: '지각(분)',
      AppLanguage.english: 'Late (Mins)',
    },
    'note': {
      AppLanguage.khmer: 'កំណត់ចំណាំ (Note)',
      AppLanguage.korean: '메모 (Note)',
      AppLanguage.english: 'Note',
    },
    'btn_save': {
      AppLanguage.khmer: 'រក្សាទុកទិន្នន័យ',
      AppLanguage.korean: '저장하기',
      AppLanguage.english: 'Save Log',
    },

    // Delete & Clean Features
    'btn_delete': {
      AppLanguage.khmer: 'លុបកំណត់ត្រាថ្ងៃនេះ',
      AppLanguage.korean: '이 날짜 기록 삭제',
      AppLanguage.english: 'Delete Record',
    },
    'confirm_delete_day': {
      AppLanguage.khmer: 'តើអ្នកពិតជាចង់លុបទិន្នន័យថ្ងៃនេះមែនទេ? ម៉ោងនឹងត្រូវបានកាត់ចេញពីប្រាក់ខែសរុប។',
      AppLanguage.korean: '해당 날짜의 근무기록을 삭제하시겠습니까? 총 급여가 자동으로 재계산됩니다.',
      AppLanguage.english: 'Are you sure you want to delete this record? Total pay will be recalculated.',
    },
    'btn_clear_month': {
      AppLanguage.khmer: 'លុបទិន្នន័យខែនេះទាំងអស់',
      AppLanguage.korean: '이번 달 전체 기록 삭제',
      AppLanguage.english: 'Clear All Month Records',
    },
    'confirm_clear_month': {
      AppLanguage.khmer: 'តើអ្នកចង់លុបទិន្នន័យការងារទាំងអស់ក្នុងខែនេះចោលមែនទេ? (ទិន្នន័យដែលលុបហើយមិនអាចយកមកវិញបានឡើយ)',
      AppLanguage.korean: '이번 달의 모든 근무 기록을 삭제하시겠습니까? (삭제 후 복구 불가)',
      AppLanguage.english: 'Are you sure you want to delete all work records for this month? This cannot be undone.',
    },
    'btn_cancel': {
      AppLanguage.khmer: 'បោះបង់',
      AppLanguage.korean: '취소',
      AppLanguage.english: 'Cancel',
    },
    'view_calendar': {
      AppLanguage.khmer: 'ប្រតិទិន',
      AppLanguage.korean: '달력보기',
      AppLanguage.english: 'Calendar',
    },
    'view_list': {
      AppLanguage.khmer: 'បញ្ជីការងារ',
      AppLanguage.korean: '목록보기',
      AppLanguage.english: 'List View',
    },
    'swipe_to_delete_hint': {
      AppLanguage.khmer: 'អូសទៅឆ្វេងដើម្បីលុបថ្ងៃធ្វើការ 🗑️',
      AppLanguage.korean: '왼쪽으로 밀어서 삭제 🗑️',
      AppLanguage.english: 'Swipe left to delete 🗑️',
    },
    'deleted_success': {
      AppLanguage.khmer: 'បានលុបទិន្នន័យដោយជោគជ័យ!',
      AppLanguage.korean: '기록이 삭제되었습니다.',
      AppLanguage.english: 'Record deleted successfully!',
    },
    'month_cleared_success': {
      AppLanguage.khmer: 'បានសម្អាតទិន្នន័យខែនេះរួចរាល់!',
      AppLanguage.korean: '이번 달 기록이 모두 초기화되었습니다.',
      AppLanguage.english: 'Month records cleared!',
    },

    // Payslip Modal
    'payslip_header': {
      AppLanguage.khmer: 'វិក្កយបត្រប្រាក់ខែ (Khmer Salary)',
      AppLanguage.korean: '월간 급여명세서 (Khmer Salary)',
      AppLanguage.english: 'Monthly Payslip (Khmer Salary)',
    },
    'base_pay': {
      AppLanguage.khmer: 'ប្រាក់ខែគោល',
      AppLanguage.korean: '기본급',
      AppLanguage.english: 'Base Salary',
    },
    'ot_pay': {
      AppLanguage.khmer: 'ប្រាក់ថែមម៉ោង (OT)',
      AppLanguage.korean: '연장근로수당 (OT)',
      AppLanguage.english: 'Overtime Pay',
    },
    'deductions': {
      AppLanguage.khmer: 'ប្រាក់កាត់កង (អវត្តមាន/យឺត)',
      AppLanguage.korean: '공제액 (결근/지각)',
      AppLanguage.english: 'Deductions',
    },
    'net_pay': {
      AppLanguage.khmer: 'ប្រាក់ខែជាក់ស្តែងត្រូវបើក (KRW ₩)',
      AppLanguage.korean: '실수령액 (NET PAY)',
      AppLanguage.english: 'Net Salary (KRW ₩)',
    },
    'btn_copy': {
      AppLanguage.khmer: 'ចម្លងវិក្កយបត្រ',
      AppLanguage.korean: '명세서 복사',
      AppLanguage.english: 'Copy Slip',
    },
    'btn_telegram': {
      AppLanguage.khmer: 'ផ្ញើទៅ Telegram / Kakao',
      AppLanguage.korean: '텔레그램/카카오톡 전송',
      AppLanguage.english: 'Share Slip',
    },

    // Language setting
    'language_setting': {
      AppLanguage.khmer: 'ភាសា (Language / 언어)',
      AppLanguage.korean: '언어 설정 (Language)',
      AppLanguage.english: 'Language',
    },

    // Live Exchange Rate & Currency
    'live_rate_title': {
      AppLanguage.khmer: 'ហាងឆេងប្រចាំថ្ងៃ (Live Rate)',
      AppLanguage.korean: '실시간 오늘의 환율',
      AppLanguage.english: 'Daily Live Exchange Rate',
    },
    'live_rate_badge': {
      AppLanguage.khmer: 'ហាងឆេងផ្ទាល់',
      AppLanguage.korean: '실시간',
      AppLanguage.english: 'Live',
    },
    'refresh_rate': {
      AppLanguage.khmer: 'ទាញយកហាងឆេងថ្មី',
      AppLanguage.korean: '환율 새로고침',
      AppLanguage.english: 'Refresh Rate',
    },
    'exchange_rate_updated': {
      AppLanguage.khmer: '✅ បានធ្វើបច្ចុប្បន្នភាពហាងឆេងថ្ងៃនេះដោយជោគជ័យ!',
      AppLanguage.korean: '✅ 오늘의 환율 정보가 갱신되었습니다.',
      AppLanguage.english: '✅ Exchange rate updated to today\'s live rates!',
    },
    'rate_setting_title': {
      AppLanguage.khmer: 'អត្រាប្តូរប្រាក់ (Exchange Rate)',
      AppLanguage.korean: '환율 설정 (Exchange Rate)',
      AppLanguage.english: 'Exchange Rate Settings',
    },
    'remit_est_label': {
      AppLanguage.khmer: 'ប៉ាន់ស្មានផ្ញើទៅផ្ទះ',
      AppLanguage.korean: '고국 예상 송금액',
      AppLanguage.english: 'Est. Remittance',
    },
    'currency_tab_krw': {
      AppLanguage.khmer: '₩ វ៉ុន',
      AppLanguage.korean: '₩ 원화',
      AppLanguage.english: '₩ KRW',
    },
    'currency_tab_khr': {
      AppLanguage.khmer: '៛ រៀល',
      AppLanguage.korean: '៛ 리엘',
      AppLanguage.english: '៛ KHR',
    },
    'currency_tab_usd': {
      AppLanguage.khmer: '\$ ដុល្លារ',
      AppLanguage.korean: '\$ 달러',
      AppLanguage.english: '\$ USD',
    },

    // Employee & Team Tracking
    'employees_title': {
      AppLanguage.khmer: 'គ្រប់គ្រងបុគ្គលិក',
      AppLanguage.korean: '직원 관리',
      AppLanguage.english: 'Employees',
    },
    'add_employee': {
      AppLanguage.khmer: 'បន្ថែមបុគ្គលិកថ្មី',
      AppLanguage.korean: '직원 추가',
      AppLanguage.english: 'Add Employee',
    },
    'edit_employee': {
      AppLanguage.khmer: 'កែប្រែព័ត៌មានបុគ្គលិក',
      AppLanguage.korean: '직원 정보 수정',
      AppLanguage.english: 'Edit Employee',
    },
    'delete_employee': {
      AppLanguage.khmer: 'លុบบុគ្គលិក',
      AppLanguage.korean: '직원 삭제',
      AppLanguage.english: 'Delete Employee',
    },
    'confirm_delete_emp': {
      AppLanguage.khmer: 'តើអ្នកពិតជាចង់លុบบុគ្គលិកនេះមែនទេ? កំណត់ត្រាការងារទាំងអស់របស់បុគ្គលិកនេះនឹងត្រូវលុប។',
      AppLanguage.korean: '이 직원을 삭제하시겠습니까? 관련된 모든 근무 기록이 삭제됩니다.',
      AppLanguage.english: 'Are you sure you want to delete this employee? All related work records will be removed.',
    },
    'emp_name_label': {
      AppLanguage.khmer: 'ឈ្មោះបុគ្គលិក',
      AppLanguage.korean: '직원 이름',
      AppLanguage.english: 'Employee Name',
    },
    'emp_role_label': {
      AppLanguage.khmer: 'តួនាទី / ផ្នែក',
      AppLanguage.korean: '직책 / 파트',
      AppLanguage.english: 'Role / Department',
    },

    // Week start setting
    'week_start_title': {
      AppLanguage.khmer: 'ថ្ងៃចាប់ផ្តើមសប្តាហ៍',
      AppLanguage.korean: '주 시작 요일',
      AppLanguage.english: 'Week Starts On',
    },
    'week_start_sat': {
      AppLanguage.khmer: 'សៅរ៍ ដល់ អាទិត្យ (Sat - Sun)',
      AppLanguage.korean: '토요일 시작 (토-금)',
      AppLanguage.english: 'Saturday (Sat - Fri)',
    },
    'week_start_mon': {
      AppLanguage.khmer: 'ច័ន្ទ ដល់ អាទិត្យ (Mon - Sun)',
      AppLanguage.korean: '월요일 시작 (월-일)',
      AppLanguage.english: 'Monday (Mon - Sun)',
    },
    'week_start_sun': {
      AppLanguage.khmer: 'អាទិត្យ ដល់ សៅរ៍ (Sun - Sat)',
      AppLanguage.korean: '일요일 시작 (일-토)',
      AppLanguage.english: 'Sunday (Sun - Sat)',
    },

    // Screenshot & Full Calendar View
    'screenshot_mode': {
      AppLanguage.khmer: 'ថតចម្លងប្រតិទិន (Screenshot)',
      AppLanguage.korean: '달력 스크린샷 모드',
      AppLanguage.english: 'Screenshot View',
    },
    'screenshot_tip': {
      AppLanguage.khmer: 'ផ្ទាំងពេញលេញ ងាយស្រួលថតចម្លងអេក្រង់',
      AppLanguage.korean: '한 화면 캡처용 전체 달력',
      AppLanguage.english: 'Full Calendar View for Screenshot',
    },

    // Ministry of Labor Statutory Minimum Wage
    'ministry_wage_title': {
      AppLanguage.khmer: 'ប្រាក់ឈ្នួលអប្បបរមាក្រសួងការងារកូរ៉េ (MOEL)',
      AppLanguage.korean: '고용노동부 법정 최저임금',
      AppLanguage.english: 'Ministry Statutory Minimum Wage',
    },
    'auto_ministry_rate_title': {
      AppLanguage.khmer: 'ប្រាក់ម៉ោងស្វ័យប្រវត្តិតាមឆ្នាំ (ក្រសួង)',
      AppLanguage.korean: '연도별 법정 최저시급 자동 적용',
      AppLanguage.english: 'Auto-sync Statutory Wage by Year',
    },
    'auto_ministry_rate_desc': {
      AppLanguage.khmer: 'កម្មវិធីនឹងទាញយកប្រាក់ម៉ោង និង OT ផ្លូវការរបស់ក្រសួងការងារកូរ៉េដោយស្វ័យប្រវត្តិតាមឆ្នាំ',
      AppLanguage.korean: '달력 연도에 맞춰 고용노동부 공식 시급 및 연장(OT) 단가를 자동으로 적용합니다.',
      AppLanguage.english: 'Automatically applies official statutory hourly & OT rates based on calendar year.',
    },
    'ministry_badge_label': {
      AppLanguage.khmer: 'ស្តង់ដារក្រសួងការងារកូរ៉េ',
      AppLanguage.korean: '고용노동부 고시 기준',
      AppLanguage.english: 'Official Ministry Standard',
    },
    'statutory_year_selector': {
      AppLanguage.khmer: 'ជ្រើសរើសឆ្នាំកំណត់របស់ក្រសួង',
      AppLanguage.korean: '적용 연도 선택',
      AppLanguage.english: 'Select Statutory Year',
    },
    'statutory_monthly_equivalent': {
      AppLanguage.khmer: 'ប្រាក់ខែគោលស្តង់ដារ (២០៩ ម៉ោង)',
      AppLanguage.korean: '월 환산액 (209시간 기준)',
      AppLanguage.english: 'Monthly Standard (209 hrs)',
    },
  };

  static String tr(String key, AppLanguage lang) {
    if (_strings.containsKey(key)) {
      return _strings[key]![lang] ?? _strings[key]![AppLanguage.khmer] ?? key;
    }
    return key;
  }
}
