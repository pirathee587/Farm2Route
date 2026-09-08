import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  ta('TA', 'தமிழ்'),
  si('SI', 'සිංහල'),
  en('EN', 'English');

  final String code;
  final String label;

  const AppLanguage(this.code, this.label);
}

class FarmerLocalizations {
  final AppLanguage language;

  const FarmerLocalizations(this.language);

  // Landing / Welcome Screen
  String get welcomeTitle {
    switch (language) {
      case AppLanguage.ta:
        return 'Farm2Route இற்கு நல்வரவு';
      case AppLanguage.si:
        return 'Farm2Route වෙත සාදරයෙන් පිළිගනිමු';
      case AppLanguage.en:
        return 'Welcome to Farm2Route';
    }
  }

  String get welcomeSubtitle {
    switch (language) {
      case AppLanguage.ta:
        return 'உங்கள் அறுவடையை விரைவாக சந்தைக்கு கொண்டு செல்லுங்கள்.';
      case AppLanguage.si:
        return 'ඔබේ අස්වැන්න ඉක්මනින් වෙළඳපොළට ගෙන යන්න.';
      case AppLanguage.en:
        return 'Get your harvest to market, faster.';
    }
  }

  String get getStartedButton {
    switch (language) {
      case AppLanguage.ta:
        return 'தொடங்குங்கள்';
      case AppLanguage.si:
        return 'ආරම්භ කරන්න';
      case AppLanguage.en:
        return 'Get Started';
    }
  }

  String get alreadyHaveAccount {
    switch (language) {
      case AppLanguage.ta:
        return 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழைக';
      case AppLanguage.si:
        return 'දැනටමත් ගිණුමක් තිබේද? ඇතුල් වන්න';
      case AppLanguage.en:
        return 'I already have an account — Log in';
    }
  }

  String get selectLanguageTitle {
    switch (language) {
      case AppLanguage.ta:
        return 'மொழியைத் தேர்ந்தெடுக்கவும்';
      case AppLanguage.si:
        return 'භාෂාව තෝරන්න';
      case AppLanguage.en:
        return 'Select Language';
    }
  }

  // Farmer Login Screen
  String get farmerLoginTitle {
    switch (language) {
      case AppLanguage.ta:
        return 'விவசாயி உள்நுழைவு';
      case AppLanguage.si:
        return 'ගොවි පිවිසුම';
      case AppLanguage.en:
        return 'Farmer Log In';
    }
  }

  String get farmerLoginSubtitle {
    switch (language) {
      case AppLanguage.ta:
        return 'OTP மூலம் உடனடியாக உள்நுழைய உங்கள் தொலைபேசி எண்ணை உள்ளிடவும்.';
      case AppLanguage.si:
        return 'OTP මඟින් ක්ෂණිකව ඇතුල් වීමට ඔබේ දුරකථන අංකය ඇතුළත් කරන්න.';
      case AppLanguage.en:
        return 'Enter your mobile number to log in securely with OTP.';
    }
  }

  String get verifyAndLoginButton {
    switch (language) {
      case AppLanguage.ta:
        return 'உறுதிப்படுத்தி உள்நுழைக';
      case AppLanguage.si:
        return 'තහවුරු කර ඇතුල් වන්න';
      case AppLanguage.en:
        return 'Verify & Log In';
    }
  }

  // Phone Entry Screen
  String get farmerSignupTitle {
    switch (language) {
      case AppLanguage.ta:
        return 'விவசாயி பதிவு';
      case AppLanguage.si:
        return 'ගොවි ලියාපදිංචිය';
      case AppLanguage.en:
        return 'Farmer Sign Up';
    }
  }

