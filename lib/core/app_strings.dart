class AppStrings {
  const AppStrings._();

  static const alertCategoryRockets = 'ירי רקטות וטילים';
  static const alertCategoryUav = 'חדירת כלי טיס עוין';
  static const alertCategoryClearance = 'האירוע הסתיים';
  static const alertCategoryImminent = 'התרעה צפויה';
  static const alertCategoryOther = 'התרעה';

  static const alertStateAllClear = 'אין התרעות';
  static const alertStateImminent = 'התרעה צפויה';
  static const alertStateRedAlert = 'צבע אדום';
  static const alertStateWaitingClear = 'המתינו במרחב המוגן';
  static const alertStateJustCleared = 'האירוע הסתיים';
  static const alertInstructionImminent = 'התרעות צפויות בדקות הקרובות';
  static const alertInstructionTakeShelter = 'היכנסו למרחב המוגן';
  static const alertInstructionWaitClear = 'ממתינים לאישור יציאה';
  static const alertInstructionCleared = 'ניתן לצאת מהמרחב המוגן';

  static const noConnection = 'אין חיבור';
  static const noInternetConnection = 'אין חיבור לאינטרנט';
  static const unknownStatus = 'מצב לא ידוע';
  static const cannotVerifyAlerts = 'לא ניתן לאמת התרעות כרגע';

  static const waitingForInternet = 'ממתין לחיבור לאינטרנט...';
  static const loading = 'טוען...';
  static const addLocationToSeeAlerts = 'הוסף מיקום כדי לראות התרעות';
  static const cannotShowAlertsNow = 'לא ניתן להציג התרעות כרגע';
  static const noAlertsInYourAreas = 'אין התרעות באזורים שלך';
  static const loadAlertsError = 'שגיאה בטעינת התרעות';
  static const historyUnavailable = 'היסטוריה לא זמינה';

  static const statusTab = 'מצב';
  static const newsTab = 'חדשות';
  static const newsTitle = 'מבזקי חדשות';
  static const loadNewsError = 'שגיאה בטעינת חדשות';
  static const noNewsItems = 'אין מבזקים חדשים';

  static const loadLocationsError = 'שגיאה בטעינת רשימת אזורים';
  static const loadingLocations = 'טוען רשימת אזורים...';
  static const tryAgainLater = 'נסו שוב מאוחר יותר';
  static const noResults = 'לא נמצאו תוצאות';
  static const addLocation = 'הוסף מיקום';
  static const addFirstLocation = 'הוסף מיקום ראשון';
  static const chooseArea = 'בחר אזור';
  static const chooseAreaRequired = 'יש לבחור אזור';
  static const duplicateLocation = 'מיקום זה כבר קיים ברשימה';
  static const saveLocationFailed = 'שמירת המיקום נכשלה';
  static const locationNotFound = 'המיקום לא נמצא';
  static const customLabelOptional = 'שם מותאם (לא חובה)';
  static const customLabelHint = 'בית, עבודה...';
  static const searchHint = 'חיפוש...';
  static const setAsPrimary = 'הגדר כמיקום ראשי';
  static const save = 'שמור';
  static const myLocations = 'המיקומים שלי';
  static const noSavedLocations = 'אין מיקומים שמורים';

  static const recentAlerts = 'התרעות אחרונות';
  static const showingLastHour = 'מציג שעה אחרונה';
  static const loadMore = 'טען עוד';
  static const refreshing = 'מתעדכן...';

  static const editLocation = 'ערוך מיקום';
  static const deleteLocation = 'מחק מיקום';
  static const cancel = 'ביטול';
  static const delete = 'מחק';
  static const customLabel = 'שם מותאם';
  static const area = 'אזור';
  static const primaryLocation = 'מיקום ראשי';

  static String deleteLocationPrompt(String label) => "למחוק את '$label'?";
  static String nationwideAlertSummary(int userCount, int nationwideCount) =>
      '$userCount באזורים שלך • $nationwideCount ברחבי הארץ';
}
