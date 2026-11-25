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
````

## Journey API Contracts

The following endpoints are proposed for frontend skeleton development and require backend review before production use. Until available, the frontend may use a local repository with these request and response fields. Ownership is supplied by the UI; do not add authentication or user ID fields until agreed with the backend team.

Supported `privacy` values are `Private` and `Shared Anonymously`.

Proposed privacy behavior: Private Journeys are accessible only to their owner.
Shared Anonymously Journeys show only the owner's anonymous alias. The backend
must enforce access when authentication is connected. Frontend ownership inputs
are temporary skeleton controls.

The proposed `posts` array contains the root post exactly once. Display the root
first and linked posts in ascending `createdAt` order. Preserve response order
when timestamps match. Legacy posts without timestamps appear last in their
original order.

Create Journey and Add Journey Post responses must include every existing
CommunityPost field, as shown in Load Journey. The compact examples below show
relationship fields only. A complete Add Journey Post response is:

```json
{
  "post": {
    "id": "post_125",
    "alias": "QuietMoon22",
    "timeAgo": "Just now",
    "topic": "Recovery journey",
    "status": "Ongoing",
    "title": "Week three update",
    "body": "I am monitoring the changes.",
    "votes": 0,
    "comments": 0,
    "isSensitive": false,
    "journeyId": "journey_123",
    "rootPostId": "post_123",
    "parentPostId": "post_124",
    "createdAt": "2026-11-26T09:30:00Z"
  }
}
```

The local repository registers an existing owned post before conversion and
checks ownership on reads and writes. Its data is held in memory and resets
when the application restarts. A future HTTP repository must use the reviewed
contract and authenticated server permissions.

### Load Journey

- Screen/button: Journey, View Journey, or Journey tab
- When: The user opens a Journey
- Method: `GET`
- Endpoint: `/api/journeys/{journeyId}`
- Request body: None. Path parameter `journeyId` identifies the Journey.
- Loading: Show a loading indicator.
- Empty: If the root exists without linked posts, show the root followed by `No additional journey posts yet`. If no usable data exists, show `No journey posts yet`.
- Error: Return `{"message":"Unable to load the requested journey."}`. Show an error and Retry button that repeats the request for the same ID.
- Success: Return owner alias, privacy, root post, and linked posts ordered by ascending `createdAt`.

Response `200 OK`:

```json
{
  "journey": {
    "id": "journey_123",
    "ownerAlias": "QuietMoon22",
    "rootPostId": "post_123",
    "privacy": "Shared Anonymously",
    "posts": [
      {
        "id": "post_123",
        "alias": "QuietMoon22",
        "timeAgo": "2 weeks ago",
        "topic": "Recovery journey",
        "status": "Ongoing",
        "title": "Week one update",
        "body": "I started recording changes.",
        "votes": 42,
        "comments": 8,
        "isSensitive": false,
        "journeyId": "journey_123",
        "rootPostId": "post_123",
        "parentPostId": null,
        "createdAt": "2026-11-10T10:00:00Z"
      }
    ]
  }
}
```

### Create Journey

- Screen/button: Home or Create Post, Start Journey
- When: The current user converts a first post into a Journey
- Method: `POST`
- Endpoint: `/api/journeys`
- Request: `{"rootPostId":"post_123","privacy":"Private"}`. Privacy must be `Private` or `Shared Anonymously`.
- Loading: Disable the action and show a loading indicator.
- Error: Return a clear `{"message":"..."}` response. Preserve the original post and show an error.
- Success: Return `201 Created` with `{"journey":{"id":"journey_123","ownerAlias":"QuietMoon22","rootPostId":"post_123","privacy":"Private","posts":[{"id":"post_123","journeyId":"journey_123","rootPostId":"post_123","parentPostId":null,"createdAt":"2026-11-26T09:00:00Z"}]}}`. Update the root post relationship fields and allow opening the Journey.

Complete proposed Create Journey response (`201 Created`):

```json
{
  "journey": {
    "id": "journey_123",
    "ownerAlias": "QuietMoon22",
    "rootPostId": "post_123",
    "privacy": "Private",
    "posts": [
      {
        "id": "post_123",
        "alias": "QuietMoon22",
        "timeAgo": "Just now",
        "topic": "Recovery journey",
        "status": "Ongoing",
        "title": "Starting my journey",
        "body": "I am beginning to record observations.",
        "votes": 0,
        "comments": 0,
        "isSensitive": false,
        "journeyId": "journey_123",
        "rootPostId": "post_123",
        "parentPostId": null,
        "createdAt": "2026-11-26T09:00:00Z"
      }
    ]
  }
}
```

### Add Journey Post

- Screen/button: Journey, Add Post
- When: The Journey owner adds a post
- Method: `POST`
- Endpoint: `/api/journeys/{journeyId}/posts`
- Path parameter: `journeyId` identifies the Journey.
- Request body: `{"parentPostId":"post_124","title":"Week three update","body":"I am monitoring the changes.","topic":"Recovery journey","status":"Ongoing","isSensitive":false}`
- Loading: Disable publish and show a loading indicator.
- Error: Return a clear `{"message":"..."}` response. Preserve the Journey and show an error.
- Success: Return `201 Created` with `{"post":{"id":"post_125","journeyId":"journey_123","rootPostId":"post_123","parentPostId":"post_124","createdAt":"2026-11-26T09:30:00Z"}}`. Add the post to the Journey in `createdAt` order and show success.

## Authentication and Onboarding Contracts

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