  String get phoneEntrySubtitle {
    switch (language) {
      case AppLanguage.ta:
        return 'ஒருமுறை கடவுச்சொல்லை (OTP) பெற உங்கள் தொலைபேசி எண்ணை உள்ளிடவும்.';
      case AppLanguage.si:
        return 'තහවුරු කිරීමේ කේතය (OTP) ලබා ගැනීම සඳහා ඔබේ ජංගම දුරකථන අංකය ඇතුළත් කරන්න.';
      case AppLanguage.en:
        return 'Enter your mobile number to receive a one-time verification code.';
    }
  }

  String get mobileNumberLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'தொலைபேசி எண்';
      case AppLanguage.si:
        return 'ජංගම දුරකථන අංකය';
      case AppLanguage.en:
        return 'Mobile Number';
    }
  }

  String get sendOtpButton {
    switch (language) {
      case AppLanguage.ta:
        return 'OTP அனுப்புக';
      case AppLanguage.si:
        return 'OTP කේතය එවන්න';
      case AppLanguage.en:
        return 'Send OTP';
    }
  }

  String get phoneRequiredError {
    switch (language) {
      case AppLanguage.ta:
        return 'தொலைபேசி எண் தேவை';
      case AppLanguage.si:
        return 'දුරකථන අංකය ඇතුළත් කරන්න';
      case AppLanguage.en:
        return 'Mobile number is required';
    }
  }

  String get phoneInvalidError {
    switch (language) {
      case AppLanguage.ta:
        return 'சரியான 9 இலக்க இலங்கை தொலைபேசி எண்ணை உள்ளிடவும் (எ.கா. 771234567)';
      case AppLanguage.si:
        return 'වලංගු ශ්‍රී ලංකා ජංගම දුරකථන අංකයක් ඇතුළත් කරන්න (උදා. 771234567)';
      case AppLanguage.en:
        return 'Enter a valid 9-digit Sri Lankan mobile number (e.g. 771234567)';
    }
  }

  // OTP Verification Screen
  String get verifyPhoneTitle {
    switch (language) {
      case AppLanguage.ta:
        return 'தொலைபேசியை உறுதிப்படுத்துக';
      case AppLanguage.si:
        return 'දුරකථන අංකය තහවුරු කරන්න';
      case AppLanguage.en:
        return 'Verify Phone';
    }
  }

  String get otpSubtitle {
    switch (language) {
      case AppLanguage.ta:
        return 'அனுப்பப்பட்ட 6 இலக்க OTP குறியீட்டை உள்ளிடவும்:';
      case AppLanguage.si:
        return 'වෙත එවන ලද ඉලක්කම් 6 කේතය ඇතුළත් කරන්න:';
      case AppLanguage.en:
        return 'Enter the 6-digit code sent to:';
    }
  }

  String get otpRequiredError {
    switch (language) {
      case AppLanguage.ta:
        return '6 இலக்க OTP குறியீட்டை உள்ளிடவும்';
      case AppLanguage.si:
        return 'ඉලක්කම් 6ක OTP කේතය ඇතුළත් කරන්න';
      case AppLanguage.en:
        return 'Please enter the 6-digit OTP';
    }
  }

  String get resendInText {
    switch (language) {
      case AppLanguage.ta:
        return 'மீண்டும் அனுப்ப விநாடிகள்:';
      case AppLanguage.si:
        return 'නැවත යැවීම තත්පර:';
      case AppLanguage.en:
        return 'Resend code in';
    }
  }

  String get resendOtpButton {
    switch (language) {
      case AppLanguage.ta:
        return 'OTP ஐ மீண்டும் அனுப்புக';
      case AppLanguage.si:
        return 'OTP නැවත එවන්න';
      case AppLanguage.en:
        return 'Resend OTP';
    }
  }

  String get verifyAndContinueButton {
    switch (language) {
      case AppLanguage.ta:
        return 'உறுதிப்படுத்தி தொடரவும்';
      case AppLanguage.si:
        return 'තහවුරු කර ඉදිරියට යන්න';
      case AppLanguage.en:
        return 'Verify & Continue';
    }
  }

  // Details Screen
  String get farmerDetailsTitle {
    switch (language) {
      case AppLanguage.ta:
        return 'விவசாயி விபரங்கள்';
      case AppLanguage.si:
        return 'ගොවි තොරතුරු';
      case AppLanguage.en:
        return 'Farmer Details';
    }
  }

  String get farmerDetailsSubtitle {
    switch (language) {
      case AppLanguage.ta:
        return 'விவசாய விபரங்களை பூர்த்தி செய்து பதிவை நிறைவு செய்க';
      case AppLanguage.si:
        return 'ලියාපදිංචිය සම්පූර්ණ කිරීම සඳහා ගොවිපල තොරතුරු ඇතුළත් කරන්න';
      case AppLanguage.en:
        return 'Fill in your farm details to complete registration';
    }
  }

  String get fullNameLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'முழுப் பெயர் *';
      case AppLanguage.si:
        return 'සම්පූර්ණ නම *';
      case AppLanguage.en:
        return 'Full Name *';
    }
  }

  String get fullNameRequiredError {
    switch (language) {
      case AppLanguage.ta:
        return 'முழுப் பெயர் தேவை';
      case AppLanguage.si:
        return 'සම්පූර්ණ නම ඇතුළත් කරන්න';
      case AppLanguage.en:
        return 'Full name is required';
    }
  }

  String get emailLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'மின்னஞ்சல் (விருப்பத்தேர்வு)';
      case AppLanguage.si:
        return 'විද්‍යුත් තැපෑල (අත්‍යවශ්‍ය නොවේ)';
      case AppLanguage.en:
        return 'Email (Optional)';
    }
  }

  String get districtLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'மாவட்டம் *';
      case AppLanguage.si:
        return 'දිස්ත්‍රික්කය *';
      case AppLanguage.en:
        return 'District *';
    }
  }

  String get districtRequiredError {
    switch (language) {
      case AppLanguage.ta:
        return 'தயவுசெய்து மாவட்டத்தைத் தேர்ந்தெடுக்கவும்';
      case AppLanguage.si:
        return 'කරුණාකර ඔබේ දිස්ත්‍රික්කය තෝරන්න';
      case AppLanguage.en:
        return 'Please select your district';
    }
  }

  String get gnDivisionLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'கிராம அலுவலர் பிரிவு (விருப்பத்தேர்வு)';
      case AppLanguage.si:
        return 'ග්‍රාම නිලධාරී වසම (අත්‍යවශ්‍ය නොවේ)';
      case AppLanguage.en:
        return 'GN Division (Optional)';
    }
  }

  String get farmLocationTitle {
    switch (language) {
      case AppLanguage.ta:
        return 'பண்ணை அமைவிடம் (வரைபடம்)';
      case AppLanguage.si:
        return 'ගොවිපල පිහිටීම (සිතියම)';
      case AppLanguage.en:
        return 'Farm Location (Map Picker)';
    }
  }

  String get farmLocationSubtitle {
    switch (language) {
      case AppLanguage.ta:
        return 'ஏற்றுமதி செய்யும் சரியான இடத்தை வரைபடத்தில் குறிக்கவும்';
      case AppLanguage.si:
        return 'පැටවීමේ ස්ථානය සිතියමෙන් ලකුණු කරන්න';
      case AppLanguage.en:
        return 'Pinpoint your farm harvest pickup location';
    }
  }

  String get useCurrentLocationButton {
    switch (language) {
      case AppLanguage.ta:
        return 'எனது தற்போதைய இடத்தை உபயோகிக்க';
      case AppLanguage.si:
        return 'මගේ වත්මන් ස්ථානය භාවිතා කරන්න';
      case AppLanguage.en:
        return 'Use My Current Location';
    }
  }

  String get farmSizeLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'பண்ணை அளவு (ஏக்கர் - விருப்பத்தேர்வு)';
      case AppLanguage.si:
        return 'ගොවිපල ප්‍රමාණය (අක්කර - අත්‍යවශ්‍ය නොවේ)';
      case AppLanguage.en:
        return 'Farm Size in Acres (Optional)';
    }
  }

  String get primaryCropsLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'முதன்மை பயிர்கள் (ஒன்றைத் தேர்ந்தெடுக்கவும்)';
      case AppLanguage.si:
        return 'ප්‍රධාන භෝග (අවම වශයෙන් එකක් තෝරන්න)';
      case AppLanguage.en:
        return 'Primary Crops (Select all that apply)';
    }
  }

  String get preferredLanguageLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'விருப்பமான மொழி';
      case AppLanguage.si:
        return 'කැමති භාෂාව';
      case AppLanguage.en:
        return 'Preferred Language';
    }
  }

  String get bankAccountLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'வங்கி கணக்கு எண் (விருப்பத்தேர்வு)';
      case AppLanguage.si:
        return 'බැංකු ගිණුම් අංකය (අත්‍යවශ්‍ය නොවේ)';
      case AppLanguage.en:
        return 'Bank Account Number (Optional)';
    }
  }

  String get mobileWalletLabel {
    switch (language) {
      case AppLanguage.ta:
        return 'மொபைல் பணப்பை எண் (eZ Cash / mCash)';
      case AppLanguage.si:
        return 'ජංගම පසුම්බි අංකය (eZ Cash / mCash)';
      case AppLanguage.en:
        return 'Mobile Wallet Number (e.g. eZ Cash)';
    }
  }

  String get completeSignupButton {
    switch (language) {
      case AppLanguage.ta:
        return 'பதிவை நிறைவு செய்க';
      case AppLanguage.si:
        return 'ලියාපදිංචිය අවසන් කරන්න';
      case AppLanguage.en:
        return 'Complete Signup';
    }
  }

  String cropLabel(String cropCode) {
    switch (cropCode) {
      case 'VEGETABLES':
        switch (language) {
          case AppLanguage.ta:
            return 'காய்கறிகள்';
          case AppLanguage.si:
            return 'එළවළු';
          case AppLanguage.en:
            return 'Vegetables';
        }
      case 'FRUITS':
        switch (language) {
          case AppLanguage.ta:
            return 'பழங்கள்';
          case AppLanguage.si:
            return 'පළතුරු';
          case AppLanguage.en:
            return 'Fruits';
        }
      case 'GRAINS':
        switch (language) {
          case AppLanguage.ta:
            return 'தானியங்கள் / நெல்';
          case AppLanguage.si:
            return 'ධාන්‍ය / වී';
          case AppLanguage.en:
            return 'Grains';
        }
      case 'DAIRY':
        switch (language) {
          case AppLanguage.ta:
            return 'பால் பண்ணை';
          case AppLanguage.si:
            return 'කිරි නිෂ්පාදන';
          case AppLanguage.en:
            return 'Dairy';
        }
      case 'OTHER':
      default:
        switch (language) {
          case AppLanguage.ta:
            return 'மற்றவை';
          case AppLanguage.si:
            return 'වෙනත්';
          case AppLanguage.en:
            return 'Other';
        }
    }
  }
}

final farmerLanguageProvider = StateNotifierProvider<FarmerLanguageNotifier, AppLanguage>((ref) {
  return FarmerLanguageNotifier();
});

class FarmerLanguageNotifier extends StateNotifier<AppLanguage> {
  FarmerLanguageNotifier() : super(AppLanguage.ta); // Default Tamil per requirements

  void setLanguage(AppLanguage lang) {
    state = lang;
  }

  void setLanguageByCode(String code) {
    switch (code.toUpperCase()) {
      case 'SI':
        state = AppLanguage.si;
        break;
      case 'EN':
        state = AppLanguage.en;
        break;
      case 'TA':
      default:
        state = AppLanguage.ta;
        break;
    }
  }
}

final farmerLocalizationsProvider = Provider<FarmerLocalizations>((ref) {
  final lang = ref.watch(farmerLanguageProvider);
  return FarmerLocalizations(lang);
});
