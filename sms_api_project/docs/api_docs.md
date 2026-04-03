# MoMo SMS Transactions API Documentation

## Overview
This API provides access to MTN Mobile Money SMS transaction records.
It is built using plain Python (`http.server`) and secured with Basic Authentication.

- **Base URL:** `http://localhost:8000`
- **Authentication:** Basic Auth (username + password required on every request)
- **Data Format:** JSON

---

## Authentication

All endpoints require Basic Authentication.

| Field    | Value         |
|----------|---------------|
| Username | `admin`       |
| Password | `password123` |

If credentials are missing or incorrect, the API returns:

**Status Code:** `401 Unauthorized`
```json
{
  "error": "Unauthorized",
  "message": "Valid username and password required."
}
```

### Why Basic Auth is Weak
Basic Authentication encodes credentials in Base64, which is **not encryption**.
Anyone who intercepts the request can easily decode the credentials.

### Stronger Alternatives
| Method | Why it's better |
|--------|----------------|
| **JWT (JSON Web Tokens)** | Issues a signed token after login. No password sent on every request. Token expires automatically. |
| **OAuth2** | Industry standard. Allows third-party login (Google, Facebook). Tokens are scoped and can be revoked. |
| **API Keys** | A unique key per client. Easy to revoke if compromised. |

---

## Endpoints

---

### 1. GET /transactions
Returns a list of all SMS transaction records.

**Method:** `GET`
**URL:** `http://localhost:8000/transactions`

#### Request Example
```
GET /transactions HTTP/1.1
Host: localhost:8000
Authorization: Basic YWRtaW46cGFzc3dvcmQxMjM=
```

#### Response Example
**Status Code:** `200 OK`
```json
[
  {
    "id": 1,
    "address": "M-Money",
    "date": "1715351458724",
    "readable_date": "10 May 2024 4:30:58 PM",
    "body": "You have received 2000 RWF from Jane Smith...",
    "type": "1",
    "read": "1",
    "service_center": "+250788110381"
  },
  {
    "id": 2,
    "address": "M-Money",
    "date": "1715351506754",
    "readable_date": "10 May 2024 4:31:46 PM",
    "body": "TxId: 73214484437. Your payment of 1,000 RWF...",
    "type": "1",
    "read": "1",
    "service_center": "+250788110381"
  }
]
```

#### Error Codes
| Code | Meaning |
|------|---------|
| 200 | Success |
| 401 | Unauthorized — wrong or missing credentials |

---

### 2. GET /transactions/{id}
Returns a single transaction by its ID.

**Method:** `GET`
**URL:** `http://localhost:8000/transactions/{id}`

#### Request Example
```
GET /transactions/1 HTTP/1.1
Host: localhost:8000
Authorization: Basic YWRtaW46cGFzc3dvcmQxMjM=
```

#### Response Example
**Status Code:** `200 OK`
```json
{
  "id": 1,
  "address": "M-Money",
  "date": "1715351458724",
  "readable_date": "10 May 2024 4:30:58 PM",
  "body": "You have received 2000 RWF from Jane Smith...",
  "type": "1",
  "read": "1",
  "service_center": "+250788110381"
}
```

#### Error Codes
| Code | Meaning |
|------|---------|
| 200 | Success |
| 401 | Unauthorized — wrong or missing credentials |
| 404 | Transaction with that ID not found |
| 400 | ID must be a number |

---

### 3. POST /transactions
Adds a new transaction record.

**Method:** `POST`
**URL:** `http://localhost:8000/transactions`

#### Request Example
```
POST /transactions HTTP/1.1
Host: localhost:8000
Authorization: Basic YWRtaW46cGFzc3dvcmQxMjM=
Content-Type: application/json

{
  "address": "M-Money",
  "readable_date": "03 Apr 2026 10:00:00 AM",
  "body": "You have received 5000 RWF from Test User.",
  "type": "1",
  "read": "1",
  "service_center": "+250788110381"
}
```

#### Response Example
**Status Code:** `201 Created`
```json
{
  "message": "Transaction created.",
  "transaction": {
    "id": 1692,
    "address": "M-Money",
    "readable_date": "03 Apr 2026 10:00:00 AM",
    "body": "You have received 5000 RWF from Test User.",
    "type": "1",
    "read": "1",
    "service_center": "+250788110381"
  }
}
```

#### Error Codes
| Code | Meaning |
|------|---------|
| 201 | Transaction created successfully |
| 400 | Invalid JSON in request body |
| 401 | Unauthorized — wrong or missing credentials |

---

### 4. PUT /transactions/{id}
Updates an existing transaction by its ID.

**Method:** `PUT`
**URL:** `http://localhost:8000/transactions/{id}`

#### Request Example
```
PUT /transactions/1 HTTP/1.1
Host: localhost:8000
Authorization: Basic YWRtaW46cGFzc3dvcmQxMjM=
Content-Type: application/json

{
  "address": "M-Money",
  "readable_date": "03 Apr 2026 12:00:00 PM",
  "body": "UPDATED: You have received 9999 RWF from Updated User.",
  "type": "1",
  "read": "1",
  "service_center": "+250788110381"
}
```

#### Response Example
**Status Code:** `200 OK`
```json
{
  "message": "Transaction updated.",
  "transaction": {
    "id": 1,
    "address": "M-Money",
    "readable_date": "03 Apr 2026 12:00:00 PM",
    "body": "UPDATED: You have received 9999 RWF from Updated User.",
    "type": "1",
    "read": "1",
    "service_center": "+250788110381"
  }
}
```

#### Error Codes
| Code | Meaning |
|------|---------|
| 200 | Transaction updated successfully |
| 400 | Invalid JSON or ID must be a number |
| 401 | Unauthorized — wrong or missing credentials |
| 404 | Transaction with that ID not found |

---

### 5. DELETE /transactions/{id}
Deletes a transaction by its ID.

**Method:** `DELETE`
**URL:** `http://localhost:8000/transactions/{id}`

#### Request Example
```
DELETE /transactions/1692 HTTP/1.1
Host: localhost:8000
Authorization: Basic YWRtaW46cGFzc3dvcmQxMjM=
```

#### Response Example
**Status Code:** `200 OK`
```json
{
  "message": "Transaction 1692 deleted successfully."
}
```

#### Error Codes
| Code | Meaning |
|------|---------|
| 200 | Transaction deleted successfully |
| 400 | ID must be a number |
| 401 | Unauthorized — wrong or missing credentials |
| 404 | Transaction with that ID not found |

---

## Summary of Error Codes

| Code | Meaning |
|------|---------|
| 200 | OK — request successful |
| 201 | Created — new record added |
| 400 | Bad Request — invalid input |
| 401 | Unauthorized — invalid credentials |
| 404 | Not Found — record or route does not exist |