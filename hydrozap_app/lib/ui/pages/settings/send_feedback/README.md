# HydroZap Feedback System

This folder contains the implementation of the feedback system for HydroZap mobile application.

## Components

1. **Frontend (Mobile App)**
   - `send_feedback_page.dart`: Flutter UI for feedback submission
   - Allows users to submit three types of feedback: Bug Reports, Feature Requests, and General Feedback
   - Collects optional contact information (email, phone)

2. **Backend (Django)**
   - `views.py`: Contains `FeedbackView` API endpoint
   - Handles feedback storage in Firebase Realtime Database
   - Sends email notifications to administrators

3. **Services**
   - `firebase_service.dart`: Contains methods to submit feedback through API
   - Handles error states and user authentication

## Data Flow

1. User submits feedback from the mobile app
2. Data is sent to the Django backend via HTTP POST request
3. Backend stores the feedback in Firebase Realtime Database
4. Backend sends email notification to administrators
5. User receives confirmation in the app

## Feedback Structure

```json
{
  "type": "Bug Report | Feature Request | General Feedback",
  "message": "User's feedback message",
  "email": "user@example.com (optional)",
  "phone": "+1234567890 (optional)",
  "timestamp": "ISO timestamp",
  "user_id": "Firebase UID (if authenticated)",
  "status": "new | in_progress | resolved"
}
```

## API Endpoint

- **URL**: `/feedback/`
- **Method**: POST
- **Success Response**: 201 Created
- **Error Response**: 400 Bad Request or 500 Internal Server Error

## Email Notifications

Administrators receive HTML-formatted emails containing:
- Feedback type
- User contact information (if provided)
- Message content
- Timestamp

## Future Improvements

- Add feedback management dashboard for administrators
- Implement functionality to respond to user feedback
- Add attachments support (screenshots, files)
- Add categorization and tagging system 