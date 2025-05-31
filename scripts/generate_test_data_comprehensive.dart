import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Comprehensive test data generator for Collective journaling app
/// Creates 2 years worth of realistic journal entries for a 26-year-old Malaysian 
/// software engineering student with part-time work, hobbies, and authentic writing style
class TestDataGenerator {
  static final Random _random = Random();
  static late DateTime _startDate;
  static late DateTime _endDate;
  static int _entryId = 0;

  // Malaysian student persona traits
  static const String name = "Wei Ming";
  static const int age = 26;
  static const String university = "UTM";
  static const String course = "Software Engineering";
  
  // Malaysian slang and expressions
  static const List<String> malaysianSlang = [
    'lah', 'lor', 'wei', 'mah', 'la', 'kan', 'one', 'already', 'sia', 'ar',
    'confirm plus chop', 'blur like sotong', 'steady lah', 'aiyo', 'wah',
    'chiong', 'shiok', 'paiseh', 'kiasu', 'kiasi', 'yum cha', 'tapau'
  ];

  // Common typos and shortforms in Malaysian context
  static const Map<String, List<String>> typosAndShorts = {
    'the': ['da', 'teh'],
    'you': ['u'],
    'your': ['ur'],
    'because': ['cos', 'bcoz'],
    'something': ['sth', 'smth'],
    'someone': ['sb'],
    'tomorrow': ['tmr', 'tmrw'],
    'today': ['tdy'],
    'yesterday': ['ytd'],
    'project': ['proj'],
    'assignment': ['assgmt', 'asgmt'],
    'university': ['uni'],
    'programming': ['coding'],
    'definitely': ['def'],
    'probably': ['prob'],
    'anyway': ['anw'],
    'okay': ['ok', 'k'],
    'right': ['rite'],
    'night': ['nite'],
    'with': ['w'],
    'without': ['w/o'],
    'and': ['&', 'n'],
    'very': ['v'],
    'really': ['rly'],
    'homework': ['hw'],
  };

  // Entry categories with weights (higher = more frequent)
  static const Map<String, double> entryTypes = {
    'academic_stress': 0.20,
    'work_life': 0.15,
    'social_friends': 0.18,
    'hobbies': 0.15,
    'lazy_days': 0.12,
    'random_thoughts': 0.10,
    'family': 0.10,
  };

  // Mood distribution
  static const Map<String, double> moodWeights = {
    '😊': 0.25, // happy
    '😔': 0.15, // sad
    '😤': 0.12, // frustrated
    '🤔': 0.18, // thoughtful
    '😴': 0.10, // tired
    '🤗': 0.08, // excited
    '😎': 0.07, // cool
    '🙄': 0.05, // annoyed
  };

  // Time patterns (24-hour format)
  static const Map<String, List<int>> timePatterns = {
    'morning': [6, 7, 8, 9, 10, 11],
    'afternoon': [12, 13, 14, 15, 16, 17],
    'evening': [18, 19, 20, 21],
    'night': [22, 23, 0, 1, 2],
  };

