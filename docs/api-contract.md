# Doca API Contract

## Purpose

This document is the shared agreement between the Flutter frontend team and backend team.

Frontend and backend must use the exact field names written here.

Do not rename fields, endpoints, or response properties without informing the whole team and updating this document.

## Base URL

For local computer testing:

http://localhost:5000

For real-phone testing, use the computer's Wi-Fi IP:

http://YOUR_WIFI_IP:5000

All API paths include `/api`.

Example:

http://localhost:5000/api/posts

## General API Rules

- JSON request and response bodies
- Use HTTP status codes correctly
- Include clear error messages
- Frontend must support loading, success, empty, and error states
- Authentication will be connected after the authentication backend is ready
- Mock repositories may be used before backend endpoints are available

## Shared Models

The project will use these models:

- UserProfile
- CommunityPost
- Journey
- JourneyPost
- Notification
- Chat
- Message

## Existing Home Feed Contract

### Load Home Feed

- When it happens: User opens the Home screen
- API: `GET /api/posts?filter=For%20You`
- Request body: None

### Response

````json
{
  "posts": [
    {
      "id": "post_123",
      "alias": "CalmOtter47",
      "timeAgo": "12 min ago",
      "topic": "Skin irritation",
      "status": "Asking",
      "title": "Has anyone experienced something similar?",
      "body": "I noticed some mild redness after changing my skincare routine.",
      "votes": 24,
      "comments": 8,
      "isSensitive": false,
      "rootPostId": null,
      "journeyId": null,
      "parentPostId": null,
      "createdAt": "2026-11-25T12:00:00Z"
    }
  ]
}
`## Authentication and Onboarding Contracts

### Google Authentication

- Owner: Member A
- Screen: Login
- When it happens: User taps Get Started or Already Have an Account and selects Google
- API: `POST /api/auth/google`

### Request

```json
{
  "googleIdToken": "google_token_from_provider"
}
````

### Create Username

- Owner: Member A
- Screen: Create Username
- When it happens: A new user submits a username
- API: `POST /api/auth/username`

#### Request

````json
{
  "username": "CalmOtter47"
}

#### Response: 200 OK

```json
{
  "user": {
    "id": "user_123",
    "alias": "CalmOtter47",
    "usernameCompleted": true,
    "genderCompleted": false
  }
}

#### Loading state

Disable the Continue button and show a loading indicator.

#### Error state

Show an error if the username is invalid or already taken.

#### Success action

Navigate to Select Gender.

### Select Gender

- Owner: Member A
- Screen: Select Gender
- When it happens: A new user selects a gender option
- API: `POST /api/auth/gender`

#### Request

```json
{
  "gender": "prefer_not_to_say"
}

#### Response

```json
{
  "user": {
    "id": "user_123",
    "alias": "CalmOtter47",
    "genderCompleted": true
  }
}
````

#### Loading state

Disable the Continue button and show a loading indicator.

#### Error state

Show an error message and allow the user to retry.

#### Success action

Navigate to Home.
