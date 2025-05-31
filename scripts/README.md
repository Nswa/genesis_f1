# Test Data Generation System

This directory contains scripts for generating comprehensive test data for the Collective journaling app.

## Quick Start

1. **Generate comprehensive test data**:
   ```bash
   dart run scripts/generate_test_data_comprehensive.dart
   ```

2. **In the app**: Navigate to the Test Data Management screen and click "Inject Comprehensive Data (2 Years)"

## Files

### `generate_test_data_comprehensive.dart`
The main test data generator that creates 1500+ realistic journal entries spanning 2 years for a 26-year-old Malaysian software engineering student.

**Features:**
- **Authentic Malaysian context**: Includes local slang, cultural references, and typical student experiences
- **Realistic categories**: Academic stress (20%), work life (15%), social/friends (18%), hobbies (15%), lazy days (12%), random thoughts (10%), family (10%)
- **Smart mood distribution**: Context-aware mood selection based on entry content
- **Time patterns**: Realistic posting times based on entry type (e.g., work entries during work hours)
- **Malaysian typing style**: Includes shortforms, typos, and casual language patterns
- **Contextual tags**: Automatically generated tags based on content analysis

**Output:**
- `test_data.json`: Contains all generated entries in the correct format for injection
- Statistics summary displayed in console

## Generated Content Examples

The system generates entries covering:

### Academic Life
- Assignment stress and deadlines
- Programming challenges and debugging sessions
- University presentations and group projects
- Study sessions and exam preparation

### Work Experience
- Part-time retail jobs (sales associate, cashier)
- Customer service experiences
- Freelance web development projects
- Job interviews and applications

### Hobbies & Interests
- **Skateboarding**: Learning tricks, skateboard maintenance, skate park sessions
- **Guitar**: Practice sessions, learning songs, music theory
- **Football**: Watching matches, playing with friends, fantasy football

### Social Life
- Hanging out with friends at mamak stalls
- BBQ sessions and house parties
- Movie nights and gaming sessions
- Relationship thoughts and social interactions

### Malaysian Cultural Context
- Weather complaints (common Malaysian topic)
- Food references (nasi lemak, teh tarik, etc.)
- Local slang and expressions
- Cultural celebrations and holidays

## Technical Details

### Entry Structure
Each generated entry follows the app's data model:
```json
{
  "localId": "local_test_1685682000000_1",
  "firestoreId": null,
  "text": "Assignment due tomorrow and I haven't started. Classic me lah.",
  "timestamp": "2023-06-02T13:00:00.000",
  "mood": "😤",
  "tags": ["study", "assignment", "stress"],
  "wordCount": 10,
  "imageUrl": null,
  "isFavorite": false,
  "isSynced": false,
  "localImagePath": null
}
```

### Date Range
- **Start**: 2 years ago from current date
- **End**: Current date
- **Frequency**: 2-3 entries per day on average
- **Realistic gaps**: Some days have no entries, others have multiple

### Mood Distribution
- 😊 Happy: 25% (achievements, good times with friends)
- 🤔 Thoughtful: 20% (random thoughts, reflections)
- 😔 Sad/Tired: 15% (stress, assignments, work)
- 😤 Frustrated: 12% (coding bugs, difficult customers)
- 😴 Tired: 10% (late nights, lazy days)
- 🤗 Grateful: 8% (family, achievements, good food)
- 😎 Cool: 7% (hobbies, accomplishments)
- 🙄 Annoyed: 3% (minor irritations)

## Usage in App

The generated data integrates seamlessly with the Collective app:

1. **Navigation**: Go to Settings → Test Data Management
2. **Options**:
   - **Generate & Inject Test Data**: Simple 200-entry dataset
   - **Inject Comprehensive Data (2 Years)**: Full 1500+ entry dataset
   - **Import from JSON File**: Manual file selection
   - **Clear Test Data**: Remove all test entries

3. **Statistics**: View real-time database statistics
4. **Safety**: Test entries are clearly marked and can be removed without affecting real entries

## Development Notes

- All test entries have `localId` starting with "local_test_" for easy identification
- The generator uses weighted random selection for realistic content distribution
- Time patterns follow typical student lifestyle (late nights, afternoon classes)
- Malaysian cultural authenticity achieved through careful language pattern analysis
- Content categories are balanced to represent diverse student experiences

## Future Enhancements

Potential improvements to the test data system:

1. **Seasonal content**: Holiday-specific entries, exam periods
2. **Image integration**: Sample images for certain entry types
3. **Location data**: Geotagging for relevant entries
4. **Social connections**: References to recurring friends/family
5. **Academic calendar**: Semester-based content patterns
6. **Mood evolution**: Character growth and emotional journey
7. **Multiple personas**: Different student profiles and backgrounds
