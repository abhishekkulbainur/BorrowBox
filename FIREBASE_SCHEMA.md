# 📦 BorrowBox: Cloud Firestore Data Architecture & Security

This document specifies the complete NoSQL schema, collection structure, composite indexes, and security rules for **BorrowBox** on **Google Firebase** (Cloud Firestore, Firebase Authentication, and Firebase Storage).

---

## 🗄️ Collections Overview

```
firestore/
├── users/ {userId}
│   ├── favorites/ {itemId}
│   ├── blocked_users/ {blockedUserId}
│   └── notifications/ {notificationId}
├── items/ {itemId}
├── borrow_requests/ {requestId}
│   └── events/ {eventId}
├── conversations/ {conversationId}
│   └── messages/ {messageId}
├── reviews/ {reviewId}
├── reports/ {reportId}
├── support_tickets/ {ticketId}
├── communities/ {communityId}
│   └── members/ {memberId}
└── notifications/ {notificationId}  (top-level indexable)
```

---

## 1. `users` Collection
*Document ID: `auth.currentUser.uid` (Matches Firebase Auth UID)*

| Field | Type | Description |
|---|---|---|
| `id` | String | Firebase Auth UID |
| `name` | String | Full user name |
| `email` | String | Registered email address |
| `avatarUrl` | String? | Firebase Storage download URL |
| `bio` | String | Profile bio |
| `location` | String | City / Campus / Neighborhood |
| `rating` | Number (double) | Average rating (1.0 to 5.0, default: 5.0) |
| `reviewCount` | Number (int) | Total number of reviews received |
| `completedLoans`| Number (int) | Successful lending/borrowing transactions completed |
| `isVerified` | Boolean | Verification flag |
| `isAdmin` | Boolean | Administrative privileges (protected by server rules) |
| `createdAt` | Timestamp | Account creation date |
| `updatedAt` | Timestamp | Last profile update date |

---

## 2. `items` Collection
*Document ID: Unique UUID / Auto-generated Firestore ID*

| Field | Type | Description |
|---|---|---|
| `id` | String | Unique item identifier |
| `ownerId` | String | UID of the item owner |
| `ownerName` | String | Cached owner display name |
| `ownerRating` | Number | Cached owner rating |
| `title` | String | Item title |
| `description` | String | Detailed description |
| `category` | String | `electronics`, `books`, `tools`, `sports`, `furniture`, `gaming`, `kitchen`, `accessories`, `educational`, `other` |
| `condition` | String | `like_new`, `excellent`, `good`, `fair` |
| `pickupLocation`| String | Pick-up and handover point |
| `maxDurationDays`| Number (int)| Maximum borrowing period allowed (e.g., 7) |
| `rentalPricePerDay` | Number? | Optional daily rental rate (INR / Local) |
| `depositAmount` | Number? | Optional refundable security deposit |
| `availability` | String | `available`, `reserved`, `borrowed`, `deactivated` |
| `isActive` | Boolean | Owner active toggle (pause / resume) |
| `imageUrls` | Array<String> | Cloudinary CDN delivery URLs (or legacy Storage URLs, backward-compatible) |
| `imagesMeta` | Array<Map> | Rich Cloudinary image metadata objects: `secure_url`, `public_id`, `width`, `height`, `format`, `bytes`, `order`, `is_cover`, `created_at` |
| `terms` | String? | Special lending condition / instructions |
| `communityId` | String? | ID of community if scoped |
| `communityName` | String? | Name of community |
| `favoriteCount` | Number (int) | Count of favorites |
| `createdAt` | Timestamp | Date listed |
| `updatedAt` | Timestamp | Date modified |

---

## 3. `borrow_requests` Collection
*Document ID: Unique UUID / Auto-generated Firestore ID*

| Field | Type | Description |
|---|---|---|
| `id` | String | Unique request ID |
| `listingId` | String | ID of the marketplace item |
| `itemTitle` | String | Cached item title |
| `borrowerId` | String | UID of requesting borrower |
| `borrowerName` | String | Cached borrower display name |
| `ownerId` | String | UID of item owner |
| `ownerName` | String | Cached owner display name |
| `startDate` | Timestamp | Requested start date |
| `endDate` | Timestamp | Requested return date |
| `status` | String | `pending`, `approved`, `handover_pending`, `active`, `return_pending`, `returned`, `rejected`, `cancelled`, `disputed` |
| `message` | String? | Borrower's request message |
| `handoverQrToken`| String? | Cryptographic token for physical pickup verification |
| `returnQrToken` | String? | Cryptographic token for return verification |
| `notes` | String? | Private loan notes |
| `depositAmount` | Number? | Applicable security deposit |
| `rentalFee` | Number? | Total rental fee if applicable |
| `createdAt` | Timestamp | Date request submitted |
| `updatedAt` | Timestamp | Last state transition |

### Subcollection: `borrow_requests/{requestId}/events/{eventId}`
*Immutable audit log representing all handovers and returns*
- `actorId`: String (UID of person who triggered action)
- `fromStatus`: String
- `toStatus`: String
- `eventDescription`: String
- `timestamp`: Timestamp

---

## 4. `conversations` Collection
*Document ID: Composite ID (e.g. `conv_${user1}_${user2}_${itemId}`)*

