/// Prosta klasa lokalizacji — obsługa PL i EN
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static final Map<String, Map<String, String>> _translations = {
    // ==================== OGÓLNE ====================
    'appTitle': {'pl': 'BeHydrated', 'en': 'BeHydrated'},

    // ==================== GŁÓWNY EKRAN ====================
    'statistics': {'pl': 'Statystyki', 'en': 'Statistics'},
    'ofGoal': {'pl': 'z', 'en': 'of'},
    'percentGoal': {'pl': 'celu', 'en': 'of goal'},
    'addAgain': {'pl': 'Dodaj ponownie', 'en': 'Add again'},
    'noEntriesToday': {
      'pl': 'Brak wpisów na dzisiaj.\nDodaj swoją pierwszą wodę!',
      'en': 'No entries today.\nAdd your first water!',
    },
    'addWater': {'pl': 'Dodaj wodę', 'en': 'Add water'},
    'added': {'pl': 'Dodano', 'en': 'Added'},
    'earlyStatus': {'pl': 'Wcześnie! 👏', 'en': 'Early! 👏'},
    'lateStatus': {'pl': 'Pora spać! 😴', 'en': 'It\'s late! 😴'},
    'addAgainTooltip': {'pl': 'Dodaj ponownie', 'en': 'Add again'},
    'deleteTooltip': {'pl': 'Usuń', 'en': 'Delete'},

    // ==================== DODAJ WODĘ ====================
    'addWaterTitle': {'pl': 'Dodaj wodę', 'en': 'Add water'},
    'addCustomAmount': {'pl': 'Dodaj własną ilość', 'en': 'Add custom amount'},
    'newAmount': {'pl': 'Nowa ilość', 'en': 'New amount'},
    'enterAmountAndAdd': {
      'pl': 'Podaj ilość wody i dodaj jako przycisk',
      'en': 'Enter water amount and add as button',
    },
    'amountMl': {'pl': 'Ilość (ml)', 'en': 'Amount (ml)'},
    'cancel': {'pl': 'Anuluj', 'en': 'Cancel'},
    'addButton': {'pl': 'Dodaj przycisk', 'en': 'Add button'},
    'addedButton': {'pl': 'Dodano przycisk', 'en': 'Added button'},

    // ==================== USTAWIENIA ====================
    'settings': {'pl': 'Opcje', 'en': 'Settings'},
    'appearance': {'pl': 'Wygląd', 'en': 'Appearance'},
    'theme': {'pl': 'Motyw', 'en': 'Theme'},
    'chooseTheme': {'pl': 'Wybierz motyw', 'en': 'Choose theme'},
    'themeLight': {'pl': 'Jasny', 'en': 'Light'},
    'themeDark': {'pl': 'Ciemny', 'en': 'Dark'},
    'themeOled': {'pl': 'OLED Dark', 'en': 'OLED Dark'},
    'themeOledSubtitle': {
      'pl': 'Całkowicie czarne tło',
      'en': 'Fully black background',
    },
    'language': {'pl': 'Język', 'en': 'Language'},
    'chooseLanguage': {'pl': 'Wybierz język', 'en': 'Choose language'},
    'languagePolish': {'pl': 'Polski', 'en': 'Polish'},
    'languageEnglish': {'pl': 'Angielski', 'en': 'English'},
    'day': {'pl': 'Dzień', 'en': 'Day'},
    'dayHours': {'pl': 'Godziny dnia', 'en': 'Day hours'},
    'dayStart': {'pl': 'Początek dnia', 'en': 'Day start'},
    'dayEnd': {'pl': 'Koniec dnia', 'en': 'Day end'},
    'save': {'pl': 'Zapisz', 'en': 'Save'},
    'counterReset': {'pl': 'Reset licznika', 'en': 'Counter reset'},
    'counterResetSubtitle': {'pl': 'Codziennie o', 'en': 'Every day at'},
    'counterResetAfter': {
      'pl': '(3h po końcu dnia)',
      'en': '(3h after day end)',
    },
    'dailyGoal': {'pl': 'Dzienny cel', 'en': 'Daily goal'},
    'dailyGoalQuestion': {
      'pl': 'Ile mililitrów wody chcesz wypijać dziennie?',
      'en': 'How many milliliters of water do you want to drink daily?',
    },
    'goalMl': {'pl': 'Cel (ml)', 'en': 'Goal (ml)'},
    'units': {'pl': 'Jednostki', 'en': 'Units'},
    'unitsMl': {'pl': 'Mililitry (ml)', 'en': 'Milliliters (ml)'},
    'unitsOz': {'pl': 'Uncje (oz)', 'en': 'Ounces (oz)'},
    'info': {'pl': 'Informacje', 'en': 'Information'},
    'aboutApp': {'pl': 'O aplikacji', 'en': 'About app'},
    'aboutAppDescription': {
      'pl': 'Prosta aplikacja do śledzenia ilości wypijanej wody.',
      'en': 'Simple app for tracking your water intake.',
    },

    // ==================== STATYSTYKI ====================
    'statsTitle': {'pl': 'Statystyki', 'en': 'Statistics'},
    'week': {'pl': 'Tydzień', 'en': 'Week'},
    'month': {'pl': 'Miesiąc', 'en': 'Month'},
    'last7Days': {'pl': 'Ostatnie 7 dni', 'en': 'Last 7 days'},
    'avgDaily': {'pl': 'Średnio dziennie', 'en': 'Daily average'},
    'goalReached': {'pl': 'Cel osiągnięty', 'en': 'Goal reached'},
    'details': {'pl': 'Szczegóły', 'en': 'Details'},
    'history': {'pl': 'Historia', 'en': 'History'},
    'today': {'pl': 'Dzisiaj', 'en': 'Today'},
    'goal': {'pl': 'Cel', 'en': 'Goal'},
    'goalReachedDays': {'pl': 'Cel osiągnięty:', 'en': 'Goal reached:'},
    'days': {'pl': 'dni', 'en': 'days'},
    'goalReachedLegend': {'pl': 'Cel osiągnięty', 'en': 'Goal reached'},
    'goalNotReachedLegend': {
      'pl': 'Cel nieosiągnięty',
      'en': 'Goal not reached',
    },

    // Dni tygodnia (skróty nagłówków kalendarza)
    'weekdayMon': {'pl': 'Pn', 'en': 'Mo'},
    'weekdayTue': {'pl': 'Wt', 'en': 'Tu'},
    'weekdayWed': {'pl': 'Śr', 'en': 'We'},
    'weekdayThu': {'pl': 'Cz', 'en': 'Th'},
    'weekdayFri': {'pl': 'Pt', 'en': 'Fr'},
    'weekdaySat': {'pl': 'Sb', 'en': 'Sa'},
    'weekdaySun': {'pl': 'Nd', 'en': 'Su'},

    // ==================== SERIA (STREAK) ====================
    'streak': {'pl': 'Seria', 'en': 'Streak'},
    'streakDays': {'pl': 'dni z rzędu!', 'en': 'days in a row!'},
    'streakDay': {'pl': 'dzień z rzędu!', 'en': 'day in a row!'},
    'streakRegular': {'pl': 'Pijesz regularnie', 'en': 'Drinking regularly'},
    'noStreak': {'pl': 'Zacznij swoją serię!', 'en': 'Start your streak!'},
    'bestStreak': {'pl': 'Najlepsza seria', 'en': 'Best streak'},

    // ==================== ROCZNE STATYSTYKI ====================
    'year': {'pl': 'Rok', 'en': 'Year'},
    'yearlyOverview': {'pl': 'Przegląd roczny', 'en': 'Yearly overview'},
    'less': {'pl': 'Mniej', 'en': 'Less'},
    'more': {'pl': 'Więcej', 'en': 'More'},
    'totalDaysTracked': {'pl': 'Dni z danymi', 'en': 'Days tracked'},
    'totalGoalDays': {'pl': 'Dni z celem', 'en': 'Goal days'},
    'yearlyAvg': {'pl': 'Średnia roczna', 'en': 'Yearly average'},

    // ==================== EKSPORT ====================
    'export': {'pl': 'Eksport', 'en': 'Export'},
    'exportData': {'pl': 'Eksportuj dane', 'en': 'Export data'},
    'exportCSV': {'pl': 'Eksport CSV', 'en': 'Export CSV'},
    'exportPDF': {'pl': 'Eksport PDF', 'en': 'Export PDF'},
    'exportCSVDesc': {
      'pl': 'Eksportuj historię picia do pliku CSV',
      'en': 'Export drinking history to CSV file',
    },
    'exportPDFDesc': {
      'pl': 'Eksportuj raport ze statystykami jako PDF',
      'en': 'Export statistics report as PDF',
    },
    'exportSuccess': {
      'pl': 'Dane wyeksportowane pomyślnie!',
      'en': 'Data exported successfully!',
    },
    'exportError': {'pl': 'Błąd eksportu', 'en': 'Export error'},
    'noDataToExport': {
      'pl': 'Brak danych do eksportu',
      'en': 'No data to export',
    },
    'date': {'pl': 'Data', 'en': 'Date'},
    'time': {'pl': 'Czas', 'en': 'Time'},
    'amount': {'pl': 'Ilość (ml)', 'en': 'Amount (ml)'},

    // ==================== TRENDY ====================
    'trends': {'pl': 'Trendy', 'en': 'Trends'},
    'weeklyAvgTrend': {'pl': 'Średnia tygodniowa', 'en': 'Weekly average'},
    'monthlyAvgTrend': {'pl': 'Średnia miesięczna', 'en': 'Monthly average'},
    'last8Weeks': {'pl': 'Ostatnie 8 tygodni', 'en': 'Last 8 weeks'},
    'last6Months': {'pl': 'Ostatnie 6 miesięcy', 'en': 'Last 6 months'},
    'avgPerDay': {'pl': 'Śr. dziennie', 'en': 'Avg per day'},
    'goalDays': {'pl': 'Dni z celem', 'en': 'Goal days'},
    'weekShort': {'pl': 'Tydz', 'en': 'Wk'},

    // ==================== POWIADOMIENIA ====================
    'notifications': {'pl': 'Powiadomienia', 'en': 'Notifications'},
    'notificationsEnabled': {
      'pl': 'Przypomnienia o piciu',
      'en': 'Drinking reminders',
    },
    'notificationsEnabledSubtitle': {
      'pl': 'Regularne przypomnienia o piciu wody',
      'en': 'Regular reminders to drink water',
    },
    'soundsEnabled': {'pl': 'Dźwięki aplikacji', 'en': 'App sounds'},
    'soundsEnabledSubtitle': {
      'pl': 'Krótki dźwięk po dodaniu wody',
      'en': 'Short sound after adding water',
    },
    'notificationTimes': {
      'pl': 'Godziny powiadomień',
      'en': 'Notification times',
    },
    'notificationTimesSubtitle': {
      'pl':
          'Wybierz konkretne godziny, o których chcesz dostawać przypomnienia',
      'en': 'Choose the exact times when you want reminders',
    },
    'notificationTimesEmpty': {
      'pl': 'Dodaj pierwszą godzinę przypomnienia',
      'en': 'Add your first reminder time',
    },
    'addNotificationTime': {'pl': 'Dodaj godzinę', 'en': 'Add time',
    },
  };

  String get(String key) {
    final entry = _translations[key];
    if (entry == null) return key;
    return entry[languageCode] ?? entry['pl'] ?? key;
  }

  /// Skrócony dostęp: t('key')
  String call(String key) => get(key);

  /// Locale string do DateFormat ('pl' lub 'en')
  String get dateLocale => languageCode == 'en' ? 'en_US' : 'pl';

  /// Lista obsługiwanych języków
  static const List<String> supportedLanguages = ['pl', 'en'];

  /// Nazwa języka w tym języku
  static String languageName(String code) {
    switch (code) {
      case 'pl':
        return 'Polski';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }
}
