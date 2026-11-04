import 'package:flutter/material.dart';

import '../../models/agriculture_news_item.dart';
import '../../models/farmer_profile.dart';
import '../../services/agriculture_news_service.dart';
import '../../services/language_service.dart';
import '../notifications/notification_settings_page.dart';

/// Government Agriculture News, Farmer Alerts, and Subsidies Directory.
class GovernmentNewsDirectoryPage extends StatefulWidget {
  final FarmerProfile profile;
  final AgricultureNewsCategory? initialCategory;

  const GovernmentNewsDirectoryPage({
    super.key,
    required this.profile,
    this.initialCategory,
  });

  @override
  State<GovernmentNewsDirectoryPage> createState() =>
      _GovernmentNewsDirectoryPageState();
}

class _GovernmentNewsDirectoryPageState
    extends State<GovernmentNewsDirectoryPage> {
  late FarmerProfile _profile;
  List<AgricultureNewsItem> _newsList = [];
  bool _isLoading = true;
  AgricultureNewsCategory? _selectedCategory;
  bool _onlyBookmarked = false;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _states = [
    'All India',
    'Gujarat',
    'Punjab',
    'Maharashtra',
    'Madhya Pradesh',
    'Rajasthan',
    'Uttar Pradesh',
    'Haryana',
    'Karnataka',
    'Tamil Nadu',
    'Andhra Pradesh',
    'West Bengal',
    'Bihar',
  ];
  late String _filterState;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _selectedCategory = widget.initialCategory;
    _filterState = _profile.effectiveState.isNotEmpty
        ? _profile.effectiveState
        : 'All India';
    _fetchNews();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    setState(() => _isLoading = true);

    final effectiveProfile = _profile.copyWith(
      state: _filterState == 'All India' ? '' : _filterState,
      selectedState: _filterState == 'All India' ? '' : _filterState,
    );

    final results = await AgricultureNewsService.instance.getNewsForFarmer(
      effectiveProfile,
      categoryFilter: _selectedCategory,
      searchQuery: _searchCtrl.text,
      onlyBookmarked: _onlyBookmarked,
    );

    if (mounted) {
      setState(() {
        _newsList = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark(AgricultureNewsItem item) async {
    final newState = await AgricultureNewsService.instance.toggleBookmark(
      _profile.mobileNumber,
      item.id,
    );
    setState(() {
      final index = _newsList.indexWhere((n) => n.id == item.id);
      if (index != -1) {
        _newsList[index] = item.copyWith(isBookmarked: newState);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? 'Added to Saved News' : 'Removed from Saved News',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _openNewsDetail(AgricultureNewsItem item, String langCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(item.iconEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.category.getLocalizedName(langCode),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.originalSource,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      item.isBookmarked
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_border_rounded,
                      color: const Color(0xFF1B5E20),
                    ),
                    onPressed: () {
                      _toggleBookmark(item);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item.getLocalizedHeadline(langCode),
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // AI Summary Pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFAED581)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            langCode == 'gu'
                                ? 'AI ખેડૂત-મિત્ર સારાંશ'
                                : (langCode == 'hi'
                                      ? 'AI किसान-मित्र सारांश'
                                      : 'AI Farmer-Friendly Summary'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.getLocalizedSummary(langCode),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    item.getLocalizedDescription(langCode),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${langCode == 'gu' ? 'સ્ત્રોત' : (langCode == 'hi' ? 'स्रोत' : 'Source')}: ${item.officialSourceUrl}',
                            ),
                            backgroundColor: const Color(0xFF1B5E20),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                      label: Text(
                        langCode == 'gu'
                            ? 'સત્તાવાર પોર્ટલ'
                            : (langCode == 'hi'
                                  ? 'आधिकारिक पोर्टल'
                                  : 'Official Portal'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        langCode == 'gu'
                            ? 'બંધ કરો'
                            : (langCode == 'hi' ? 'बंद करें' : 'Close'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode =
        LanguageService.instance.currentLanguage.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          langCode == 'gu'
              ? 'કૃષિ સમાચાર અને યોજનાઓ'
              : (langCode == 'hi'
                    ? 'सरकारी कृषि समाचार एवं अलर्ट'
                    : 'Govt Agriculture News & Alerts'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _onlyBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: const Color(0xFFFFD54F),
            ),
            tooltip: 'Saved News',
            onPressed: () {
              setState(() => _onlyBookmarked = !_onlyBookmarked);
              _fetchNews();
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Notification Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationSettingsPage(profile: _profile),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & State Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: langCode == 'gu'
                        ? 'યોજનાઓ, સબસિડી, MSP, હવામાન શોધો...'
                        : (langCode == 'hi'
                              ? 'योजनाएं, सब्सिडी, एमएसपी, मौसम खोजें...'
                              : 'Search schemes, subsidies, MSP, weather...'),
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1B5E20),
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _fetchNews();
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _fetchNews(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      langCode == 'gu'
                          ? 'રાજ્ય: '
                          : (langCode == 'hi' ? 'राज्य: ' : 'State: '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _states.contains(_filterState)
                          ? _filterState
                          : 'All India',
                      isDense: true,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                      items: _states
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _filterState = val);
                          _fetchNews();
                        }
                      },
                    ),
                    const Spacer(),
                    if (_onlyBookmarked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          langCode == 'gu'
                              ? 'સાચવેલ દર્શાવો છો'
                              : (langCode == 'hi'
                                    ? 'सहेजे गए'
                                    : 'Showing Saved'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Horizontal Category Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(
                    null,
                    langCode == 'gu'
                        ? 'બધા સમાચાર'
                        : (langCode == 'hi' ? 'सभी समाचार' : 'All News'),
                  ),
                  _buildCategoryChip(
                    AgricultureNewsCategory.farmerSubsidies,
                    langCode == 'gu'
                        ? 'સબસિડી'
                        : (langCode == 'hi' ? 'सब्सिडी' : 'Subsidies'),
                  ),
                  _buildCategoryChip(
                    AgricultureNewsCategory.pmKisan,
                    'PM-KISAN',
                  ),
                  _buildCategoryChip(
                    AgricultureNewsCategory.newSchemes,
                    langCode == 'gu'
                        ? 'નવી યોજનાઓ'
                        : (langCode == 'hi' ? 'नई योजनाएं' : 'New Schemes'),
                  ),
                  _buildCategoryChip(
                    AgricultureNewsCategory.cropInsurance,
                    langCode == 'gu'
                        ? 'પાક વીમો'
                        : (langCode == 'hi' ? 'फसल बीमा' : 'Crop Insurance'),
                  ),
                  _buildCategoryChip(
                    AgricultureNewsCategory.mspAnnouncements,
                    langCode == 'gu'
                        ? 'ટેકાના ભાવ (MSP)'
                        : (langCode == 'hi' ? 'एमएसपी (MSP)' : 'MSP Updates'),
                  ),
                  _buildCategoryChip(
                    AgricultureNewsCategory.weatherWarnings,
                    langCode == 'gu'
                        ? 'હવામાન ચેતવણી'
                        : (langCode == 'hi' ? 'मौसम चेतावनी' : 'Weather'),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // 3. News Feed
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  )
                : _newsList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.newspaper_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _onlyBookmarked
                              ? (langCode == 'gu'
                                    ? 'કોઈ સાચવેલ સમાચાર નથી.'
                                    : (langCode == 'hi'
                                          ? 'कोई सहेजा गया समाचार नहीं है।'
                                          : 'No saved news items yet.'))
                              : (langCode == 'gu'
                                    ? 'પસંદ કરેલા ફિલ્ટર માટે કોઈ સમાચાર મળ્યા નથી.'
                                    : (langCode == 'hi'
                                          ? 'चयनित फिल्टर के लिए कोई समाचार नहीं मिला।'
                                          : 'No announcements matching selected filters.')),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF1B5E20),
                    onRefresh: _fetchNews,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _newsList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (ctx, i) =>
                          _buildNewsCard(_newsList[i], langCode),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(AgricultureNewsCategory? cat, String label) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11.5)),
        selected: isSelected,
        selectedColor: const Color(0xFF1B5E20),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF333333),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) {
          setState(() => _selectedCategory = cat);
          _fetchNews();
        },
      ),
    );
  }

  Widget _buildNewsCard(AgricultureNewsItem item, String langCode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openNewsDetail(item, langCode),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.iconEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.category.getLocalizedName(langCode),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (item.applicableState != 'All India')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.applicableState,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.getLocalizedHeadline(langCode),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        item.isBookmarked
                            ? Icons.bookmark_added_rounded
                            : Icons.bookmark_border_rounded,
                        color: const Color(0xFF1B5E20),
                        size: 22,
                      ),
                      onPressed: () => _toggleBookmark(item),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.getLocalizedSummary(langCode),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF555555),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${langCode == 'gu' ? 'સ્ત્રોત' : (langCode == 'hi' ? 'स्रोत' : 'Source')}: ${item.originalSource}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          langCode == 'gu'
                              ? 'વધુ વાંચો'
                              : (langCode == 'hi' ? 'और पढ़ें' : 'Read More'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFF1B5E20),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
