# 📦 BorrowBox: Cloud Firestore Data Architecture & Security

This document specifies the complete NoSQL schema, collection structure, and security rules for **BorrowBox** on **Google Firebase** (Cloud Firestore, Firebase Authentication, and Firebase Storage), replacing the Supabase PostgreSQL schema.

---

## 🗄️ Collections Overview

```
firestore/
├── users/ {userId}
│   ├── favorites/ {itemId}
│   └── notifications/ {notificationId}
├── items/ {itemId}
├── borrow_requests/ {requestId}
│   └── events/ {eventId}
├── communities/ {communityId}
│   └── members/ {memberId}
├── reviews/ {reviewId}
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
| `isAdmin` | Boolean | Administrative privileges |
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
| `category` | String | `tools`, `electronics`, `books`, `sports`, `household`, `travel`, `calculators`, `creative`, `games`, `other` |
| `condition` | String | `like_new`, `excellent`, `good`, `fair` |
| `pickupLocation`| String | Pick-up and handover point |
| `maxDurationDays`| Number (int)| Maximum borrowing period allowed (e.g., 7) |
| `depositAmount` | Number? | Optional refundable security deposit |
| `availability` | String | `available`, `reserved`, `borrowed` |
| `imageUrls` | Array<String> | Firebase Storage URLs (`borrowbox_images/{itemId}/...`) |
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
| `status` | String | `pending`, `approved`, `handover_pending`, `active`, `return_pending`, `returned`, `rejected`, `cancelled`, `overdue` |
| `message` | String? | Borrower's request message |
| `handoverQrToken`| String? | Cryptographic token for physical pickup verification |
| `returnQrToken` | String? | Cryptographic token for return verification |
| `notes` | String? | Private loan notes |
| `depositAmount` | Number? | Applicable security deposit |
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

## 4. `communities` Collection
*Document ID: Unique ID*

| Field | Type | Description |
|---|---|---|
| `id` | String | Community identifier |
| `name` | String | Community name |
| `description` | String | Description / purpose |
| `type` | String | `apartment`, `neighborhood`, `college`, `hobby`, `general` |
| `location` | String | Geographical locality |
| `memberCount` | Number (int) | Total joined members |
| `activeItemsCount`| Number (int)| Active listings in community |
| `isPrivate` | Boolean | Invite-only or open |
| `icon` | String | Material icon identifier |
| `createdBy` | String | UID of creator |
| `createdAt` | Timestamp | Creation date |

---

## 5. `reviews` Collection
*Document ID: Unique ID*

| Field | Type | Description |
|---|---|---|
| `id` | String | Review identifier |
| `transactionId` | String | Associated `borrow_requests` ID |
| `reviewerId` | String | UID of user leaving the review |
| `reviewerName` | String | Display name of reviewer |
| `targetUserId` | String | UID of user being reviewed (Owner or Borrower) |
| `rating` | Number (int) | Star rating (1 to 5) |
| `comment` | String | Review feedback |
| `createdAt` | Timestamp | Review submission timestamp |

---

## 6. `notifications` Collection
*Document ID: Unique ID*

| Field | Type | Description |
|---|---|---|
| `id` | String | Notification ID |
| `userId` | String | Target recipient UID |
| `title` | String | Title header |
| `message` | String | Message body |
| `type` | String | `requestReceived`, `requestApproved`, `handoverReady`, `itemBorrowed`, `returnPending`, `itemReturned`, `reviewReceived` |
| `isRead` | Boolean | Read status |
| `referenceId` | String? | Linked Request/Item ID |
| `createdAt` | Timestamp | Sent timestamp |

---

## 7. 🗄️ Firebase Storage Buckets Structure

- `borrowbox_images/{itemId}/{fileName}.jpg`: Item listing photos (Max 5MB each).
- `avatars/{userId}/{fileName}.jpg`: User profile avatar images.