| Field | Type | Description |
|---|---|---|
| `id` | String | Unique conversation identifier |
| `participants` | Array<String> | UIDs of both peer users |
| `participantNames` | Map<String, String> | Map of user UID to display name |
| `participantAvatars`| Map<String, String?> | Map of user UID to avatar URL |
| `itemId` | String | Marketplace item context |
| `itemTitle` | String | Marketplace item title |
| `lastMessage` | String | Snippet of latest message |
| `lastMessageTime` | Timestamp | Timestamp of latest message |
| `unreadCounts` | Map<String, int> | Unread message counter per UID |

### Subcollection: `conversations/{conversationId}/messages/{messageId}`
- `id`: String
- `conversationId`: String
- `senderId`: String
- `senderName`: String
- `text`: String
- `imageUrl`: String?
- `timestamp`: Timestamp
- `isRead`: Boolean

---

## 5. `reports` Collection
*Document ID: Unique ID*

| Field | Type | Description |
|---|---|---|
| `id` | String | Report ID |
| `reporterId` | String | UID of user filing the report |
| `targetId` | String | ID of reported item or user |
| `type` | String | `item` or `user` |
| `reason` | String | Reason code |
| `details` | String | Additional context / description |
| `status` | String | `pending`, `reviewed`, `dismissed`, `action_taken` |
| `createdAt` | Timestamp | Timestamp report filed |

---

## 6. `reviews` Collection
*Document ID: Unique ID*

| Field | Type | Description |
|---|---|---|
| `id` | String | Review identifier |
| `transactionId` | String | Associated `borrow_requests` ID |
| `reviewerId` | String | UID of user leaving the review |
| `reviewerName` | String | Display name of reviewer |
| `reviewerAvatarUrl` | String? | Avatar URL of reviewer |
| `targetUserId` | String | UID of user being reviewed (Owner or Borrower) |
| `rating` | Number (double) | Star rating (1.0 to 5.0) |
| `comment` | String | Review feedback |
| `itemTitle` | String | Item title for transaction context |
| `createdAt` | Timestamp | Review submission timestamp |

---

## 7. `notifications` Collection
*Document ID: Unique ID*

| Field | Type | Description |
|---|---|---|
| `id` | String | Notification ID |
| `userId` | String | Target recipient UID |
| `title` | String | Title header |
| `message` | String | Message body |
| `type` | String | `borrowRequest`, `requestApproved`, `requestRejected`, `handoverReady`, `returnReminder`, `itemReturned`, `systemAlert` |
| `isRead` | Boolean | Read status |
| `referenceId` | String? | Linked Request/Item ID |
| `createdAt` | Timestamp | Sent timestamp |

---

## 8. Required Composite Indexes (`firestore.indexes.json`)

```json
{
  "indexes": [
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "ownerId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "borrow_requests",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "borrowerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "borrow_requests",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "ownerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "participants", "arrayConfig": "CONTAINS" },
        { "fieldPath": "lastMessageTime", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "conversationId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "targetUserId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

---

## 9. ☁️ Product Image Architecture: Cloudinary Integration

To avoid Google Cloud / Firebase Blaze plan requirements ($0 free-tier without credit cards or surprise paywalls), product image storage and CDN delivery in BorrowBox is powered by **Cloudinary**.

### Zero-Secret Client Architecture
BorrowBox communicates with Cloudinary's Upload API strictly using **unsigned upload presets**.
- **No API Secret** or Admin API credentials are ever embedded in or accessible to Flutter client code.
- Endpoint: `POST https://api.cloudinary.com/v1_1/<cloud_name>/image/upload`
- Multipart form parameters:
  - `upload_preset`: Unsigned preset configured in Cloudinary Dashboard.
  - `folder`: `borrowbox/product_images`
  - `tags`: `borrowbox,product_listing,{userId},{itemId}`
  - `context`: `user_id={userId}|item_id={itemId}|app=borrowbox`

### Saved Firestore Image Schema (`imagesMeta`)
Each item document in Firestore persists:
```json
"imagesMeta": [
  {
    "secure_url": "https://res.cloudinary.com/<cloud>/image/upload/v1730380000/borrowbox/product_images/item_1_0.jpg",
    "public_id": "borrowbox/product_images/item_1_0",
    "width": 1280,
    "height": 960,
    "format": "jpg",
    "bytes": 245120,
    "order": 0,
    "is_cover": true,
    "created_at": "2026-10-31T08:00:00.000Z"
  }
]
```

### Image Pipeline & Performance Constraints
1. **Format Validation**: Strict client validation for `.jpg`, `.jpeg`, `.png`, and `.webp`.
2. **File Size Limit**: Max 10MB input file size before compression (`CloudinaryConfig.maxFileSizeBytes`).
3. **Pre-Upload Compression**:
   - Engine: `flutter_image_compress`
   - Resolution Cap: 1280 x 1280 logical pixels.
   - Target Quality: 80% JPEG.
   - Resulting Payload: ~150KB - 350KB per photo.
4. **Client-Side Image Caching & Dynamic Transformations**:
   - Library: `cached_network_image` with local disk persistence and memory constraints (`memCacheWidth: 600`).
   - Dynamic URL Transformation: `CloudinaryConfig.getOptimizedUrl` automatically injects `f_auto,q_auto,w_{width},c_limit` into Cloudinary delivery URLs for device-responsive bandwidth conservation.
   - Interactive zoom: `InteractiveViewer` with 0.8x to 4.0x pinch-to-zoom for detailed condition inspection.
5. **Secure Asset Deletion & Garbage Collection**:
   - Asset destruction in Cloudinary requires HMAC-SHA1 API signature.
   - To maintain zero-secret client security, deletion requests are registered safely on the client while permanent Cloudinary storage garbage collection is handled via serverless backend webhooks.


