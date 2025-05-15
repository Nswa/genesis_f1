# Project Context

## Project Summary

Genesis F1 is a Flutter-based mobile application that provides a journaling platform where users can write, save, and manage their personal journal entries. The app features user authentication with Firebase, a journal entry system, and favorites functionality.

## Main Features

- **User Authentication**: Firebase Auth integration for secure login/signup
- **Journal Entry System**: Create, view, edit, and delete journal entries
- **Journal Search**: Search functionality for finding specific entries
- **Calendar Integration**: View journal entries by date
- **Favorites**: Save and view favorite journal entries
- **Offline Support**: Local data persistence with sembast
- **Image Upload**: Add images to journal entries via Firebase Storage
- **Connectivity Monitoring**: Detect and handle network status changes

## Non-Functional Requirements / Design Language

- **UI Design**: Modern, clean interface with custom theme
- **Fonts**: BreeSerif and IBM Plex Sans
- **Firebase Backend**: Authentication, Firestore, Storage, and App Check
- **Responsiveness**: Works across different screen sizes
- **Performance**: Efficient loading with shimmer placeholders

## Current State

- Fully functional authentication system with Firebase
- Journal screen with create/view/edit capabilities
- Calendar integration for date-based viewing
- Favorites screen implementation
- Image upload and storage functionality

## Notes

- The application uses Flutter SDK ^3.7.2
- Firebase is used as the backend for authentication and data storage
- The project includes connectivity management for offline capabilities
