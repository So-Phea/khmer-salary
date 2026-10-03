# 🚀 Tica - Productivity & Task Management App

កម្មវិធីគ្រប់គ្រងការងារប្រចាំថ្ងៃ និងផលិតភាព (Productivity & Task Management Mobile App) បង្កើតឡើងដោយ **Flutter & Dart**។

---

## 📱 មុខងារសំខាន់ៗ (Features Implemented)

1. **ផ្ទាំងការងារឆ្លាតវៃ (Smart Dashboard):**
   - បង្ហាញកាលបរិច្ឆេទ និងការស្វាគមន៍ផ្ទាល់ខ្លួន
   - **Productivity Progress Gauge**: បង្ហាញភាគរយនៃការងារដែលបានបញ្ចប់ (%) ជាមួយនឹងរង្វាស់ Gradient ទំនើប
   - បង្ហាញចំនួនសរុប (Total), រួចរាល់ (Done), នៅសល់ (Pending), និងការងារហួសកំណត់ (Overdue)
   - មុខងារ Filter រហ័ស៖ ទាំងអស់ (All), ថ្ងៃនេះ (Today), បន្ទាន់ (Urgent), ហួសកំណត់ (Overdue), រួចរាល់ (Done)
   - ស្វែងរកការងារ (Search Bar) តាមចំណងជើង និងព័ត៌មានលម្អិត

2. **ការគ្រប់គ្រងការងារ (Task Management):**
   - បង្កើត និងកែប្រែការងារ (Add & Edit Task Modal)
   - បែងចែកតាមផ្នែក (Categories) ជាមួយ Icon និងពណ៌៖
     - 💼 ការងារ (Work)
     - 📚 ការសិក្សា (Study)
     - 👨‍👩‍👧 គ្រួសារ (Family)
     - 👤 ផ្ទាល់ខ្លួន (Personal)
     - ❤️ សុខភាព (Health)
   - កម្រិតអាទិភាព (Priority): ខ្ពស់ (High), មធ្យម (Medium), ទាប (Low)
   - កំណត់កាលបរិច្ឆេទ និងម៉ោង (Due Date & Time Picker)
   - Checkbox អមដោយ Effect បន្ទាត់ឆូតពេលបញ្ចប់
   - អូសទៅឆ្វេងដើម្បីលុប (Swipe-to-delete)

3. **កាលវិភាគប្រចាំថ្ងៃ (Interactive Calendar):**
   - ផ្ទាំងជ្រើសរើសថ្ងៃផ្តេក (Horizontal Day Picker Strip)
   - មើលបញ្ជីការងារតាមថ្ងៃជាក់លាក់

4. **របាយការណ៍ផលិតភាព (Productivity Analytics):**
   - **Productivity Score (ពិន្ទុផលិតភាព)** ធៀបនឹង ១០០
   - ក្រាហ្វិកសកម្មភាពប្រចាំសប្តាហ៍ (Weekly Activity Bar Chart)
   - សូចនាករ KPI សំខាន់ៗ (Total, Completed, Pending, Overdue)
   - ការវិភាគតាមប្រភេទការងារ (Category Breakdown Progress Bars)

5. **ប្រព័ន្ធគណនី និងការកំណត់ (Profile & Settings):**
   - គណនីអ្នកប្រើប្រាស់ និងការកែប្រែឈ្មោះ/អ៊ីមែល
   - **Tica Premium Modal** ($2.99/ខែ) សម្រាប់មុខងារ Sync Calendar, No Ads, Cloud Backup
   - ជម្រើសប្ដូររូបរាងងងឹត/ភ្លឺ (Dark Mode & Light Mode)
   - **Offline Mode**: ទិន្នន័យទាំងអស់ត្រូវបានរក្សាទុកដោយស្វ័យប្រវត្តិតាមរយៈ Local Storage (`shared_preferences`) មិនបាត់បង់ទោះគ្មានអ៊ីនធឺណិត

---

## 🛠️ រចនាសម្ព័ន្ធកូដ (Architecture)

```text
tica/
├── lib/
│   ├── main.dart                      # ចំណុចចាប់ផ្ដើម & Navigation Shell
│   ├── models/
│   │   ├── task_model.dart            # Model ការងារ, Category, Priority
│   │   └── user_model.dart            # Model គណនីអ្នកប្រើប្រាស់
│   ├── services/
│   │   └── storage_service.dart       # Offline Persistence (SharedPreferences)
│   ├── screens/
│   │   ├── dashboard_screen.dart      # ផ្ទាំងការងារធំ & Smart Dashboard
│   │   ├── calendar_screen.dart       # ផ្ទាំងកាលវិភាគប្រចាំថ្ងៃ
│   │   ├── analytics_screen.dart      # ផ្ទាំងរបាយការណ៍ផលិតភាព & ក្រាហ្វិក
│   │   ├── profile_screen.dart        # ផ្ទាំងគណនី, ការកំណត់ & Premium
│   │   └── add_task_sheet.dart        # ផ្ទាំង Bottom Sheet បន្ថែម/កែប្រែការងារ
│   └── widgets/
│       ├── task_card.dart             # កាតការងារនីមួយៗ
│       └── productivity_card.dart     # កាតវឌ្ឍនភាព Gradient & Gauge
└── test/
    └── widget_test.dart               # Test Suite
```

---

## 💻 របៀបដំណើរការ (How to Run)

នៅក្នុង Terminal៖
```bash
cd /Users/lansophea/.gemini/antigravity/scratch/tica
flutter run
```
ឬបើកដោយផ្ទាល់នៅក្នុង **Android Studio** ឬ **VS Code**!
