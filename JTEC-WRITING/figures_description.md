# JTEC Conference Paper - Required Figures and Graphics

## Figure 1: System Architecture Overview (system_architecture.png)
- **Description**: High-level system architecture diagram showing three-tier design
- **Components**: 
  - Presentation Layer (Flutter Mobile App)
  - Business Logic Layer (Local Services, Cloud Services, AI Services)
  - Data Layer (Sembast Local DB, Firebase Firestore, Firebase Storage)
- **Visual Style**: Clean technical diagram with proper layering and data flow arrows
- **Dimensions**: 600x400 pixels for IEEE format compatibility

## Figure 2: Data Flow Architecture (data_flow_diagram.png)
- **Description**: Detailed data flow showing offline-first synchronization strategy
- **Components**:
  - User Input → Local Storage → Sync Queue
  - Connectivity Detection → Cloud Sync → Conflict Resolution
  - AI Processing Pipeline → Insights Generation
- **Visual Style**: Flowchart with decision points and process boxes
- **Dimensions**: 600x450 pixels

## Figure 3: Main User Interface Screens (ui_interface_screens.png)
- **Description**: Composite screenshot showing key app screens
- **Components**:
  - Journal Writing Interface (minimalist design)
  - Entry List View (with date grouping)
  - AI Insights Screen (analytics dashboard)
  - Settings and Profile Screen
- **Visual Style**: Mobile mockups with Material Design 3 styling
- **Dimensions**: 800x600 pixels (4 screens in 2x2 grid)

## Figure 4: AI Processing Workflow (ai_processing_flow.png)
- **Description**: Technical workflow showing AI integration pipeline
- **Components**:
  - Text Input → Preprocessing → DeepSeek API
  - Sentiment Analysis → Pattern Recognition → Insight Generation
  - Caching Strategy → Response Formatting → UI Display
- **Visual Style**: Technical flowchart with API integration details
- **Dimensions**: 700x400 pixels

## Figure 5: Usability Testing Results Summary (usability_testing_results.png)
- **Description**: Bar chart showing user satisfaction across 10 evaluation criteria
- **Data Points**:
  - UI Satisfaction: 4.5/5.0
  - Navigation Ease: 4.3/5.0
  - Performance: 4.3/5.0
  - AI Features: 4.4/5.0
  - Offline/Sync: 4.1/5.0
  - Mood Analytics: 4.5/5.0
  - Goal Achievement: 4.4/5.0
  - Recommendation: 4.2/5.0
  - Distraction-Free: 4.3/5.0
  - Overall Experience: 4.5/5.0
- **Visual Style**: Professional bar chart with clear labeling and color coding
- **Dimensions**: 600x400 pixels

## Table 1: Performance Metrics Analysis
- **Description**: Tabular data showing performance across different operational modes
- **Metrics**: Startup time, entry creation, AI processing, search response, memory usage
- **Modes**: Offline, Online, Synchronization
- **Format**: Standard IEEE table format with clear headers and units

## Additional Technical Diagrams (Optional)

### User Journey Flow Diagram
- **Description**: Step-by-step user interaction flow from app launch to insight generation
- **Components**: Onboarding → Writing → Analysis → Insights → Retention
- **Visual Style**: User experience flowchart with decision points

### Architecture Component Diagram
- **Description**: Detailed technical component breakdown
- **Components**: Flutter widgets, Services, Controllers, Models, External APIs
- **Visual Style**: UML-style component diagram

### Comparative Analysis Chart
- **Description**: Feature comparison with existing journaling applications
- **Platforms**: Collective vs. Day One vs. Evernote vs. Notion
- **Metrics**: Simplicity, AI Features, Offline Support, User Satisfaction
- **Visual Style**: Radar chart or comparison matrix

## Figure Creation Guidelines

1. **Consistency**: All figures should use consistent color scheme and typography
2. **Readability**: Text should be legible at conference presentation size
3. **Professional Quality**: High-resolution graphics suitable for publication
4. **IEEE Compliance**: Follow IEEE conference figure formatting guidelines
5. **Technical Accuracy**: All diagrams should accurately represent implementation details

## Color Scheme Recommendations
- **Primary**: DeepPurple (#6200EE) - matching app theme
- **Secondary**: Teal (#009688) - for data flow
- **Accent**: Orange (#FF9800) - for highlights
- **Neutral**: Gray (#757575) - for supporting elements
- **Background**: White (#FFFFFF) - for publication clarity

## Software Recommendations
- **Diagrams**: Draw.io, Lucidchart, or Adobe Illustrator
- **Charts**: matplotlib, Chart.js, or Excel with professional styling
- **Screenshots**: Direct from app with consistent device frame
- **Technical Diagrams**: Visio, OmniGraffle, or specialized UML tools
