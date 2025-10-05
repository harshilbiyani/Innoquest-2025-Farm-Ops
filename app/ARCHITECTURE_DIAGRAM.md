# 🎨 Multi-Language System Architecture

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP STARTUP                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  main.dart - Initialize LocalizationService                     │
│  ✓ Load saved language from SharedPreferences                   │
│  ✓ Provide LocalizationService to entire app                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────┴─────────┐
                    │   First Time?     │
                    └─────────┬─────────┘
                    YES ↓              ↓ NO
                        │              │
         ┌──────────────┘              └──────────────┐
         ↓                                            ↓
┌──────────────────────┐                    ┌──────────────────────┐
│ Language Selection   │                    │  Go to Home Page     │
│ - English            │                    │  (with saved lang)   │
│ - हिंदी (Hindi)      │                    └──────────────────────┘
│ - मराठी (Marathi)    │
└──────────────────────┘
         ↓
┌──────────────────────┐
│ User Selects Language│
│ ✓ Save to Storage    │
│ ✓ Update Provider    │
│ ✓ Navigate to Login  │
└──────────────────────┘
```

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      LOCALIZATION LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  LocalizationService (ChangeNotifier)                           │
│  ├── Locale _locale                                             │
│  ├── loadLanguage() → Load from SharedPreferences               │
│  ├── changeLanguage(code) → Save & notify                       │
│  └── currentLanguageName → Get language display name            │
│                                                                  │
│  AppLocalizations                                                │
│  ├── _englishStrings (Map<String, String>)                     │
│  ├── _hindiStrings (Map<String, String>)                       │
│  ├── _marathiStrings (Map<String, String>)                     │
│  └── translate(key) → Get translation for current locale        │
│                                                                  │
│  LocalizationExtension                                          │
│  └── context.localizations → Easy access in any widget          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      STORAGE LAYER                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  UserPreferences (SharedPreferences wrapper)                    │
│  ├── saveLanguage(code) → Persist language choice               │
│  └── getLanguage() → Retrieve saved language                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Any Widget                                                      │
│  └── context.localizations.keyName                              │
│      ↓                                                           │
│      Returns translated string based on current locale          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Translation Flow

```
User Opens App
     ↓
Check if language saved?
     ├─ YES → Load language → Apply to app
     └─ NO → Show language selector → Save choice → Apply to app
                                            ↓
                            ┌───────────────┴───────────────┐
                            │                               │
                    Text Widget Renders                 Button Renders
                            │                               │
                    calls context.localizations.home  calls context.localizations.save
                            │                               │
                    LocalizationService checks locale       │
                            │                               │
                    ┌───────┴────────┬──────────┐          │
                    ↓                ↓          ↓          ↓
               If 'en'          If 'hi'    If 'mr'    Returns appropriate
               return          return      return     translation
               "Home"          "होम"       "होम"      for current locale
```

## File Structure

```
lib/
├── main.dart ───────────────────── App entry, provides LocalizationService
├── language_selection_page.dart ─── Language selector UI
│
├── services/
│   ├── localization_service.dart ── Main localization logic
│   │   ├── LocalizationService (Provider)
│   │   ├── AppLocalizations (Translation strings)
│   │   ├── LocalizationExtension
│   │   ├── _englishStrings
│   │   ├── _hindiStrings
│   │   └── _marathiStrings
│   │
│   └── user_preferences.dart ────── Storage for language preference
│
└── [all other pages] ────────────── Use context.localizations.key
```

## Data Flow Sequence

```
1. App Start
   ↓
2. main.dart creates LocalizationService
   ↓
3. LocalizationService.loadLanguage() called
   ↓
4. UserPreferences.getLanguage() retrieves saved language
   ↓
5. If language found → Set locale
   If no language → Use default (English)
   ↓
6. LocalizationService provided to entire widget tree
   ↓
7. MaterialApp configured with:
   - locale (current language)
   - supportedLocales (en, hi, mr)
   - localizationsDelegates
   ↓
8. Any widget can access via context.localizations
   ↓
9. Widget requests translation → Returns string in current language
```

## Language Change Flow

```
User Action (Select Language)
         ↓
LocalizationService.changeLanguage(code)
         ↓
├─ Update _locale
├─ Save to SharedPreferences (UserPreferences.saveLanguage)
└─ notifyListeners()
         ↓
Provider notifies all listeners
         ↓
MaterialApp rebuilds with new locale
         ↓
All widgets rebuild
         ↓
context.localizations now returns translations in new language
         ↓
UI displays in new language
```

## Example: Button Click to Logout

```
┌──────────────────────┐
│  User taps Logout    │
│  button in Home Page │
└──────────┬───────────┘
           ↓
┌─────────────────────────────────────┐
│  _showLogoutDialog() called          │
│  final loc = context.localizations;  │
└──────────┬──────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  AlertDialog shows with:             │
│  - Title: loc.logout                 │
│  - Cancel button: loc.cancel         │
│  - Confirm button: loc.logout        │
└──────────┬──────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  LocalizationService checks locale   │
│  If locale.languageCode == 'en'      │
│    return "Logout", "Cancel"         │
│  If locale.languageCode == 'hi'      │
│    return "लॉगआउट", "रद्द करें"     │
│  If locale.languageCode == 'mr'      │
│    return "लॉगआउट", "रद्द करा"      │
└─────────────────────────────────────┘
```

## Key Benefits of This Architecture

✅ **Separation of Concerns**
- Localization logic separate from UI
- Easy to maintain and update

✅ **Type-Safe Access**
- No string typos with getter methods
- IDE autocomplete support

✅ **Persistent Storage**
- User choice remembered
- No re-selection needed

✅ **Easy to Extend**
- Add new languages by adding translation maps
- Add new strings in one place

✅ **Provider Pattern**
- Reactive updates
- Automatic UI rebuild on language change

✅ **Clean API**
- Simple: `context.localizations.keyName`
- Works anywhere with BuildContext

---

This architecture provides a robust, maintainable, and scalable solution for multi-language support in your Flutter app! 🎉