  static Future<void> main() async {
    print('🚀 Starting comprehensive test data generation for Collective app...');
    
    // Set date range: 2 years ago to now
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 730));
    
    print('📅 Generating entries from ${_startDate.toString().split(' ')[0]} to ${_endDate.toString().split(' ')[0]}');
    
    final entries = <Map<String, dynamic>>[];
    
    // Generate entries with realistic frequency
    DateTime currentDate = _startDate;
    while (currentDate.isBefore(_endDate)) {
      // 2-4 entries per day on average, with some days having none
      final dayType = _getDayType(currentDate);
      final entryCount = _getEntriesForDay(dayType);
      
      for (int i = 0; i < entryCount; i++) {
        final entry = _generateEntry(currentDate, i);
        entries.add(entry);
      }
      
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // Shuffle entries to make timestamps more realistic
    entries.shuffle(_random);
    
    // Sort by timestamp
    entries.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
    
    print('📝 Generated ${entries.length} entries');
    print('📊 Statistics:');
    _printStatistics(entries);
    
    // Save to JSON file
    const outputPath = 'test_data.json';
    await _saveToFile(entries, outputPath);
    
    print('✅ Test data saved to: $outputPath');
    print('🎯 Ready for injection into the app!');
  }

  static String _getDayType(DateTime date) {
    if (date.weekday >= 6) return 'weekend';
    if (_isUniversityHoliday(date)) return 'holiday';
    if (_isExamPeriod(date)) return 'exam';
    return 'weekday';
  }

  static int _getEntriesForDay(String dayType) {
    switch (dayType) {
      case 'weekend': return _random.nextInt(4) + 1; // 1-4 entries
      case 'holiday': return _random.nextInt(3) + 1; // 1-3 entries
      case 'exam': return _random.nextInt(2) + 1; // 1-2 entries (stressed)
      default: return _random.nextInt(3) + 1; // 1-3 entries
    }
  }

  static bool _isUniversityHoliday(DateTime date) {
    // Simplified holiday detection
    final month = date.month;
    return month == 12 || month == 1 || month == 6; // Dec, Jan, June
  }

  static bool _isExamPeriod(DateTime date) {
    final month = date.month;
    return month == 5 || month == 11; // May, November
  }

  static Map<String, dynamic> _generateEntry(DateTime date, int entryIndex) {
    final entryType = _selectEntryType();
    final timeOfDay = _selectTimeOfDay(entryType);
    final hour = _selectHour(timeOfDay);
    final minute = _random.nextInt(60);
    
    final timestamp = DateTime(date.year, date.month, date.day, hour, minute);
    final localId = 'local_test_${timestamp.millisecondsSinceEpoch}_${_entryId++}';
    
    final content = _generateEntryContent(entryType, date, timeOfDay);
    final mood = _selectMood(entryType);
    final tags = _generateTags(entryType, content);
    final wordCount = content.split(' ').where((word) => word.isNotEmpty).length;
    
    return {
      'localId': localId,
      'firestoreId': null,
      'text': content,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
      'tags': tags,
      'wordCount': wordCount,
      'imageUrl': null,
      'isFavorite': _random.nextDouble() < 0.08, // 8% favorite rate
      'isSynced': false,
      'localImagePath': null,
    };
  }

  static String _selectEntryType() {
    final rand = _random.nextDouble();
    double cumulative = 0.0;
    
    for (final entry in entryTypes.entries) {
      cumulative += entry.value;
      if (rand <= cumulative) return entry.key;
    }
    
    return 'random_thoughts';
  }

  static String _selectTimeOfDay(String entryType) {
    switch (entryType) {
      case 'academic_stress':
        return _random.nextBool() ? 'afternoon' : 'night';
      case 'work_life':
        return _random.nextBool() ? 'afternoon' : 'evening';
      case 'social_friends':
        return _random.nextBool() ? 'evening' : 'night';
      case 'hobbies':
        return ['afternoon', 'evening'][_random.nextInt(2)];
      case 'lazy_days':
        return ['morning', 'afternoon'][_random.nextInt(2)];
      default:
        return ['morning', 'afternoon', 'evening', 'night'][_random.nextInt(4)];
    }
  }

  static int _selectHour(String timeOfDay) {
    final hours = timePatterns[timeOfDay] ?? [12];
    return hours[_random.nextInt(hours.length)];
  }

  static String? _selectMood(String entryType) {
    // Some entries have no mood (30% chance)
    if (_random.nextDouble() < 0.3) return null;
    
    final rand = _random.nextDouble();
    double cumulative = 0.0;
    
    // Adjust mood weights based on entry type
    Map<String, double> adjustedWeights = Map.from(moodWeights);
    
    switch (entryType) {
      case 'academic_stress':
        adjustedWeights['😤'] = 0.25;
        adjustedWeights['😔'] = 0.20;
        adjustedWeights['😴'] = 0.20;
        break;
      case 'work_life':
        adjustedWeights['😤'] = 0.20;
        adjustedWeights['😔'] = 0.15;
        break;
      case 'social_friends':
        adjustedWeights['😊'] = 0.40;
        adjustedWeights['🤗'] = 0.15;
        break;
      case 'hobbies':
        adjustedWeights['😊'] = 0.35;
        adjustedWeights['😎'] = 0.15;
        break;
      case 'lazy_days':
        adjustedWeights['😴'] = 0.30;
        adjustedWeights['😊'] = 0.20;
        break;
    }
    
    for (final entry in adjustedWeights.entries) {
      cumulative += entry.value;
      if (rand <= cumulative) return entry.key;
    }
    
    return '😊';
  }

  static String _generateEntryContent(String entryType, DateTime date, String timeOfDay) {
    final baseContent = _generateBaseContent(entryType, date);
    final processed = _applyMalaysianStyle(baseContent);
    return processed;
  }

  static String _generateBaseContent(String entryType, DateTime date) {
    final month = date.month;
    final dayOfWeek = date.weekday;
    final isWeekend = dayOfWeek >= 6;
    final isExamPeriod = _isExamPeriod(date);
    
    switch (entryType) {
      case 'academic_stress':
        return _generateAcademicContent(isExamPeriod, month);
      case 'work_life':
        return _generateWorkContent(isWeekend);
      case 'social_friends':
        return _generateSocialContent(isWeekend);
      case 'hobbies':
        return _generateHobbyContent();
      case 'lazy_days':
        return _generateLazyContent(isWeekend);
      case 'random_thoughts':
        return _generateRandomThoughts();
      case 'family':
        return _generateFamilyContent();
      default:
        return _generateRandomThoughts();
    }
  }

  static String _generateAcademicContent(bool isExamPeriod, int month) {
    final academicEntries = [
      // Assignments and projects
      "FYP progress meeting today. Supervisor wants more documentation. Sometimes I think they want us to document every breath we take.",
      "Data structures assignment due tomorrow and I'm stuck on the binary tree implementation. YouTube tutorials here I come.",
      "Group project meeting was chaos. Everyone wants to be the leader but nobody wants to do the actual work.",
      "Finally understood how machine learning algorithms work. Took me 3 weeks but the lightbulb moment was worth it.",
      "Software engineering methodology exam next week. Time to memorize waterfall vs agile for the 100th time.",
      "Coding bootcamp assignment on React hooks. Still confused about useEffect dependencies.",
      "Database design project is giving me nightmares. Normalization rules are more complicated than my love life.",
      "Algorithm complexity analysis makes my head hurt. Big O notation should be called Big Oh-No notation.",
      "Computer networks assignment about TCP/IP. At least now I know why my internet is so slow.",
      "Human computer interaction project requires user interviews. Talking to strangers is scarier than coding.",
      
      // Exam stress
      "2 more exams to go. Surviving on coffee and instant noodles. This is fine. Everything is fine.",
      "Studied for 8 hours straight. My brain feels like mashed potatoes.",
      "Exam hall was freezing cold. Hard to think when your fingers are numb.",
      "Multiple choice questions are evil. Between A and C, life becomes meaningless.",
      "Open book exam but forgot to bring calculator. Basic math suddenly became rocket science.",
      "Final year project presentation went surprisingly well. Maybe I do know what I'm talking about.",
      
      // Lectures and classes
      "Operating systems lecture was actually interesting today. Process scheduling is like organizing my life.",
      "Skipped morning lecture because of rain. Priorities: staying dry > education.",
      "Professor's code example had bugs. Spent 30 minutes debugging before realizing it wasn't my fault.",
      "Computer graphics assignment requires OpenGL. Why do they torture us with ancient technology?",
      "Mobile app development using Flutter. Finally something that might be useful in real life.",
      "Artificial intelligence course is making me question my own intelligence.",
      
      // University life
      "Library wifi is down again. How am I supposed to copy-paste from Stack Overflow?",
      "Cafeteria food is getting worse. RM5 for rubber chicken and sad vegetables.",
      "Parking on campus is a battle royale. Arrived 2 hours early just to find a spot.",
      "Group study session turned into gossip session. We're definitely failing this exam.",
      "Dean's list ceremony next week. Finally some recognition for my suffering.",
      "Graduation is 6 months away. Scared and excited at the same time.",
    ];

    if (isExamPeriod) {
      final examEntries = academicEntries.where((entry) => 
        entry.contains('exam') || entry.contains('study') || entry.contains('stress')).toList();
      return examEntries[_random.nextInt(examEntries.length)];
    }

    return academicEntries[_random.nextInt(academicEntries.length)];
  }

  static String _generateWorkContent(bool isWeekend) {
    final workEntries = [
      // Part-time jobs
      "Part-time job at the cafe was busy today. Made 47 drinks and my hands smell like coffee beans.",
      "Customer complained about cold food. Sir, you ordered ice cream, what did you expect?",
      "Night shift at the convenience store. 3am customers are either very drunk or very strange.",
      "Tutoring high school kids in programming. They learn faster than me, feeling old at 26.",
      "Weekend job at the electronics store. Explained the difference between 4GB and 8GB RAM 20 times.",
      "Freelance web development project is finally done. Client changed requirements 15 times.",
      "Job interview at tech startup went well. They have free snacks and bean bags. I'm sold.",
      "Intern orientation at software company. Everyone looks 12 years old except me.",
      "Part-time graphic design work is more creative than I expected. Actually enjoying it.",
      "Food delivery job during lunch rush. GPS led me to a construction site. Thanks technology.",
      
      // Money and financial stress
      "Calculated monthly expenses vs income. Mathematics confirms I'm broke.",
      "PTPTN loan disbursement finally came through. Rich for exactly 3 days.",
      "Part-time salary can't keep up with textbook prices. Who needs knowledge anyway?",
      "Found RM20 in old jeans pocket. This is better than winning the lottery.",
      "Rent is due next week. Time to survive on maggi mee and hope.",
      
      // Job hunting
      "Applied to 15 companies this month. Got 2 rejection emails and 13 black holes.",
      "LinkedIn profile views increased after adding buzzwords like 'synergy' and 'disruptive'.",
      "HR called for phone interview. Panicked and forgot my own name for 10 seconds.",
      "Salary negotiation is an art I haven't mastered. Asked for market rate, got market vegetables.",
      "Job fair at university was crowded. Collected 20 brochures and 3 pen drives.",
    ];

    return workEntries[_random.nextInt(workEntries.length)];
  }

  static String _generateSocialContent(bool isWeekend) {
    final socialEntries = [
      // Friends and social life
      "Yum cha session with coursemates until 2am. Discussed everything except assignments.",
      "Karaoke night was epic. My rendition of 'My Way' cleared the room in 30 seconds.",
      "Birthday celebration at mamak. 12 people, 1 birthday, 47 roti canai orders.",
      "Movie night with friends. Horror movie marathon was a bad idea. Can't sleep now.",
      "Clubbing last night was exhausting. Too old for this but too young to admit it.",
      "BBQ at friend's house. Burned the chicken but the vibes were perfect.",
      "Game night turned competitive. Monopoly ended 3 friendships and started 2 arguments.",
      "Hiking trip with university gang. Nature is beautiful but mosquitoes are evil.",
      "Beach trip to Port Dickson. Sunburned despite applying sunscreen 5 times.",
      "Food hunting expedition in SS15. Found the best cendol in Selangor.",
      
      // Dating and relationships
      "Coffee date went well. She laughed at my jokes or she's very polite.",
      "Tinder match conversation died after 'How's your day'. Small talk is hard.",
      "Relationship status: in love with my code editor. Stable and reliable.",
      "Valentine's Day dinner reservation for one. Treating myself like a queen.",
      "Couple goals: finding someone who debugs my code and brings me food.",
      
      // Social events
      "Wedding dinner was fancy. 8 courses, 3 hours, 1 very full stomach.",
      "Chinese New Year reunion dinner. Relatives asked about job prospects 47 times.",
      "Hari Raya open house hopping. Gained 3kg and new appreciation for loose pants.",
      "Deepavali celebration with Indian coursemates. Learned to eat with hands properly.",
      "Christmas party gift exchange. Got a weird mug, gave a weird book. Perfect balance.",
    ];

    return socialEntries[_random.nextInt(socialEntries.length)];
  }

  static String _generateHobbyContent() {
    final hobbyEntries = [
      // Skateboarding
      "Skateboard session at Paradigm Mall. Landed kickflip after 200 attempts. Persistence pays off.",
      "New skateboard deck arrived. Spent 2 hours assembling and 5 minutes riding. Priorities.",
      "Skate park was crowded with kids. Feeling ancient but their energy is infectious.",
      "Watched skateboarding videos for 3 hours. My technique improved 0% but motivation increased 100%.",
      "Scraped knee attempting tre flip. Bandages and pride both needed replacement.",
      "Solo skateboarding session. Sometimes you need wheels, wind, and no witnesses.",
      
      // Guitar
      "Guitar practice session lasted 4 hours. Neighbors probably hate me but my calluses approve.",
      "Learned new song on YouTube. Tutorial said 'easy' but my fingers disagree violently.",
      "Jam session with friends. We sound terrible but enthusiasm makes up for skill.",
      "Guitar strings snapped during emotional ballad. Even my instrument has feelings.",
      "Open mic night next week. Nervous about performing but excited to share music.",
      "Acoustic session in the park. Playing for squirrels and joggers feels surprisingly therapeutic.",
      
      // Football
      "Football match with coursemates. Lost 3-1 but scored 1 beautiful goal. Moral victory.",
      "World Cup match at mamak. Malaysia didn't qualify but our commentary was world-class.",
      "Futsal tournament at university. Team chemistry good, actual skills questionable.",
      "Watched Liverpool vs Man City. 90 minutes of stress disguised as entertainment.",
      "Weekend football league registration. Time to pretend I'm still athletic.",
      "Playing Football Manager until 4am. Virtual trophies count as real achievements right?",
      
      // Gaming and tech
      "New video game release. Productivity and social life officially on hold.",
      "Built new PC setup. RGB lighting is not necessary but essential for performance.",
      "Gaming marathon with friends. 12 hours, 15 energy drinks, 1 questionable life choice.",
      "Code review feels like gaming. Finding bugs is like hunting Easter eggs.",
      "Streaming setup complete. Ready to entertain dozens of viewers and my mom.",
    ];

    return hobbyEntries[_random.nextInt(hobbyEntries.length)];
  }

  static String _generateLazyContent(bool isWeekend) {
    final lazyEntries = [
      // Lazy days and procrastination
      "Sunday agenda: bed to couch to bed. Achieved all goals successfully.",
      "Spent 6 hours watching TikTok. Algorithm knows me better than my family.",
      "Netflix suggested 'Are you still watching?' Yes Netflix, this is my life now.",
      "Ordered food delivery 3 times today. Kitchen is for decoration purposes only.",
      "Planned to be productive. Instead reorganized phone apps for 2 hours. Close enough.",
      "Pajamas dress code for the entire weekend. Fashion statements include mismatched socks.",
      "YouTube rabbit hole: started with study tips, ended with cat videos. Education is diverse.",
      "Afternoon nap turned into evening sleep. Time is a social construct anyway.",
      "Pretended to study by opening textbook. Photosynthesis happens to books right?",
      "Cleaned room by moving mess from bed to chair. Organization is about redistribution.",
      
      // Food and comfort
      "Maggi mee for breakfast, lunch, and dinner. Balanced diet includes 3 different flavors.",
      "Cooking experiment failed. Smoke alarm is not a timer, lesson learned.",
      "Food coma after McDonald's delivery. Deep philosophical thoughts about burger construction.",
      "Craving homemade food but too lazy to cook. Paradox of adult life.",
      "Discovered new coffee shop. Caffeine addiction has geographical expansion.",
      
      // Weather and mood
      "Rainy day vibes. Perfect excuse to stay indoors and question life choices.",
      "Hot weather makes me appreciate air conditioning and cold drinks. Modern miracles.",
      "Cloudy sky matches my mood. Weather and emotions are mysteriously connected.",
    ];

    return lazyEntries[_random.nextInt(lazyEntries.length)];
  }

  static String _generateRandomThoughts() {
    final randomEntries = [
      // Philosophical thoughts
      "Random thought: Why do we park in driveways and drive on parkways? English is weird.",
      "Shower thought: If time heals everything, why do some wounds leave scars?",
      "3am philosophy: Are we living life or is life living us? Too deep for midnight.",
      "Wondering if parallel universe me is more successful or equally confused about existence.",
      "Life update: Still don't know what I'm doing but doing it with confidence.",
      
      // Technology observations
      "Phone battery dies exactly when I need it most. Technology has a sense of humor.",
      "Autocorrect changed 'debugging' to 'hugging'. Maybe my code needs emotional support.",
      "Wifi speed is inversely proportional to assignment deadline urgency. Scientific fact.",
      "Smart home devices are getting too smart. Alexa judges my music choices now.",
      "Social media timeline shows everyone's highlight reel. My behind-the-scenes is chaotic.",
      
      // Adult life realizations
      "Adult life: excitement about new sponges and panic about electricity bills.",
      "Quarter-life crisis hits different when you're almost 27. Time moves suspiciously fast.",
      "Responsibility is overrated. Want to return to childhood with warranty intact.",
      "Grocery shopping as adult is 90% confused staring and 10% impulse buying.",
      "Tax season approaches. Annual reminder that math was indeed important.",
      
      // Malaysian culture
      "Malaysian solution to everything: add more chili and hope for the best.",
      "Traffic jam meditation: acceptance, patience, and strategic lane changing.",
      "Malaysia weather: sunny morning, thunderstorm afternoon, sauna evening. Choose your adventure.",
      "Food delivery apps know my address better than my relatives. Modern relationships.",
    ];

    return randomEntries[_random.nextInt(randomEntries.length)];
  }

  static String _generateFamilyContent() {
    final familyEntries = [
      // Family interactions
      "Called mom today. Conversation lasted 2 hours, learned neighborhood gossip for 6 months.",
      "Dad's advice for life problems: 'Just work harder.' Thanks dad, very specific.",
      "Family WhatsApp group is 90% forwarded messages and 10% actual family updates.",
      "Cousin got promoted. Family pressure to achieve similar success intensifies immediately.",
      "Grandma still thinks I'm 12 years old. Free snacks policy remains unchanged.",
      "Family dinner discussion about my future career. Same questions, optimistic answers.",
      
      // Hometown visits
      "Weekend trip back to hometown. Traffic jam for 4 hours, visit for 2 hours. Math checks out.",
      "Hometown food hits different. Childhood flavors activate nostalgic time travel mode.",
      "Old school friends gathering. Everyone's married except me. Single life champion status maintained.",
      "Helping mom with technology problems. 'Have you tried turning it off and on again?' works 80% of time.",
      
      // Family expectations
      "Family asks about graduation timeline. Optimistic projections meet realistic procrastination schedules.",
      "Relative comparison session: 'Your cousin graduated faster.' Motivation level decreases proportionally.",
      "Family proud of my programming skills. They think I can hack into anything. I can barely hack homework.",
    ];

    return familyEntries[_random.nextInt(familyEntries.length)];
  }

  static String _applyMalaysianStyle(String content) {
    var result = content;
    
    // Add Malaysian slang occasionally (20% chance)
    if (_random.nextDouble() < 0.2) {
      final slang = malaysianSlang[_random.nextInt(malaysianSlang.length)];
      result = result.replaceFirst('.', ' $slang.');
    }
    
    // Apply typos and shortforms (15% chance per word)
    final words = result.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (_random.nextDouble() < 0.15) {
        final word = words[i].toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        if (typosAndShorts.containsKey(word)) {
          final replacements = typosAndShorts[word]!;
          final replacement = replacements[_random.nextInt(replacements.length)];
          words[i] = words[i].replaceAll(RegExp(word, caseSensitive: false), replacement);
        }
      }
    }
    
    result = words.join(' ');
    
    // Add casual punctuation style (Malaysian text style)
    if (_random.nextDouble() < 0.3) {
      result = result.replaceAll('.', '...');
    }
    
    if (_random.nextDouble() < 0.2) {
      result = result.replaceAll('!', '!!');
    }
    
    return result;
  }

  static List<String> _generateTags(String entryType, String content) {
    final baseTags = <String>[];
    
    // Add category-based tags
    switch (entryType) {
      case 'academic_stress':
        baseTags.addAll(['study', 'university', 'assignment']);
        if (content.contains('exam')) baseTags.add('exam');
        if (content.contains('project')) baseTags.add('project');
        if (content.contains('code') || content.contains('programming')) baseTags.add('coding');
        break;
      case 'work_life':
        baseTags.addAll(['work', 'money']);
        if (content.contains('interview')) baseTags.add('job-hunt');
        if (content.contains('customer')) baseTags.add('customer-service');
        if (content.contains('freelance')) baseTags.add('freelance');
        break;
      case 'social_friends':
        baseTags.addAll(['friends', 'social']);
        if (content.contains('food') || content.contains('mamak')) baseTags.add('food');
        if (content.contains('movie') || content.contains('karaoke')) baseTags.add('entertainment');
        break;
      case 'hobbies':
        if (content.contains('skateboard')) baseTags.add('skateboard');
        if (content.contains('guitar') || content.contains('music')) baseTags.add('music');
        if (content.contains('football') || content.contains('game')) baseTags.add('sports');
        if (content.contains('gaming') || content.contains('PC')) baseTags.add('gaming');
        break;
      case 'lazy_days':
        baseTags.addAll(['lazy', 'weekend']);
        if (content.contains('Netflix') || content.contains('TikTok')) baseTags.add('entertainment');
        if (content.contains('food') || content.contains('delivery')) baseTags.add('food');
        break;
      case 'random_thoughts':
        baseTags.add('thoughts');
        if (content.contains('life')) baseTags.add('life');
        if (content.contains('technology')) baseTags.add('tech');
        break;
      case 'family':
        baseTags.add('family');
        if (content.contains('mom') || content.contains('dad')) baseTags.add('parents');
        if (content.contains('hometown')) baseTags.add('hometown');
        break;
    }
    
    // Add contextual tags based on content
    if (content.contains('stress') || content.contains('pressure')) baseTags.add('stress');
    if (content.contains('happy') || content.contains('good') || content.contains('great')) baseTags.add('positive');
    if (content.contains('tired') || content.contains('exhausted')) baseTags.add('tired');
    if (content.contains('coffee') || content.contains('drink')) baseTags.add('drinks');
    if (content.contains('rain') || content.contains('weather')) baseTags.add('weather');
    
    // Remove duplicates and limit to 3-5 tags
    final uniqueTags = baseTags.toSet().toList();
    uniqueTags.shuffle(_random);
    
    final count = 2 + _random.nextInt(4); // 2-5 tags
    return uniqueTags.take(count).toList();
  }

  static Future<void> _saveToFile(List<Map<String, dynamic>> entries, String path) async {
    final file = File(path);
    final jsonString = const JsonEncoder.withIndent('  ').convert(entries);
    await file.writeAsString(jsonString);
  }

  static void _printStatistics(List<Map<String, dynamic>> entries) {
    final totalEntries = entries.length;
    final dateRange = entries.map((e) => DateTime.parse(e['timestamp'])).toList();
    dateRange.sort();
    
    final moodCounts = <String, int>{};
    final tagCounts = <String, int>{};
    
    var totalWords = 0;
    var favoriteCount = 0;
    
    for (final entry in entries) {
      // Count moods
      final mood = entry['mood'] as String?;
      if (mood != null) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
      
      // Count tags
      final tags = List<String>.from(entry['tags'] ?? []);
      for (final tag in tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
      
      // Count words and favorites
      totalWords += entry['wordCount'] as int;
      if (entry['isFavorite'] as bool) favoriteCount++;
    }
    
    print('  📊 Total entries: $totalEntries');
    print('  📅 Date range: ${dateRange.first.toString().split(' ')[0]} to ${dateRange.last.toString().split(' ')[0]}');
    print('  📝 Total words: $totalWords');
    print('  ⭐ Favorites: $favoriteCount');
    print('  😊 Most common moods: ${_getTopItems(moodCounts, 3)}');
    print('  🏷️ Most common tags: ${_getTopItems(tagCounts, 5)}');
    print('  📈 Average entries per day: ${(totalEntries / 730).toStringAsFixed(1)}');
  }

  static String _getTopItems(Map<String, int> counts, int limit) {
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .take(limit)
        .map((e) => '${e.key}(${e.value})')
        .join(', ');
  }
}

void main() async {
  await TestDataGenerator.main();
}
