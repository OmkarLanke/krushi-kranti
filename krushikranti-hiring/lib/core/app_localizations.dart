import 'package:flutter/material.dart';

// GLOBAL NOTIFIER to handle language state across the app
final ValueNotifier<String> currentLanguage = ValueNotifier<String>('mr'); // Default Marathi

class AppStrings {
  // HELPER: Get string based on current language
  static String tr(String key) {
    return _localizedValues[currentLanguage.value]?[key] ?? key;
  }

  // DICTIONARY
  static const Map<String, Map<String, String>> _localizedValues = {
    // --- ENGLISH ---
    'en': {
      'brand_name': 'Krushi Kranti',
      'continue_as': 'Continue as',
      'role_desc': 'Choose a role to apply as a Krushi Tadnya, Field Officer, or Shopkeeper',
      
      // Roles
      'role_field_officer': 'FIELD OFFICER',
      'role_officer_desc': 'Manage field operations and assist farmers directly.',
      'role_tadnya': 'KRUSHI TADNYA',
      'role_tadnya_desc': 'Share your agricultural expertise and guide others.',
      'role_shopkeeper': 'SHOPKEEPER',
      'role_shopkeeper_desc': 'Register your shop to sell authentic products.',

      // Personal Details
      'personal_detail_title': 'Personal Detail',
      'enter_full_name': 'Enter Full Name',
      'enter_mobile': 'Enter Mobile No',
      'dob': 'Date Of Birth',
      'enter_aadhaar': 'Enter Aadhaar No',
      'terms_agree': 'I have read and agree with the Terms and Conditions and Privacy Policy.',
      'next': 'Next',
      'required': 'Required',
      'digits_only': 'Please enter digits only',
      'invalid_mobile': 'Must be exactly 10 digits',
      'invalid_aadhaar': 'Must be exactly 12 digits',
      'alphabets_only': 'Please enter alphabets only',

      // Qualifications / Forms
      'enter_qualification': 'Enter Qualification',
      'highest_qual': 'Highest Qualification',
      'agri_spec': 'Agriculture Specialization',
      'years_exp': 'Years of Experience',
      'pref_area': 'Preferred Work Area',
      'field_visit': 'Willing for Field Visit',
      'yes': 'Yes',
      'no': 'No',
      'upload_resume': '+ Upload Resume (PDF/Doc)',
      'submit_form': 'Submit Form',
      
      // Shopkeeper Specific
      'shop_name': 'Shop Name',
      'shop_address': 'Shop Address',
      'gst_number': 'GST Number',
      'years_business': 'Years in Business',
      'shop_type': 'Shop Type',
      'upload_shop_photo': '+ Upload Shop Photo',
      'retail': 'Retail',
      'wholesale': 'Wholesale',
      'distributor': 'Distributor',

      // Success
      'success': 'Success',
      'success_msg': 'Your Form has successfully Submitted',
      'ok': 'OK',

      'vehicle_avail': 'Vehicle Availability',
      'district_pref': 'Assigned District Preference',

      'apply_title': 'Apply for Agriculture Careers',
      'apply_subtitle': 'Fill the form to work as a Krushi Tadnya, Field Officer, or Shopkeeper',
    },

    // --- MARATHI (DEFAULT) ---
    'mr': {
      'brand_name': 'कृषी क्रांती',
      'continue_as': 'पुढे जा',
      'role_desc': 'कृषी तज्ञ, क्षेत्र अधिकारी किंवा दुकानदार म्हणून अर्ज करण्यासाठी भूमिका निवडा',
      
      'role_field_officer': 'क्षेत्र अधिकारी',
      'role_officer_desc': 'क्षेत्रीय कामे व्यवस्थापित करा आणि शेतकऱ्यांना थेट मदत करा.',
      'role_tadnya': 'कृषी तज्ञ',
      'role_tadnya_desc': 'तुमचे कृषी ज्ञान शेअर करा आणि इतरांना मार्गदर्शन करा.',
      'role_shopkeeper': 'दुकानदार',
      'role_shopkeeper_desc': 'अधिकृत उत्पादने विकण्यासाठी तुमच्या दुकानाची नोंदणी करा.',

      'personal_detail_title': 'वैयक्तिक माहिती',
      'enter_full_name': 'पूर्ण नाव प्रविष्ट करा',
      'enter_mobile': 'मोबाईल नंबर प्रविष्ट करा',
      'dob': 'जन्म तारीख',
      'enter_aadhaar': 'आधार क्रमांक प्रविष्ट करा',
      'terms_agree': 'मी अटी व शर्ती आणि गोपनीयता धोरण वाचले आहे आणि सहमत आहे.',
      'next': 'पुढे',
      'required': 'आवश्यक',
      'digits_only': 'फक्त अंक प्रविष्ट करा',
      'invalid_mobile': 'नेमके १० अंक असावेत',
      'invalid_aadhaar': 'नेमके १२ अंक असावेत',
      'alphabets_only': 'फक्त अक्षरे प्रविष्ट करा',

      'enter_qualification': 'पात्रता प्रविष्ट करा',
      'highest_qual': 'उच्चतम शिक्षण',
      'agri_spec': 'कृषी विशेषीकरण',
      'years_exp': 'अनुभव (वर्षे)',
      'pref_area': 'पसंतीचे कामाचे क्षेत्र',
      'field_visit': 'क्षेत्र भेटीसाठी तयार?',
      'yes': 'होय',
      'no': 'नाही',
      'upload_resume': '+ बायोडाटा अपलोड करा (PDF/Doc)',
      'submit_form': 'फॉर्म जमा करा',

      'shop_name': 'दुकानाचे नाव',
      'shop_address': 'दुकानाचा पत्ता',
      'gst_number': 'जीएसटी क्रमांक',
      'years_business': 'व्यवसायातील वर्षे',
      'shop_type': 'दुकानाचा प्रकार',
      'upload_shop_photo': '+ दुकानाचा फोटो अपलोड करा',
      'retail': 'किरकोळ',
      'wholesale': 'घाऊक',
      'distributor': 'वितरक',

      'success': 'यशस्वी',
      'success_msg': 'तूमचा फॉर्म यशस्वीरित्या जमा झाला आहे',
      'ok': 'ठीक आहे',

      'vehicle_avail': 'वाहन उपलब्धता',
      'district_pref': 'नेमून दिलेला जिल्हा',

      'apply_title': 'कृषी करिअरसाठी अर्ज करा',
      'apply_subtitle': 'कृषी तज्ञ, क्षेत्र अधिकारी किंवा दुकानदार म्हणून काम करण्यासाठी फॉर्म भरा',
    },

    // --- HINDI ---
    'hi': {
      'brand_name': 'कृषि क्रांति',
      'continue_as': 'आगे बढ़ें',
      'role_desc': 'कृषि विशेषज्ञ, फील्ड ऑफिसर या दुकानदार के रूप में आवेदन करने के लिए भूमिका चुनें',
      
      'role_field_officer': 'फील्ड ऑफिसर',
      'role_officer_desc': 'फील्ड कार्यों का प्रबंधन करें और किसानों की सीधे सहायता करें।',
      'role_tadnya': 'कृषि विशेषज्ञ',
      'role_tadnya_desc': 'अपनी कृषि विशेषज्ञता साझा करें और दूसरों का मार्गदर्शन करें।',
      'role_shopkeeper': 'दुकानदार',
      'role_shopkeeper_desc': 'प्रामाणिक उत्पाद बेचने के लिए अपनी दुकान पंजीकृत करें।',

      'personal_detail_title': 'व्यक्तिगत विवरण',
      'enter_full_name': 'पूरा नाम दर्ज करें',
      'enter_mobile': 'मोबाइल नंबर दर्ज करें',
      'dob': 'जन्म तिथि',
      'enter_aadhaar': 'आधार नंबर दर्ज करें',
      'terms_agree': 'मैंने नियम और शर्तें और गोपनीयता नीति पढ़ ली है और सहमत हूं।',
      'next': 'अगला',
      'required': 'आवश्यक',
      'digits_only': 'केवल अंक दर्ज करें',
      'invalid_mobile': 'ठीक 10 अंक होने चाहिए',
      'invalid_aadhaar': 'ठीक 12 अंक होने चाहिए',
      'alphabets_only': 'केवल अक्षर दर्ज करें',

      'enter_qualification': 'योग्यता दर्ज करें',
      'highest_qual': 'उच्चतम योग्यता',
      'agri_spec': 'कृषि विशेषज्ञता',
      'years_exp': 'अनुभव (वर्ष)',
      'pref_area': 'पसंदीदा कार्य क्षेत्र',
      'field_visit': 'फील्ड विजिट के लिए तैयार?',
      'yes': 'हाँ',
      'no': 'नहीं',
      'upload_resume': '+ बायोडाटा अपलोड करें (PDF/Doc)',
      'submit_form': 'फॉर्म जमा करें',

      'shop_name': 'दुकान का नाम',
      'shop_address': 'दुकान का पता',
      'gst_number': 'जीएसटी नंबर',
      'years_business': 'व्यवसाय में वर्ष',
      'shop_type': 'दुकान का प्रकार',
      'upload_shop_photo': '+ दुकान का फोटो अपलोड करें',
      'retail': 'खुदरा',
      'wholesale': 'थोक',
      'distributor': 'वितरक',

      'success': 'सफल',
      'success_msg': 'आपका फॉर्म सफलतापूर्वक जमा हो गया है',
      'ok': 'ठीक है',

      'vehicle_avail': 'वाहन उपलब्धता',
      'district_pref': 'आवंटित जिला प्राथमिकता',

      'apply_title': 'कृषि करियर के लिए आवेदन करें',
      'apply_subtitle': 'कृषि विशेषज्ञ, फील्ड ऑफिसर या दुकानदार के रूप में काम करने के लिए फॉर्म भरें',
    },
  };
}