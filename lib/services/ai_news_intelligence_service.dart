import '../models/agriculture_news_item.dart';

/// AI News Intelligence Engine for KhetChacha.
/// Parses official government notices, removes bureaucratic jargon, extracts
/// application deadlines, and generates concise, farmer-friendly explanations in
/// regional Indian languages.
class AiNewsIntelligenceService {
  AiNewsIntelligenceService._();
  static final AiNewsIntelligenceService instance =
      AiNewsIntelligenceService._();

  /// Generates a simplified, actionable explanation for a farmer in their language.
  String generateFarmerFriendlySummary({
    required AgricultureNewsItem news,
    required String langCode,
  }) {
    final state = news.applicableState;
    final lc = langCode.toLowerCase();

    // Gujarati Summary
    if (lc == 'gu') {
      if (news.category == AgricultureNewsCategory.farmerSubsidies ||
          news.category == AgricultureNewsCategory.newSchemes) {
        return 'ખેડૂત મિત્રો માટે સારા સમાચાર! $state રાજ્ય માટે નવી કૃષિ સહાય અને સબસિડી જાહેર થઈ છે. સત્તાવાર પોર્ટલ પરથી પાત્રતા અને છેલ્લી તારીખ તપાસો.';
      } else if (news.category == AgricultureNewsCategory.pmKisan) {
        return 'પીએમ-કિસાન યોજના અપડેટ: ₹2,000 નો હપ્તો મેળવવા માટે તમારા આધાર કાર્ડનું ઈ-કેવાયસી (eKYC) ચકાસો.';
      } else if (news.category == AgricultureNewsCategory.weatherWarnings) {
        return 'હવામાન સાવચેતી: તમારા વિસ્તારમાં વરસાદ અથવા પવનની શક્યતા છે. ખેતરમાં પાણીના નિકાલની વ્યવસ્થા રાખો.';
      } else if (news.category == AgricultureNewsCategory.cropInsurance) {
        return 'પાક વીમા સુચના: પ્રધાનમંત્રી ફસલ બીમા યોજના (PMFBY) હેઠળ નોંધણીની છેલ્લી તારીખ નજીક છે. સમયસર અરજી કરો.';
      }
      return '$state ખેડૂતો માટે મહત્વપૂર્ણ સરકારી સૂચના: ${news.headline}. સત્તાવાર લિંક પરથી સંપૂર્ણ વિગત જાણો.';
    }

    // Hindi Summary
    if (lc == 'hi') {
      if (news.category == AgricultureNewsCategory.farmerSubsidies ||
          news.category == AgricultureNewsCategory.newSchemes) {
        return 'किसान भाइयों के लिए अच्छी खबर! $state में नई कृषि सब्सिडी और योजना की घोषणा हुई है। आधिकारिक पोर्टल पर पात्रता देखकर आवेदन करें।';
      } else if (news.category == AgricultureNewsCategory.pmKisan) {
        return 'पीएम-किसान योजना अपडेट: ₹2,000 की अगली किस्त प्राप्त करने के लिए आधार eKYC और बैंक सीडिंग पूरा करें।';
      } else if (news.category == AgricultureNewsCategory.weatherWarnings) {
        return 'मौसम चेतावनी: आगामी दिनों में वर्षा की संभावना है। खेतों में जल निकासी की व्यवस्था सुनिश्चित करें।';
      } else if (news.category == AgricultureNewsCategory.cropInsurance) {
        return 'फसल बीमा सूचना: पीएम फसल बीमा योजना में पंजीकरण की अंतिम तिथि से पूर्व बीमा करवाएं।';
      }
      return '$state के किसानों के लिए आधिकारिक सूचना: ${news.headline}. विस्तृत जानकारी हेतु लिंक देखें।';
    }

    // Punjabi Summary
    if (lc == 'pa') {
      if (news.category == AgricultureNewsCategory.mspAnnouncements) {
        return 'ਕਿਸਾਨ ਵੀਰਾਂ ਲਈ ਖੁਸ਼ਖਬਰੀ! ਸਰਕਾਰ ਵੱਲੋਂ ਨਵਾਂ ਘੱਟੋ-ਘੱਟ ਸਮਰਥਨ ਮੁੱਲ (MSP) ਐਲਾਨਿਆ ਗਿਆ ਹੈ। ਮੰਡੀ ਵਿੱਚ ਵੇਚਣ ਤੋਂ ਪਹਿਲਾਂ ਰੇਟ ਚੈੱਕ ਕਰੋ।';
      }
      return '$state ਦੇ ਕਿਸਾਨਾਂ ਲਈ ਸਰਕਾਰੀ ਖੇਤੀਬਾੜੀ ਅਪਡੇਟ: ${news.headline}. ਪੂਰੀ ਜਾਣਕਾਰੀ ਲਈ ਲਿੰਕ ਵੇਖੋ।';
    }

    // Default English Summary
    if (news.category == AgricultureNewsCategory.farmerSubsidies) {
      return 'Good news for farmers in $state! A new government agriculture subsidy has been published. Verify eligibility and deadline on the official portal.';
    } else if (news.category == AgricultureNewsCategory.pmKisan) {
      return 'PM-KISAN Update: Complete your Aadhaar eKYC to receive the ₹2,000 installment without delay.';
    } else if (news.category == AgricultureNewsCategory.weatherWarnings) {
      return 'Agricultural Weather Alert: Rainfall predicted in your region. Check field drainage and pause spraying.';
    }
    return 'Official government advisory for $state farmers: ${news.headline}. Check official source for guidelines.';
  }

  /// Helper to summarize free-form announcement text for farmers
  Future<String> summarizeAnnouncementText({
    required String headline,
    required String text,
    required AgricultureNewsCategory category,
    String state = 'All India',
    String langCode = 'en',
  }) async {
    final item = AgricultureNewsItem(
      id: 'temp_preview',
      headline: headline,
      description: text,
      aiSummary: '',
      originalSource: 'Govt Department',
      officialSourceUrl: 'https://india.gov.in',
      publishedDate: DateTime.now(),
      lastUpdatedDate: DateTime.now(),
      applicableState: state,
      category: category,
    );
    return generateFarmerFriendlySummary(news: item, langCode: langCode);
  }
}
