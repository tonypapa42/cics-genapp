# GENAPP - General Insurance Application
## Cloud-Native Specification for Java Spring Boot on Kubernetes

**Version:** 2.0  
**Target Platform:** Kubernetes  
**Technology Stack:** Java 17+, Spring Boot 3.x, PostgreSQL, React

---

## 1. Executive Summary

### 1.1 Application Overview
GENAPP (General Insurance Application) is a comprehensive insurance management system that handles customer records and multiple types of insurance policies. The application supports complete CRUD operations for customers and five types of insurance policies: Motor, Endowment, House, Pet, and Commercial Property.

### 1.2 Modernization Goals
Transform the legacy IBM CICS mainframe application (COBOL) into a cloud-native Java Spring Boot microservices architecture designed to run on any Kubernetes-based runtime, with:
- RESTful API architecture
- Modern web-based user interface
- Cloud-native data persistence (PostgreSQL, MySQL, or SQL Server)
- Containerized deployment on Kubernetes
- Horizontal scalability and high availability
- Comprehensive observability and monitoring

### 1.3 Key Business Capabilities
1. **Customer Management**: Create, read, update, and delete customer records
2. **Policy Management**: Full lifecycle management of five policy types
3. **Multi-Policy Support**: Link multiple policies to a single customer
4. **Data Integrity**: Referential integrity with cascade delete operations
5. **Audit Trail**: Track policy changes with timestamps

---

## 2. Business Domain Model

### 2.1 Core Entities

#### 2.1.1 Customer
Represents an insurance customer with personal details and contact information.

**Attributes:**
- `customerNumber` (Integer, Primary Key, Auto-generated starting at 1000001)
- `firstName` (String, max 10 chars)
- `lastName` (String, max 20 chars)
- `dateOfBirth` (Date, format: yyyy-MM-dd)
- `houseName` (String, max 20 chars)
- `houseNumber` (String, max 4 chars)
- `postcode` (String, max 8 chars)
- `phoneHome` (String, max 20 chars)
- `phoneMobile` (String, max 20 chars)
- `emailAddress` (String, max 100 chars)

**Business Rules:**
- Customer number is system-generated and immutable
- Date of birth must be in the past
- At least one phone number (home or mobile) should be provided
- Email address should follow standard email format

#### 2.1.2 Policy (Parent Entity)
Abstract policy entity containing common attributes for all policy types.

**Attributes:**
- `policyNumber` (Integer, Primary Key, Auto-generated starting at 1000001)
- `customerNumber` (Integer, Foreign Key to Customer, NOT NULL)
- `issueDate` (Date, format: yyyy-MM-dd)
- `expiryDate` (Date, format: yyyy-MM-dd)
- `policyType` (Char, 1 character: 'M', 'E', 'H', 'P', 'C')
- `lastChanged` (Timestamp, Auto-updated on modifications)
- `brokerId` (Integer, nullable)
- `brokersReference` (String, max 10 chars, nullable)
- `payment` (Integer, nullable, represents payment amount in cents)
- `commission` (Short Integer, nullable)

**Business Rules:**
- Policy number is system-generated and immutable
- Issue date must be before or equal to expiry date
- Expiry date must be in the future for new policies
- Policy type determines which specialized policy table is used
- Deleting a customer cascades to delete all their policies
- Deleting a policy cascades to delete the specialized policy details

**Policy Type Codes:**
- `M` = Motor Insurance
- `E` = Endowment Insurance
- `H` = House Insurance
- `P` = Pet Insurance
- `C` = Commercial Property Insurance

#### 2.1.3 Motor Policy
Specialized policy for vehicle insurance.

**Attributes:**
- `policyNumber` (Integer, Primary Key, Foreign Key to Policy)
- `make` (String, max 15 chars) - Vehicle manufacturer
- `model` (String, max 15 chars) - Vehicle model
- `value` (Integer) - Vehicle value in currency units
- `regNumber` (String, max 7 chars) - Vehicle registration number
- `colour` (String, max 8 chars) - Vehicle color
- `cc` (Short Integer) - Engine cubic capacity
- `yearOfManufacture` (Date, format: yyyy-MM-dd)
- `premium` (Integer) - Premium amount in cents
- `accidents` (Integer) - Number of previous accidents

**Business Rules:**
- Registration number must be unique across all motor policies
- Year of manufacture must be in the past
- Premium calculation considers: vehicle value, cc, accidents, driver age

#### 2.1.4 Endowment Policy
Life insurance policy with investment component.

**Attributes:**
- `policyNumber` (Integer, Primary Key, Foreign Key to Policy)
- `equities` (Char, 1 char: 'Y' or 'N') - Investment in equities
- `withProfits` (Char, 1 char: 'Y' or 'N') - With-profits option
- `managedFund` (Char, 1 char: 'Y' or 'N') - Managed fund option
- `fundName` (String, max 10 chars) - Name of investment fund
- `term` (Short Integer) - Policy term in years
- `sumAssured` (Integer) - Sum assured amount in currency units
- `lifeAssured` (String, max 31 chars) - Name of person insured
- `paddingData` (String, max 32606 chars) - Reserved for future extensions

**Business Rules:**
- Term must be between 5 and 50 years
- At least one of: equities, withProfits, or managedFund must be 'Y'
- Life assured name is mandatory
- Sum assured must be positive

#### 2.1.5 House Policy
Property/home insurance policy.

**Attributes:**
- `policyNumber` (Integer, Primary Key, Foreign Key to Policy)
- `propertyType` (String, max 15 chars) - e.g., "Detached", "Semi-Detached", "Apartment"
- `bedrooms` (Short Integer) - Number of bedrooms
- `value` (Integer) - Property value in currency units
- `houseName` (String, max 20 chars) - Property name
- `houseNumber` (String, max 4 chars) - Property street number
- `postcode` (String, max 8 chars) - Property postcode

**Business Rules:**
- Property address (houseName + houseNumber + postcode) should be unique
- Number of bedrooms must be between 1 and 20
- Property value must be positive
- Premium calculation considers: property value, property type, location (postcode)

#### 2.1.6 Pet Policy
Pet insurance policy (newly added feature).

**Attributes:**
- `policyNumber` (Integer, Primary Key, Foreign Key to Policy)
- `petType` (String, max 15 chars) - e.g., "Dog", "Cat", "Rabbit"
- `petName` (String, max 20 chars) - Name of the pet
- `petBreed` (String, max 20 chars) - Breed of the pet
- `petAge` (Short Integer) - Age of pet in years
- `petValue` (Integer) - Estimated value of pet in currency units
- `veterinaryCoverage` (Integer) - Annual vet coverage limit in currency units
- `premium` (Integer) - Monthly premium in cents

**Business Rules:**
- Pet age must be between 0 and 30 years
- Pet name is mandatory
- Premium calculation considers: pet type, breed, age, and vet coverage amount
- Veterinary coverage must be positive

#### 2.1.7 Commercial Property Policy
Commercial/business property insurance with multiple peril coverage.

**Attributes:**
- `policyNumber` (Integer, Primary Key, Foreign Key to Policy)
- `requestDate` (Timestamp) - Date when policy was requested
- `startDate` (Date) - Policy start date
- `renewalDate` (Date) - Policy renewal date
- `address` (String, max 255 chars) - Commercial property address
- `zipcode` (String, max 8 chars) - Property zipcode/postcode
- `latitudeN` (String, max 11 chars) - GPS latitude coordinate
- `longitudeW` (String, max 11 chars) - GPS longitude coordinate
- `customer` (String, max 255 chars) - Business customer name
- `propertyType` (String, max 255 chars) - Type of commercial property
- `firePeril` (Short Integer) - Fire coverage indicator
- `firePremium` (Integer) - Fire coverage premium in cents
- `crimePeril` (Short Integer) - Crime coverage indicator
- `crimePremium` (Integer) - Crime coverage premium in cents
- `floodPeril` (Short Integer) - Flood coverage indicator
- `floodPremium` (Integer) - Flood coverage premium in cents
- `weatherPeril` (Short Integer) - Weather coverage indicator
- `weatherPremium` (Integer) - Weather coverage premium in cents
- `status` (Short Integer) - Policy status code
- `rejectionReason` (String, max 255 chars) - Reason if rejected

**Business Rules:**
- Start date must be before renewal date
- At least one peril coverage must be selected
- Total premium is sum of all peril premiums
- Status codes: 1=Pending, 2=Approved, 3=Rejected, 4=Active, 5=Expired
- Rejection reason is mandatory if status = 3 (Rejected)

#### 2.1.8 Claim (Optional Extension)
Insurance claim entity (present in schema for future extension).

**Attributes:**
- `claimNumber` (Integer, Primary Key, Auto-generated starting at 1000001)
- `policyNumber` (Integer, Foreign Key to Policy, NOT NULL)
- `claimDate` (Date) - Date when claim was filed
- `paid` (Integer) - Amount paid in cents
- `value` (Integer) - Claim value in cents
- `cause` (String, max 255 chars) - Cause of claim
- `observations` (String, max 255 chars) - Additional observations

**Business Rules:**
- Multiple claims can be associated with a single policy
- Claim date must be between policy issue date and expiry date
- Claim value must be positive
- Paid amount cannot exceed claim value

---

## 3. Functional Requirements

### 3.1 Customer Management

#### 3.1.1 Create Customer (FR-C-01)
**Description:** Add a new customer to the system.

**API Endpoint:** `POST /api/v1/customers`

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Smith",
  "dateOfBirth": "1985-06-15",
  "houseName": "Oak House",
  "houseNumber": "42",
  "postcode": "SW1A 1AA",
  "phoneHome": "020-1234-5678",
  "phoneMobile": "07700-900123",
  "emailAddress": "john.smith@email.com"
}
```

**Response (201 Created):**
```json
{
  "customerNumber": 1000012,
  "firstName": "John",
  "lastName": "Smith",
  "dateOfBirth": "1985-06-15",
  "houseName": "Oak House",
  "houseNumber": "42",
  "postcode": "SW1A 1AA",
  "phoneHome": "020-1234-5678",
  "phoneMobile": "07700-900123",
  "emailAddress": "john.smith@email.com",
  "_links": {
    "self": {"href": "/api/v1/customers/1000012"},
    "policies": {"href": "/api/v1/customers/1000012/policies"}
  }
}
```

**Validation Rules:**
- All required fields must be present
- Date of birth must be valid date and in the past
- Email must be valid format (if provided)
- Phone number format validation (at least one required)

**Error Responses:**
- `400 Bad Request` - Validation errors
- `409 Conflict` - Duplicate email address (if email uniqueness enforced)

#### 3.1.2 Get Customer by ID (FR-C-02)
**Description:** Retrieve customer details by customer number.

**API Endpoint:** `GET /api/v1/customers/{customerNumber}`

**Response (200 OK):**
```json
{
  "customerNumber": 1000012,
  "firstName": "John",
  "lastName": "Smith",
  "dateOfBirth": "1985-06-15",
  "houseName": "Oak House",
  "houseNumber": "42",
  "postcode": "SW1A 1AA",
  "phoneHome": "020-1234-5678",
  "phoneMobile": "07700-900123",
  "emailAddress": "john.smith@email.com",
  "numberOfPolicies": 3,
  "policies": [
    {
      "policyNumber": 1000045,
      "policyType": "M",
      "issueDate": "2024-01-15",
      "expiryDate": "2025-01-15"
    },
    {
      "policyNumber": 1000046,
      "policyType": "H",
      "issueDate": "2024-02-01",
      "expiryDate": "2025-02-01"
    }
  ],
  "_links": {
    "self": {"href": "/api/v1/customers/1000012"},
    "policies": {"href": "/api/v1/customers/1000012/policies"}
  }
}
```

**Error Responses:**
- `404 Not Found` - Customer number does not exist

#### 3.1.3 Update Customer (FR-C-03)
**Description:** Update existing customer details.

**API Endpoint:** `PUT /api/v1/customers/{customerNumber}`

**Request Body:** (Same structure as Create Customer)

**Response (200 OK):** Updated customer object

**Business Rules:**
- Customer number cannot be changed
- Partial updates supported via PATCH method

**Error Responses:**
- `400 Bad Request` - Validation errors
- `404 Not Found` - Customer number does not exist

#### 3.1.4 Delete Customer (FR-C-04)
**Description:** Delete a customer and all associated policies (cascade delete).

**API Endpoint:** `DELETE /api/v1/customers/{customerNumber}`

**Response (204 No Content):** Empty response body

**Business Rules:**
- Deleting a customer automatically deletes all associated policies
- Confirmation dialog required in UI before deletion
- Soft delete option for audit trail (recommended)

**Error Responses:**
- `404 Not Found` - Customer number does not exist
- `409 Conflict` - Customer has active claims (if claim feature enabled)

#### 3.1.5 Search Customers (FR-C-05)
**Description:** Search for customers by various criteria.

**API Endpoint:** `GET /api/v1/customers?lastName={lastName}&postcode={postcode}&page={page}&size={size}`

**Query Parameters:**
- `lastName` (optional) - Filter by last name (partial match)
- `firstName` (optional) - Filter by first name (partial match)
- `postcode` (optional) - Filter by postcode
- `emailAddress` (optional) - Filter by email address
- `page` (default: 0) - Page number for pagination
- `size` (default: 20) - Number of results per page
- `sort` (default: "customerNumber,asc") - Sort order

**Response (200 OK):**
```json
{
  "content": [
    {
      "customerNumber": 1000012,
      "firstName": "John",
      "lastName": "Smith",
      "emailAddress": "john.smith@email.com",
      "_links": {"self": {"href": "/api/v1/customers/1000012"}}
    }
  ],
  "page": {
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "number": 0
  }
}
```

### 3.2 Motor Policy Management

#### 3.2.1 Create Motor Policy (FR-MP-01)
**Description:** Create a new motor insurance policy for a customer.

**API Endpoint:** `POST /api/v1/policies/motor`

**Request Body:**
```json
{
  "customerNumber": 1000012,
  "issueDate": "2024-01-15",
  "expiryDate": "2025-01-15",
  "brokerId": 5001,
  "brokersReference": "BR-123",
  "payment": 120000,
  "commission": 150,
  "make": "Toyota",
  "model": "Camry",
  "value": 2500000,
  "regNumber": "ABC123",
  "colour": "Blue",
  "cc": 2500,
  "yearOfManufacture": "2020-01-01",
  "premium": 95000,
  "accidents": 0
}
```

**Response (201 Created):**
```json
{
  "policyNumber": 1000055,
  "policyType": "M",
  "customerNumber": 1000012,
  "issueDate": "2024-01-15",
  "expiryDate": "2025-01-15",
  "lastChanged": "2024-01-15T10:30:00Z",
  "brokerId": 5001,
  "brokersReference": "BR-123",
  "payment": 120000,
  "commission": 150,
  "motorDetails": {
    "make": "Toyota",
    "model": "Camry",
    "value": 2500000,
    "regNumber": "ABC123",
    "colour": "Blue",
    "cc": 2500,
    "yearOfManufacture": "2020-01-01",
    "premium": 95000,
    "accidents": 0
  },
  "_links": {
    "self": {"href": "/api/v1/policies/1000055"},
    "customer": {"href": "/api/v1/customers/1000012"}
  }
}
```

**Validation Rules:**
- Customer number must exist
- Registration number must be unique
- Issue date <= Expiry date
- Year of manufacture must be in the past
- All monetary values must be non-negative

**Error Responses:**
- `400 Bad Request` - Validation errors
- `404 Not Found` - Customer number does not exist
- `409 Conflict` - Duplicate registration number

#### 3.2.2 Get Motor Policy (FR-MP-02)
**Description:** Retrieve motor policy details by policy number.

**API Endpoint:** `GET /api/v1/policies/{policyNumber}`

**Response (200 OK):** Same structure as Create response

**Error Responses:**
- `404 Not Found` - Policy number does not exist

#### 3.2.3 Update Motor Policy (FR-MP-03)
**Description:** Update existing motor policy details.

**API Endpoint:** `PUT /api/v1/policies/{policyNumber}`

**Request Body:** Same structure as Create request

**Response (200 OK):** Updated policy object

**Business Rules:**
- Policy number and policy type cannot be changed
- Customer number cannot be changed
- lastChanged timestamp is automatically updated

#### 3.2.4 Delete Motor Policy (FR-MP-04)
**Description:** Delete a motor policy.

**API Endpoint:** `DELETE /api/v1/policies/{policyNumber}`

**Response (204 No Content):** Empty response body

**Business Rules:**
- Automatically removes associated motor details record (cascade)

### 3.3 Endowment Policy Management

#### 3.3.1 Create Endowment Policy (FR-EP-01)
**API Endpoint:** `POST /api/v1/policies/endowment`

**Request Body:**
```json
{
  "customerNumber": 1000012,
  "issueDate": "2024-01-01",
  "expiryDate": "2044-01-01",
  "brokerId": 5002,
  "payment": 50000,
  "equities": "Y",
  "withProfits": "Y",
  "managedFund": "N",
  "fundName": "GROWTH",
  "term": 20,
  "sumAssured": 500000,
  "lifeAssured": "John Smith"
}
```

**Response (201 Created):** Policy object with endowment details

**Validation Rules:**
- Term must be between 5 and 50 years
- At least one investment option (equities, withProfits, managedFund) must be 'Y'
- Life assured name is mandatory
- Sum assured must be positive

#### 3.3.2-3.3.4 Get/Update/Delete Endowment Policy
Similar patterns to Motor Policy with endowment-specific fields.

### 3.4 House Policy Management

#### 3.4.1 Create House Policy (FR-HP-01)
**API Endpoint:** `POST /api/v1/policies/house`

**Request Body:**
```json
{
  "customerNumber": 1000012,
  "issueDate": "2024-02-01",
  "expiryDate": "2025-02-01",
  "payment": 150000,
  "propertyType": "Detached",
  "bedrooms": 4,
  "value": 50000000,
  "houseName": "Oak House",
  "houseNumber": "42",
  "postcode": "SW1A 1AA"
}
```

**Response (201 Created):** Policy object with house details

**Validation Rules:**
- Property address should be unique (houseName + houseNumber + postcode)
- Bedrooms between 1 and 20
- Property value must be positive

#### 3.4.2-3.4.4 Get/Update/Delete House Policy
Similar patterns to Motor Policy with house-specific fields.

### 3.5 Pet Policy Management

#### 3.5.1 Create Pet Policy (FR-PP-01)
**API Endpoint:** `POST /api/v1/policies/pet`

**Request Body:**
```json
{
  "customerNumber": 1000012,
  "issueDate": "2024-03-01",
  "expiryDate": "2025-03-01",
  "payment": 45000,
  "petType": "Dog",
  "petName": "Buddy",
  "petBreed": "Golden Retriever",
  "petAge": 5,
  "petValue": 150000,
  "veterinaryCoverage": 200000,
  "premium": 45000
}
```

**Response (201 Created):** Policy object with pet details

**Validation Rules:**
- Pet age between 0 and 30 years
- Pet name is mandatory
- Veterinary coverage and premium must be positive

#### 3.5.2-3.5.4 Get/Update/Delete Pet Policy
Similar patterns to Motor Policy with pet-specific fields.

### 3.6 Commercial Property Policy Management

#### 3.6.1 Create Commercial Policy (FR-CP-01)
**API Endpoint:** `POST /api/v1/policies/commercial`

**Request Body:**
```json
{
  "customerNumber": 1000012,
  "issueDate": "2024-04-01",
  "expiryDate": "2025-04-01",
  "startDate": "2024-04-01",
  "renewalDate": "2025-04-01",
  "address": "123 Business Park, Industrial Estate",
  "zipcode": "M1 4BT",
  "latitudeN": "53.4808",
  "longitudeW": "-2.2426",
  "customer": "ABC Manufacturing Ltd",
  "propertyType": "Warehouse",
  "firePeril": 1,
  "firePremium": 250000,
  "crimePeril": 1,
  "crimePremium": 150000,
  "floodPeril": 0,
  "floodPremium": 0,
  "weatherPeril": 1,
  "weatherPremium": 100000,
  "status": 1
}
```

**Response (201 Created):** Policy object with commercial details

**Validation Rules:**
- At least one peril must be selected (peril value = 1)
- Total premium calculated as sum of all peril premiums
- Status codes: 1=Pending, 2=Approved, 3=Rejected, 4=Active, 5=Expired
- Rejection reason required if status = 3

#### 3.6.2-3.6.4 Get/Update/Delete Commercial Policy
Similar patterns to Motor Policy with commercial-specific fields.

### 3.7 Policy Search and Listing

#### 3.7.1 Get All Policies for Customer (FR-PS-01)
**API Endpoint:** `GET /api/v1/customers/{customerNumber}/policies`

**Response (200 OK):**
```json
{
  "customerNumber": 1000012,
  "policies": [
    {
      "policyNumber": 1000055,
      "policyType": "M",
      "issueDate": "2024-01-15",
      "expiryDate": "2025-01-15",
      "status": "Active"
    },
    {
      "policyNumber": 1000056,
      "policyType": "H",
      "issueDate": "2024-02-01",
      "expiryDate": "2025-02-01",
      "status": "Active"
    }
  ]
}
```

#### 3.7.2 Search Policies (FR-PS-02)
**API Endpoint:** `GET /api/v1/policies?type={type}&status={status}&customerNumber={customerNumber}`

**Query Parameters:**
- `type` - Filter by policy type (M, E, H, P, C)
- `status` - Filter by status (Active, Expired, Pending)
- `customerNumber` - Filter by customer
- `expiryFrom` - Filter policies expiring after date
- `expiryTo` - Filter policies expiring before date
- Pagination parameters

---

## 4. API Design Specification

### 4.1 RESTful API Principles
- Use HTTP methods appropriately (GET, POST, PUT, PATCH, DELETE)
- Return appropriate HTTP status codes
- Use resource-based URLs
- Support HATEOAS (Hypermedia as the Engine of Application State)
- Version the API (e.g., /api/v1/)

### 4.2 Standard Response Formats

#### Success Response Structure
```json
{
  "data": { },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "1.0"
  },
  "_links": { }
}
```

#### Error Response Structure
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Customer validation failed",
    "details": [
      {
        "field": "dateOfBirth",
        "message": "Date of birth must be in the past"
      }
    ]
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "requestId": "req-123456"
  }
}
```

### 4.3 HTTP Status Codes
- `200 OK` - Successful GET, PUT, PATCH
- `201 Created` - Successful POST
- `204 No Content` - Successful DELETE
- `400 Bad Request` - Validation errors
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Duplicate resource or business rule violation
- `500 Internal Server Error` - Server-side errors

### 4.4 API Endpoints Summary

#### Customer Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/customers` | Create customer |
| GET | `/api/v1/customers/{id}` | Get customer by ID |
| PUT | `/api/v1/customers/{id}` | Update customer |
| PATCH | `/api/v1/customers/{id}` | Partial update |
| DELETE | `/api/v1/customers/{id}` | Delete customer |
| GET | `/api/v1/customers` | Search customers |
| GET | `/api/v1/customers/{id}/policies` | Get customer's policies |

#### Policy Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/policies/motor` | Create motor policy |
| POST | `/api/v1/policies/endowment` | Create endowment policy |
| POST | `/api/v1/policies/house` | Create house policy |
| POST | `/api/v1/policies/pet` | Create pet policy |
| POST | `/api/v1/policies/commercial` | Create commercial policy |
| GET | `/api/v1/policies/{id}` | Get policy by ID |
| PUT | `/api/v1/policies/{id}` | Update policy |
| DELETE | `/api/v1/policies/{id}` | Delete policy |
| GET | `/api/v1/policies` | Search policies |
| GET | `/api/v1/policies/expiring` | Get expiring policies |

---

## 5. Technical Architecture

### 5.1 Architecture Overview
```
┌─────────────────────────────────────────────────────────────┐
│                        Front Door                           │
│                    (Global Load Balancer)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   Application Gateway                       │
│                  (WAF + Regional LB + SSL)                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              Kubernetes Service                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Ingress Controller (NGINX/App Gateway Ingress)        │ │
│  └────────────┬───────────────────────────────────────────┘ │
│               │                                              │
│  ┌────────────▼─────────────┐  ┌────────────────────────┐  │
│  │   Frontend Service       │  │   API Gateway Service  │  │
│  │   (React SPA)            │  │   (Spring Cloud GW)    │  │
│  │   - Nginx Container      │  │   - Rate Limiting      │  │
│  │   - Static Assets        │  │   - Authentication     │  │
│  └──────────────────────────┘  └──────┬─────────────────┘  │
│                                        │                     │
│  ┌─────────────────────────────────────▼──────────────────┐ │
│  │              Microservices Layer                        │ │
│  │  ┌──────────────────┐  ┌──────────────────┐            │ │
│  │  │ Customer Service │  │  Policy Service  │            │ │
│  │  │ (Spring Boot)    │  │  (Spring Boot)   │            │ │
│  │  │ - CRUD Ops       │  │  - CRUD Ops      │            │ │
│  │  │ - Validation     │  │  - 5 Policy Types│            │ │
│  │  └────────┬─────────┘  └────────┬─────────┘            │ │
│  │           │                      │                       │ │
│  │  ┌────────▼─────────────────────▼────────────────────┐ │ │
│  │  │         Shared Libraries & Common Utils           │ │ │
│  │  │    - Exception Handling  - DTOs  - Validators     │ │ │
│  │  └───────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────┬───────┬──────────────────────────────┘
                       │       │
         ┌─────────────▼───┐   └──────────────┐
         │                 │                   │
┌────────▼──────────┐ ┌────▼──────────┐ ┌─────▼──────────────┐
│ Relational DB     │ │ Redis         │ │ Message Broker     │
│ (PostgreSQL/MySQL)│ │ (Cache)       │ │ (Async Messaging)  │
│ - Customer Table  │ │ - Session     │ │ - Event Processing │
│ - Policy Tables   │ │ - API Cache   │ │ - Notifications    │
└───────────────────┘ └───────────────┘ └────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│            Observability & Management Layer                   │
│  ┌──────────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │ Prometheus       │  │ Tracing APM  │  │ Log Backend    │ │
│  │ (Metrics)        │  │ (OTel)       │  │ (Loki/ELK)     │ │
│  └──────────────────┘  └──────────────┘  └────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### 5.2 Microservices Design

#### 5.2.1 Customer Service
**Responsibilities:**
- Manage customer CRUD operations
- Customer search and filtering
- Customer validation
- Customer-to-policy relationship management

**Technology Stack:**
- Spring Boot 3.x
- Spring Data JPA
- Spring Web
- Spring Validation
- Lombok
- MapStruct (DTO mapping)

**Key Components:**
- `CustomerController` - REST endpoints
- `CustomerService` - Business logic
- `CustomerRepository` - Data access
- `CustomerDTO`, `CustomerEntity` - Data models
- `CustomerValidator` - Custom validation rules

#### 5.2.2 Policy Service
**Responsibilities:**
- Manage policy CRUD operations for all policy types
- Policy search and filtering
- Policy validation
- Policy expiry management
- Premium calculation

**Technology Stack:**
- Spring Boot 3.x
- Spring Data JPA
- Spring Web
- Spring Validation
- Strategy Pattern for policy type handling

**Key Components:**
- `PolicyController` - REST endpoints
- `MotorPolicyService`, `HousePolicyService`, etc. - Type-specific services
- `PolicyRepository`, `MotorPolicyRepository`, etc. - Data access
- `PolicyFactory` - Factory pattern for policy creation
- Policy DTOs and Entities for each type

### 5.3 Data Persistence Layer

#### 5.3.1 Database Selection
**Option 1: SQL Database (Recommended)**
- Fully managed SQL database
- Built-in high availability
- Automatic backups and point-in-time restore
- Elastic scaling
- Advanced security features

**Option 2: Database for PostgreSQL**
- Open-source alternative
- Compatible with PostgreSQL tools and extensions
- Flexible pricing tiers

#### 5.3.2 Database Schema
```sql
-- Customer Table
CREATE TABLE customer (
    customer_number INT PRIMARY KEY IDENTITY(1000001,1),
    first_name VARCHAR(10),
    last_name VARCHAR(20),
    date_of_birth DATE,
    house_name VARCHAR(20),
    house_number VARCHAR(4),
    postcode VARCHAR(8),
    phone_home VARCHAR(20),
    phone_mobile VARCHAR(20),
    email_address VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Policy Table (Parent)
CREATE TABLE policy (
    policy_number INT PRIMARY KEY IDENTITY(1000001,1),
    customer_number INT NOT NULL,
    issue_date DATE,
    expiry_date DATE,
    policy_type CHAR(1) NOT NULL,
    last_changed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    broker_id INT,
    brokers_reference VARCHAR(10),
    payment INT,
    commission SMALLINT,
    FOREIGN KEY (customer_number) REFERENCES customer(customer_number) 
        ON DELETE CASCADE,
    INDEX idx_customer (customer_number),
    INDEX idx_expiry (expiry_date),
    INDEX idx_type (policy_type)
);

-- Motor Table
CREATE TABLE motor (
    policy_number INT PRIMARY KEY,
    make VARCHAR(15),
    model VARCHAR(15),
    value INT,
    reg_number VARCHAR(7) UNIQUE,
    colour VARCHAR(8),
    cc SMALLINT,
    year_of_manufacture DATE,
    premium INT,
    accidents INT,
    FOREIGN KEY (policy_number) REFERENCES policy(policy_number) 
        ON DELETE CASCADE
);

-- Endowment Table
CREATE TABLE endowment (
    policy_number INT PRIMARY KEY,
    equities CHAR(1),
    with_profits CHAR(1),
    managed_fund CHAR(1),
    fund_name VARCHAR(10),
    term SMALLINT,
    sum_assured INT,
    life_assured VARCHAR(31),
    FOREIGN KEY (policy_number) REFERENCES policy(policy_number) 
        ON DELETE CASCADE
);

-- House Table
CREATE TABLE house (
    policy_number INT PRIMARY KEY,
    property_type VARCHAR(15),
    bedrooms SMALLINT,
    value INT,
    house_name VARCHAR(20),
    house_number VARCHAR(4),
    postcode VARCHAR(8),
    FOREIGN KEY (policy_number) REFERENCES policy(policy_number) 
        ON DELETE CASCADE,
    UNIQUE INDEX idx_address (house_name, house_number, postcode)
);

-- Pet Table
CREATE TABLE pet (
    policy_number INT PRIMARY KEY,
    pet_type VARCHAR(15),
    pet_name VARCHAR(20),
    pet_breed VARCHAR(20),
    pet_age SMALLINT,
    pet_value INT,
    veterinary_coverage INT,
    premium INT,
    FOREIGN KEY (policy_number) REFERENCES policy(policy_number) 
        ON DELETE CASCADE
);

-- Commercial Table
CREATE TABLE commercial (
    policy_number INT PRIMARY KEY,
    request_date TIMESTAMP,
    start_date DATE,
    renewal_date DATE,
    address VARCHAR(255),
    zipcode VARCHAR(8),
    latitude_n VARCHAR(11),
    longitude_w VARCHAR(11),
    customer VARCHAR(255),
    property_type VARCHAR(255),
    fire_peril SMALLINT,
    fire_premium INT,
    crime_peril SMALLINT,
    crime_premium INT,
    flood_peril SMALLINT,
    flood_premium INT,
    weather_peril SMALLINT,
    weather_premium INT,
    status SMALLINT,
    rejection_reason VARCHAR(255),
    FOREIGN KEY (policy_number) REFERENCES policy(policy_number) 
        ON DELETE CASCADE
);

-- Claim Table (Future Extension)
CREATE TABLE claim (
    claim_number INT PRIMARY KEY IDENTITY(1000001,1),
    policy_number INT NOT NULL,
    claim_date DATE,
    paid INT,
    value INT,
    cause VARCHAR(255),
    observations VARCHAR(255),
    FOREIGN KEY (policy_number) REFERENCES policy(policy_number) 
        ON DELETE CASCADE
);
```

#### 5.3.3 JPA Entity Mapping Example

```java
// Customer Entity
@Entity
@Table(name = "customer")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "customer_number")
    private Integer customerNumber;
    
    @Column(name = "first_name", length = 10)
    private String firstName;
    
    @Column(name = "last_name", length = 20)
    private String lastName;
    
    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;
    
    @Column(name = "house_name", length = 20)
    private String houseName;
    
    @Column(name = "house_number", length = 4)
    private String houseNumber;
    
    @Column(name = "postcode", length = 8)
    private String postcode;
    
    @Column(name = "phone_home", length = 20)
    private String phoneHome;
    
    @Column(name = "phone_mobile", length = 20)
    private String phoneMobile;
    
    @Column(name = "email_address", length = 100)
    private String emailAddress;
    
    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PolicyEntity> policies = new ArrayList<>();
    
    @Column(name = "created_at")
    @CreationTimestamp
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    @UpdateTimestamp
    private LocalDateTime updatedAt;
}

// Policy Entity (Parent)
@Entity
@Table(name = "policy")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Inheritance(strategy = InheritanceType.JOINED)
@DiscriminatorColumn(name = "policy_type", discriminatorType = DiscriminatorType.STRING)
public class PolicyEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "policy_number")
    private Integer policyNumber;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_number", nullable = false)
    private CustomerEntity customer;
    
    @Column(name = "issue_date")
    private LocalDate issueDate;
    
    @Column(name = "expiry_date")
    private LocalDate expiryDate;
    
    @Column(name = "policy_type", length = 1, insertable = false, updatable = false)
    private String policyType;
    
    @Column(name = "last_changed")
    @UpdateTimestamp
    private LocalDateTime lastChanged;
    
    @Column(name = "broker_id")
    private Integer brokerId;
    
    @Column(name = "brokers_reference", length = 10)
    private String brokersReference;
    
    @Column(name = "payment")
    private Integer payment;
    
    @Column(name = "commission")
    private Short commission;
}

// Motor Policy Entity
@Entity
@Table(name = "motor")
@Data
@EqualsAndHashCode(callSuper = true)
@DiscriminatorValue("M")
public class MotorPolicyEntity extends PolicyEntity {
    @Column(name = "make", length = 15)
    private String make;
    
    @Column(name = "model", length = 15)
    private String model;
    
    @Column(name = "value")
    private Integer value;
    
    @Column(name = "reg_number", length = 7, unique = true)
    private String regNumber;
    
    @Column(name = "colour", length = 8)
    private String colour;
    
    @Column(name = "cc")
    private Short cc;
    
    @Column(name = "year_of_manufacture")
    private LocalDate yearOfManufacture;
    
    @Column(name = "premium")
    private Integer premium;
    
    @Column(name = "accidents")
    private Integer accidents;
}
```

### 5.4 Caching Strategy

**Redis Cache Implementation:**
- Cache customer details (TTL: 1 hour)
- Cache policy summaries (TTL: 30 minutes)
- Cache search results (TTL: 5 minutes)
- Implement cache invalidation on updates/deletes

**Spring Cache Configuration:**
```java
@Configuration
@EnableCaching
public class CacheConfig {
    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofHours(1))
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()));
        
        return RedisCacheManager.builder(connectionFactory)
            .cacheDefaults(config)
            .withCacheConfiguration("customers", 
                config.entryTtl(Duration.ofHours(1)))
            .withCacheConfiguration("policies", 
                config.entryTtl(Duration.ofMinutes(30)))
            .build();
    }
}
```

### 5.5 API Gateway Configuration

**Spring Cloud Gateway Features:**
- Rate limiting (e.g., 100 requests per minute per user)
- JWT authentication and authorization
- Request/response logging
- Circuit breaker pattern (Resilience4j)
- Service discovery integration

**Example Gateway Configuration:**
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: customer-service
          uri: lb://customer-service
          predicates:
            - Path=/api/v1/customers/**
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 100
                redis-rate-limiter.burstCapacity: 200
            - name: CircuitBreaker
              args:
                name: customerServiceBreaker
                fallbackUri: forward:/fallback/customers
                
        - id: policy-service
          uri: lb://policy-service
          predicates:
            - Path=/api/v1/policies/**
          filters:
            - name: RequestRateLimiter
            - name: CircuitBreaker
```

---

## 6. Security Requirements

### 6.1 Authentication & Authorization

**Authentication Strategy: OAuth 2.0 / JWT**
- Use Active Directory (AD) for authentication
- Implement JWT tokens for stateless authentication
- Token expiration: 1 hour (access token), 7 days (refresh token)

**Authorization Levels:**
1. **Customer User**: Can view own customer and policy details
2. **Agent**: Can create, read, and update customers and policies
3. **Administrator**: Full access including delete operations
4. **System**: Internal service-to-service communication

**Spring Security Configuration:**
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/customers/**").hasAnyRole("AGENT", "ADMIN")
                .requestMatchers("/api/v1/policies/**").hasAnyRole("AGENT", "ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.decoder(jwtDecoder()))
            );
        return http.build();
    }
}
```

### 6.2 Data Protection
- **Encryption at Rest**: Enable Transparent Data Encryption (TDE) on SQL
- **Encryption in Transit**: TLS 1.2+ for all API communications
- **PII Protection**: Mask sensitive fields in logs and error messages
- **Field-Level Encryption**: Consider encrypting email addresses and phone numbers

### 6.3 API Security
- **CORS Configuration**: Restrict to known frontend domains
- **Rate Limiting**: Implement per-user and per-IP rate limits
- **Input Validation**: Validate and sanitize all inputs
- **SQL Injection Prevention**: Use parameterized queries (JPA handles this)
- **XSS Prevention**: Encode outputs in frontend

### 6.4 Audit Logging
- Log all create, update, and delete operations
- Include user ID, timestamp, IP address, and operation details
- Store audit logs in centralized log storage (Loki, ELK, OpenSearch, or SIEM)
- Retention period: 7 years (compliance requirement)

---

## 7. User Interface Requirements

### 7.1 Frontend Technology Stack
- **Framework**: React 18+ with TypeScript
- **State Management**: React Query + Context API
- **UI Component Library**: Material-UI (MUI) or Ant Design
- **Form Management**: React Hook Form + Zod validation
- **Routing**: React Router v6
- **HTTP Client**: Axios with interceptors
- **Build Tool**: Vite or Create React App

### 7.2 Key UI Screens

#### 7.2.1 Dashboard
**Purpose:** Landing page showing key metrics and quick actions

**Features:**
- Total number of customers
- Total number of active policies by type (pie chart)
- Policies expiring in next 30 days (alert list)
- Recent customer additions
- Quick search bar for customers and policies

#### 7.2.2 Customer Management Screen
**Purpose:** Search, view, create, and edit customers

**Features:**
- Search bar with filters (name, postcode, email)
- Customer list table with pagination
- Click to view customer details
- "Add New Customer" button
- Edit customer form (modal or side panel)
- Delete customer with confirmation dialog
- View all policies for selected customer

**Form Fields:**
- First Name (required, max 10 chars)
- Last Name (required, max 20 chars)
- Date of Birth (required, date picker, must be past date)
- House Name (optional, max 20 chars)
- House Number (optional, max 4 chars)
- Postcode (required, max 8 chars)
- Home Phone (optional, max 20 chars, format validation)
- Mobile Phone (optional, max 20 chars, format validation)
- Email Address (optional, max 100 chars, email validation)

**Validation Messages:**
- Real-time validation with error messages under each field
- Form-level validation before submit
- Backend error display

#### 7.2.3 Motor Policy Management Screen
**Purpose:** Create and manage motor insurance policies

**Features:**
- Policy type selector (tabs for M, E, H, P, C)
- Search existing policies
- "Create New Policy" button
- Policy form with sections: Common Details + Motor Specific Details

**Form Sections:**

*Common Policy Details:*
- Customer Number (required, autocomplete dropdown)
- Policy Number (auto-generated, read-only for updates)
- Issue Date (required, date picker)
- Expiry Date (required, date picker, must be after issue date)
- Broker ID (optional, numeric)
- Broker's Reference (optional, max 10 chars)
- Payment (optional, currency input)
- Commission (optional, percentage input)

*Motor Specific Details:*
- Make (required, max 15 chars, dropdown with common makes)
- Model (required, max 15 chars)
- Value (required, currency input)
- Registration Number (required, max 7 chars, uppercase, unique)
- Colour (required, max 8 chars, dropdown)
- CC (required, numeric, 0-10000)
- Year of Manufacture (required, year picker, must be past)
- Premium (required, currency input, auto-calculate button)
- Accidents (optional, numeric, default 0)

**Premium Calculator:**
- Button "Calculate Premium"
- Modal with calculation breakdown
- Factors: vehicle value, CC, accidents, driver age (from customer DOB)
- Display formula and result

#### 7.2.4 Endowment Policy Screen
Similar structure to Motor Policy but with endowment-specific fields:
- Equities (Yes/No toggle)
- With Profits (Yes/No toggle)
- Managed Fund (Yes/No toggle)
- Fund Name (dropdown, max 10 chars)
- Term (numeric, 5-50 years)
- Sum Assured (currency input)
- Life Assured (text input, max 31 chars)

#### 7.2.5 House Policy Screen
House-specific fields:
- Property Type (dropdown: Detached, Semi-Detached, Apartment, etc.)
- Bedrooms (numeric, 1-20)
- Value (currency input)
- House Name (max 20 chars)
- House Number (max 4 chars)
- Postcode (max 8 chars)

#### 7.2.6 Pet Policy Screen
Pet-specific fields:
- Pet Type (dropdown: Dog, Cat, Rabbit, etc.)
- Pet Name (required, max 20 chars)
- Pet Breed (required, max 20 chars)
- Pet Age (numeric, 0-30 years)
- Pet Value (currency input)
- Veterinary Coverage (currency input)
- Premium (currency input)

#### 7.2.7 Commercial Property Policy Screen
Commercial-specific fields:
- Address (textarea, max 255 chars)
- Zipcode (max 8 chars)
- Coordinates (optional, latitude/longitude inputs or map picker)
- Customer Business Name (max 255 chars)
- Property Type (max 255 chars)
- Four peril sections (Fire, Crime, Flood, Weather):
  - Peril checkbox
  - Premium input (if checked)
- Status dropdown (Pending, Approved, Rejected, Active, Expired)
- Rejection Reason (required if status = Rejected)

#### 7.2.8 Policy List/Search Screen
**Features:**
- Filter by policy type (tabs or dropdown)
- Filter by customer number
- Filter by expiry date range
- Search by policy number
- Table showing all matching policies
- Pagination controls
- Export to CSV button

#### 7.2.9 Reports Screen
**Features:**
- Expiring Policies Report (next 30, 60, 90 days)
- Policies by Type (pie chart + table)
- Premium Revenue by Policy Type (bar chart)
- Recent Customers Report
- Customer Count by Postcode (geographic distribution)

### 7.3 Responsive Design
- Mobile-first approach
- Breakpoints: 320px (mobile), 768px (tablet), 1024px (desktop)
- Touch-friendly UI elements (min 44px tap targets)
- Collapsible sidebar navigation on mobile

### 7.4 Accessibility (WCAG 2.1 AA Compliance)
- Semantic HTML
- Proper heading hierarchy
- Label all form inputs
- Keyboard navigation support (tab order, focus indicators)
- ARIA attributes where needed
- Color contrast ratio minimum 4.5:1
- Error messages associated with form fields
- Screen reader compatibility

### 7.5 Internationalization (Future)
- Support for multiple languages (English, Welsh, Scottish Gaelic)
- Date format localization
- Currency symbol localization
- Prepare string externalization

---

## 8. Kubernetes Service Deployment

### 8.1 Cluster Configuration

**Cluster Specifications:**
- **Node Pool**: Standard_D4s_v3 or higher (4 vCPUs, 16 GB RAM)
- **Node Count**: 3 nodes minimum (for high availability)
- **Auto-scaling**: Enable cluster autoscaler (min: 3, max: 10)
- **Kubernetes Version**: 1.28+ (latest stable)
- **Network Plugin**: CNI (for better performance)
- **Network Policy**: Calico

**Node Pool Strategy:**
- System Node Pool: 2 nodes (Kubernetes system services)
- Application Node Pool: 3+ nodes (auto-scaling)

### 8.2 Container Images

**Image Registry:** Container Registry (CR)

**Application Images:**
1. `genapp/customer-service:latest`
2. `genapp/policy-service:latest`
3. `genapp/api-gateway:latest`
4. `genapp/frontend:latest`

**Base Image:** `eclipse-temurin:17-jre-alpine` (for Java services)

**Dockerfile Example (Customer Service):**
```dockerfile
FROM eclipse-temurin:17-jre-alpine AS builder
WORKDIR /app
COPY target/customer-service-0.0.1-SNAPSHOT.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract

FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
WORKDIR /app
COPY --from=builder app/dependencies/ ./
COPY --from=builder app/spring-boot-loader/ ./
COPY --from=builder app/snapshot-dependencies/ ./
COPY --from=builder app/application/ ./

EXPOSE 8080
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
```

### 8.3 Kubernetes Manifests

#### 8.3.1 Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: genapp
```

#### 8.3.2 ConfigMap (Application Configuration)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: customer-service-config
  namespace: genapp
data:
  application.yaml: |
    spring:
      application:
        name: customer-service
      datasource:
        url: jdbc:postgresql://genapp-db.postgres.database.com:5432/genapp
        driver-class-name: org.postgresql.Driver
      jpa:
        hibernate:
          ddl-auto: validate
        show-sql: false
      cache:
        type: redis
      redis:
        host: genapp-redis.redis.cache.windows.net
        port: 6380
        ssl: true
    server:
      port: 8080
    management:
      endpoints:
        web:
          exposure:
            include: health,info,metrics,prometheus
      metrics:
        export:
          prometheus:
            enabled: true
```

#### 8.3.3 Secret (Database Credentials)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: genapp
type: Opaque
stringData:
  username: genapp_user
  password: <SECURE_PASSWORD>
  jdbc-url: jdbc:postgresql://genapp-db.postgres.database.com:5432/genapp
```

#### 8.3.4 Deployment (Customer Service)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: customer-service
  namespace: genapp
  labels:
    app: customer-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: customer-service
  template:
    metadata:
      labels:
        app: customer-service
        version: v1
    spec:
      containers:
      - name: customer-service
        image: genappacr.cr.io/customer-service:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        - name: JAVA_OPTS
          value: "-Xms512m -Xmx1024m -XX:+UseG1GC"
        volumeMounts:
        - name: config
          mountPath: /config
          readOnly: true
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
      volumes:
      - name: config
        configMap:
          name: customer-service-config
---
apiVersion: v1
kind: Service
metadata:
  name: customer-service
  namespace: genapp
  labels:
    app: customer-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: customer-service
```

#### 8.3.5 Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: customer-service-hpa
  namespace: genapp
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: customer-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 2
        periodSeconds: 60
```

#### 8.3.6 Ingress (NGINX Ingress Controller)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: genapp-ingress
  namespace: genapp
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - api.genapp.example.com
    secretName: genapp-tls-cert
  rules:
  - host: api.genapp.example.com
    http:
      paths:
      - path: /api/v1/customers
        pathType: Prefix
        backend:
          service:
            name: customer-service
            port:
              number: 80
      - path: /api/v1/policies
        pathType: Prefix
        backend:
          service:
            name: policy-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### 8.4 CI/CD Pipeline (Jenkins, GitHub Actions, or GitLab CI)

**GitHub Actions Workflow Example:**
```yaml
name: Build and Deploy to Kubernetes

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY_URL: registry.example.com/genapp
  K8S_NAMESPACE: genapp

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
        cache: maven
    
    - name: Build with Maven
      run: mvn clean package -DskipTests
    
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: registry.example.com
        username: ${{ secrets.REGISTRY_USERNAME }}
        password: ${{ secrets.REGISTRY_PASSWORD }}
    
    - name: Build and Push Customer Service Image
      run: |
        docker build -t ${{ env.REGISTRY_URL }}/customer-service:${{ github.sha }} \
          -f customer-service/Dockerfile customer-service/
        docker push ${{ env.REGISTRY_URL }}/customer-service:${{ github.sha }}
    
    - name: Build and Push Policy Service Image
      run: |
        docker build -t ${{ env.REGISTRY_URL }}/policy-service:${{ github.sha }} \
          -f policy-service/Dockerfile policy-service/
        docker push ${{ env.REGISTRY_URL }}/policy-service:${{ github.sha }}
  
  deploy-to-kubernetes:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl context
      run: |
        echo "${{ secrets.KUBE_CONFIG_DATA }}" | base64 --decode > "$HOME/.kube/config"
    
    - name: Deploy to Kubernetes
      run: |
        kubectl apply -f k8s/namespace.yaml
        kubectl apply -f k8s/configmaps/
        kubectl apply -f k8s/secrets/
        kubectl set image deployment/customer-service \
          customer-service=${{ env.REGISTRY_URL }}/customer-service:${{ github.sha }} \
          -n ${{ env.K8S_NAMESPACE }}
        kubectl set image deployment/policy-service \
          policy-service=${{ env.REGISTRY_URL }}/policy-service:${{ github.sha }} \
          -n ${{ env.K8S_NAMESPACE }}
        kubectl rollout status deployment/customer-service -n ${{ env.K8S_NAMESPACE }}
        kubectl rollout status deployment/policy-service -n ${{ env.K8S_NAMESPACE }}
```

### 8.5 Platform Services Integration

#### 8.5.1 Relational Database (PostgreSQL / MySQL / SQL Server)
**Configuration:**
- Service Tier: General Purpose (4 vCores, 20 GB storage)
- Backup Retention: 7 days
- Geo-Replication: Enabled (secondary region)
- Network Policy: Allow only application namespace ingress
- Connection Pooling: HikariCP (max pool size: 20)

**Spring Boot Configuration:**
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 20000
      idle-timeout: 300000
      max-lifetime: 1200000
```

#### 8.5.2 Redis Cache
**Configuration:**
- Tier: Premium (for data persistence and clustering)
- Size: P1 (6 GB cache)
- Clustering: Disabled (single instance sufficient initially)
- Data Persistence: RDB snapshot every 15 minutes
- Network Policy: Allow only application namespace ingress

#### 8.5.3 OpenTelemetry-Compatible Observability Backend
**Configuration:**
- Enable distributed tracing
- Custom metrics for business KPIs
- Failure anomaly detection
- Smart detection alerts

**Spring Boot Integration:**
```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
```

```yaml
management:
  tracing:
    enabled: true
    sampling:
      probability: 1.0
```

#### 8.5.4 External Secrets Manager
**Purpose:** Store sensitive configuration (database passwords, API keys)

**Integration with Kubernetes:**
- Use workload identity federation (OIDC)
- Mount secrets as Kubernetes secrets
- Rotate secrets automatically

---

## 9. Observability & Monitoring

### 9.1 Logging Strategy

**Logging Levels:**
- **ERROR**: Application errors requiring immediate attention
- **WARN**: Potential issues or deprecated functionality
- **INFO**: Important business events (customer created, policy added)
- **DEBUG**: Detailed debugging information (disabled in production)

**Structured Logging Format (JSON):**
```json
{
  "timestamp": "2024-01-15T10:30:00.123Z",
  "level": "INFO",
  "service": "customer-service",
  "traceId": "abc123",
  "spanId": "xyz789",
  "message": "Customer created successfully",
  "customerId": 1000012,
  "userId": "agent@genapp.com"
}
```

**Centralized Logging:**
- **Tool**: EFK/Loki/OpenSearch stack
- **Retention**: 90 days
- **Log Queries**: LogQL/SQL DSL (tool-dependent)

**Logback Configuration:**
```xml
<appender name="CONSOLE-JSON" class="ch.qos.logback.core.ConsoleAppender">
    <encoder class="net.logstash.logback.encoder.LogstashEncoder">
        <customFields>
            {"service":"${spring.application.name}"}
        </customFields>
    </encoder>
</appender>
```

### 9.2 Metrics & KPIs

**Infrastructure Metrics:**
- CPU usage per pod
- Memory usage per pod
- Request rate (requests per second)
- Response time (p50, p95, p99)
- Error rate (4xx, 5xx)
- Pod restart count

**Business Metrics:**
- Number of customers created per hour
- Number of policies created per hour (by type)
- Number of policies expiring in next 30 days
- Average policy premium by type
- Customer acquisition rate

**Custom Metrics (Micrometer):**
```java
@Component
public class CustomerMetrics {
    private final Counter customerCreatedCounter;
    private final Timer customerQueryTimer;
    
    public CustomerMetrics(MeterRegistry registry) {
        this.customerCreatedCounter = Counter.builder("customers.created")
            .description("Total number of customers created")
            .tag("service", "customer-service")
            .register(registry);
            
        this.customerQueryTimer = Timer.builder("customers.query.time")
            .description("Time to query customer by ID")
            .register(registry);
    }
    
    public void incrementCustomerCreated() {
        customerCreatedCounter.increment();
    }
    
    public void recordQueryTime(long duration) {
        customerQueryTimer.record(duration, TimeUnit.MILLISECONDS);
    }
}
```

### 9.3 Distributed Tracing

**Tool**: OpenTelemetry Collector + tracing backend (Jaeger, Tempo, or vendor APM)

**Trace Propagation:**
- Use W3C Trace Context standard
- Propagate trace ID and span ID across service calls
- Capture HTTP headers, database queries, external API calls

**Spring Cloud Sleuth Configuration:**
```yaml
spring:
  sleuth:
    sampler:
      probability: 1.0  # Sample 100% of traces (adjust in production)
    baggage:
      remote-fields:
        - userId
        - tenantId
```

### 9.4 Health Checks

**Liveness Probe:** Checks if application is alive
- Endpoint: `/actuator/health/liveness`
- Failure Action: Restart pod

**Readiness Probe:** Checks if application can serve traffic
- Endpoint: `/actuator/health/readiness`
- Checks: Database connection, Redis connection
- Failure Action: Remove from load balancer

**Custom Health Indicator:**
```java
@Component
public class DatabaseHealthIndicator implements HealthIndicator {
    @Autowired
    private DataSource dataSource;
    
    @Override
    public Health health() {
        try (Connection conn = dataSource.getConnection()) {
            if (conn.isValid(5)) {
                return Health.up()
                    .withDetail("database", "Available")
                    .build();
            }
        } catch (Exception e) {
            return Health.down()
                .withDetail("database", "Unavailable")
                .withException(e)
                .build();
        }
        return Health.down().build();
    }
}
```

### 9.5 Alerting

**Alert Rules (Prometheus Alertmanager or equivalent):**
1. **High Error Rate**: > 5% of requests return 5xx status
   - Severity: Critical
   - Action: Page on-call engineer
   
2. **High Response Time**: p95 response time > 2 seconds
   - Severity: Warning
   - Action: Send email to team
   
3. **Pod Crash Loop**: Pod restarting > 3 times in 10 minutes
   - Severity: Critical
   - Action: Page on-call engineer
   
4. **Database Connection Failure**: Cannot connect to database
   - Severity: Critical
   - Action: Page on-call engineer + DBA

5. **Policies Expiring Soon**: > 100 policies expiring in next 7 days
   - Severity: Informational
   - Action: Send daily email to business team

**Alert Channels:**
- Email
- SMS
- Microsoft Teams webhook
- PagerDuty integration

---

## 10. Testing Strategy

### 10.1 Unit Testing

**Framework**: JUnit 5 + Mockito

**Coverage Target**: > 80% code coverage

**Example Test:**
```java
@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {
    @Mock
    private CustomerRepository customerRepository;
    
    @InjectMocks
    private CustomerService customerService;
    
    @Test
    void testCreateCustomer_Success() {
        // Given
        CustomerDTO customerDTO = new CustomerDTO();
        customerDTO.setFirstName("John");
        customerDTO.setLastName("Smith");
        customerDTO.setDateOfBirth(LocalDate.of(1985, 6, 15));
        
        CustomerEntity savedEntity = new CustomerEntity();
        savedEntity.setCustomerNumber(1000012);
        
        when(customerRepository.save(any(CustomerEntity.class)))
            .thenReturn(savedEntity);
        
        // When
        CustomerDTO result = customerService.createCustomer(customerDTO);
        
        // Then
        assertNotNull(result);
        assertEquals(1000012, result.getCustomerNumber());
        verify(customerRepository, times(1)).save(any(CustomerEntity.class));
    }
    
    @Test
    void testCreateCustomer_InvalidDateOfBirth_ThrowsException() {
        // Given
        CustomerDTO customerDTO = new CustomerDTO();
        customerDTO.setDateOfBirth(LocalDate.now().plusDays(1)); // Future date
        
        // When & Then
        assertThrows(ValidationException.class, 
            () -> customerService.createCustomer(customerDTO));
    }
}
```

### 10.2 Integration Testing

**Framework**: Spring Boot Test + Testcontainers

**Example Test:**
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class CustomerIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");
    
    @Autowired
    private TestRestTemplate restTemplate;
    
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
    
    @Test
    void testCreateAndRetrieveCustomer() {
        // Create customer
        CustomerDTO createRequest = new CustomerDTO();
        createRequest.setFirstName("John");
        createRequest.setLastName("Smith");
        createRequest.setDateOfBirth(LocalDate.of(1985, 6, 15));
        createRequest.setPostcode("SW1A 1AA");
        
        ResponseEntity<CustomerDTO> createResponse = restTemplate.postForEntity(
            "/api/v1/customers", 
            createRequest, 
            CustomerDTO.class
        );
        
        assertEquals(HttpStatus.CREATED, createResponse.getStatusCode());
        assertNotNull(createResponse.getBody());
        Integer customerId = createResponse.getBody().getCustomerNumber();
        
        // Retrieve customer
        ResponseEntity<CustomerDTO> getResponse = restTemplate.getForEntity(
            "/api/v1/customers/" + customerId,
            CustomerDTO.class
        );
        
        assertEquals(HttpStatus.OK, getResponse.getStatusCode());
        assertEquals("John", getResponse.getBody().getFirstName());
    }
}
```

### 10.3 Contract Testing

**Framework**: Spring Cloud Contract

**Purpose**: Ensure API contracts are maintained between services

### 10.4 Performance Testing

**Tool**: Apache JMeter or Gatling

**Test Scenarios:**
1. **Load Test**: 100 concurrent users, 1000 requests per minute
2. **Stress Test**: Gradually increase load until system breaks
3. **Endurance Test**: Sustained load for 2 hours
4. **Spike Test**: Sudden burst of 500 concurrent users

**Performance Acceptance Criteria:**
- Response time p95 < 2 seconds
- Throughput > 500 requests per second
- Error rate < 1%

### 10.5 Security Testing

**Tools**: OWASP ZAP, SonarQube

**Tests:**
- SQL injection attempts
- XSS attempts
- Authentication bypass attempts
- Excessive data exposure
- Dependency vulnerability scan

---

## 11. Data Migration Strategy

### 11.1 Migration from VSAM + Db2 to Relational Database on Kubernetes

**Approach:** Phased Migration with Dual-Write Pattern

**Phase 1: Setup Target Database**
1. Provision target relational database (PostgreSQL/MySQL/SQL Server)
2. Execute DDL scripts to create tables
3. Configure indexes and constraints
4. Set up database users and permissions

**Phase 2: Initial Data Load**
1. Export customer data from Db2 to CSV
2. Transform data format (EBCDIC → UTF-8, date formats)
3. Load data into target database using BULK INSERT/psql/mysql client/ETL pipeline
4. Verify row counts and data integrity

**Phase 3: Incremental Sync**
1. Implement Change Data Capture (CDC) on source Db2
2. Use a scheduler or ETL tool to sync changes periodically
3. Validate data consistency

**Phase 4: Cutover**
1. Stop COBOL application writes
2. Perform final sync
3. Validate all data
4. Point Java application to target relational database
5. Monitor for issues

**Rollback Plan:**
- Keep Db2 database intact for 30 days
- Ability to revert Java app to read from Db2

### 11.2 Data Validation

**Automated Validation Scripts:**
```sql
-- Compare row counts
SELECT 'Customer' AS table_name, COUNT(*) AS row_count FROM customer
UNION
SELECT 'Policy', COUNT(*) FROM policy
UNION
SELECT 'Motor', COUNT(*) FROM motor;

-- Validate referential integrity
SELECT p.policy_number, p.customer_number
FROM policy p
LEFT JOIN customer c ON p.customer_number = c.customer_number
WHERE c.customer_number IS NULL;
```

**Data Quality Checks:**
- No NULL values in required fields
- Date ranges are valid (issue_date <= expiry_date)
- Foreign key relationships intact
- Unique constraints satisfied

---

## 12. Non-Functional Requirements

### 12.1 Performance
- **Response Time**: p95 < 2 seconds for all API calls
- **Throughput**: Support 500 requests per second
- **Database Query Time**: < 500ms for 95% of queries
- **Page Load Time**: < 3 seconds for frontend pages

### 12.2 Scalability
- **Horizontal Scaling**: Auto-scale pods based on CPU/memory
- **Database Scaling**: Support up to 10 million customer records
- **Concurrent Users**: Support 1000 concurrent users

### 12.3 Availability
- **Uptime SLA**: 99.9% (8.76 hours downtime per year)
- **Disaster Recovery**: RTO < 1 hour, RPO < 15 minutes
- **Multi-Region**: Deploy to secondary region for disaster recovery

### 12.4 Data Retention
- **Customer Records**: Retain indefinitely (unless GDPR delete request)
- **Policy Records**: Retain for 7 years after expiry (regulatory requirement)
- **Audit Logs**: Retain for 7 years
- **Application Logs**: Retain for 90 days

### 12.5 Compliance
- **GDPR**: Right to access, right to be forgotten, data portability
- **PCI DSS**: If payment data is stored (future extension)
- **SOC 2**: Security controls and audit trail

---

## 13. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)
- [ ] Provision Kubernetes cluster and namespaces
- [ ] Provision target relational database
- [ ] Set up container registry
- [ ] Create Java project structure (Maven multi-module)
- [ ] Implement Customer Service (CRUD operations)
- [ ] Write unit tests for Customer Service
- [ ] Create Dockerfiles and Kubernetes manifests
- [ ] Deploy Customer Service to Kubernetes

### Phase 2: Core Functionality (Weeks 5-8)
- [ ] Implement Policy Service (all 5 policy types)
- [ ] Implement API Gateway with Spring Cloud Gateway
- [ ] Add authentication and authorization (OIDC/OAuth2)
- [ ] Implement caching with Redis
- [ ] Write integration tests
- [ ] Deploy all services to Kubernetes

### Phase 3: Frontend (Weeks 9-12)
- [ ] Create React application structure
- [ ] Implement Customer Management UI
- [ ] Implement Policy Management UI (all types)
- [ ] Implement Dashboard and Reports
- [ ] Add form validation and error handling
- [ ] Deploy frontend to Kubernetes

### Phase 4: Observability & DevOps (Weeks 13-14)
- [ ] Set up OpenTelemetry collector and tracing backend
- [ ] Configure logging and monitoring
- [ ] Create CI/CD pipelines (GitHub Actions)
- [ ] Set up health checks and probes
- [ ] Configure alerts and dashboards

### Phase 5: Testing & Migration (Weeks 15-16)
- [ ] Performance testing with JMeter
- [ ] Security testing with OWASP ZAP
- [ ] Data migration from legacy system
- [ ] User acceptance testing
- [ ] Create deployment runbook

### Phase 6: Go-Live (Week 17-18)
- [ ] Final production deployment
- [ ] Smoke testing in production
- [ ] Monitor system for issues
- [ ] Hypercare support
- [ ] Post-deployment retrospective

---

## 14. Success Criteria

### 14.1 Technical Success Criteria
- [ ] All API endpoints functional with < 2s response time
- [ ] 99.9% uptime SLA achieved
- [ ] Zero critical security vulnerabilities
- [ ] Unit test coverage > 80%
- [ ] All user acceptance tests passed

### 14.2 Business Success Criteria
- [ ] All 5 policy types fully supported
- [ ] Customer and policy search working correctly
- [ ] Data migration completed with 100% accuracy
- [ ] User training completed
- [ ] Legacy COBOL system decommissioned

### 14.3 User Experience Criteria
- [ ] Users can create customer in < 2 minutes
- [ ] Users can create policy in < 3 minutes
- [ ] UI is intuitive and requires minimal training
- [ ] Mobile-responsive design works on all devices

---

## 15. Glossary

| Term | Definition |
|------|------------|
| **K8s** | Kubernetes - Container orchestration platform |
| **BMS** | Basic Mapping Support - Mainframe screen definition language |
| **CICS** | Customer Information Control System - IBM mainframe transaction server |
| **COBOL** | Common Business-Oriented Language - Legacy programming language |
| **DTO** | Data Transfer Object - Object used to transfer data between layers |
| **HATEOAS** | Hypermedia as the Engine of Application State - REST principle |
| **JPA** | Java Persistence API - Java ORM specification |
| **JWT** | JSON Web Token - Stateless authentication token format |
| **KPI** | Key Performance Indicator - Measurable business metric |
| **RBAC** | Role-Based Access Control - Authorization model |
| **SLA** | Service Level Agreement - Uptime and performance guarantee |
| **TLS** | Transport Layer Security - Encryption protocol |
| **VSAM** | Virtual Storage Access Method - Mainframe file system |

---

## 16. Appendix

### 16.1 Sample API Request/Response

**Create Motor Policy - Full Example:**

Request:
```bash
curl -X POST https://api.genapp.example.com/api/v1/policies/motor \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIs..." \
  -d '{
    "customerNumber": 1000012,
    "issueDate": "2024-01-15",
    "expiryDate": "2025-01-15",
    "payment": 120000,
    "make": "Toyota",
    "model": "Camry",
    "value": 2500000,
    "regNumber": "ABC123",
    "colour": "Blue",
    "cc": 2500,
    "yearOfManufacture": "2020-01-01",
    "premium": 95000,
    "accidents": 0
  }'
```

Response:
```json
{
  "policyNumber": 1000055,
  "policyType": "M",
  "customerNumber": 1000012,
  "customer": {
    "customerNumber": 1000012,
    "firstName": "John",
    "lastName": "Smith",
    "_links": {
      "self": {"href": "/api/v1/customers/1000012"}
    }
  },
  "issueDate": "2024-01-15",
  "expiryDate": "2025-01-15",
  "lastChanged": "2024-01-15T10:30:00.123Z",
  "brokerId": null,
  "brokersReference": null,
  "payment": 120000,
  "commission": null,
  "motorDetails": {
    "make": "Toyota",
    "model": "Camry",
    "value": 2500000,
    "regNumber": "ABC123",
    "colour": "Blue",
    "cc": 2500,
    "yearOfManufacture": "2020-01-01",
    "premium": 95000,
    "accidents": 0
  },
  "_links": {
    "self": {"href": "/api/v1/policies/1000055"},
    "customer": {"href": "/api/v1/customers/1000012"},
    "update": {"href": "/api/v1/policies/1000055"},
    "delete": {"href": "/api/v1/policies/1000055"}
  }
}
```

### 16.2 Error Response Example

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Policy validation failed",
    "details": [
      {
        "field": "expiryDate",
        "message": "Expiry date must be after issue date",
        "rejectedValue": "2023-01-15"
      },
      {
        "field": "regNumber",
        "message": "Registration number already exists",
        "rejectedValue": "ABC123"
      }
    ]
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00.123Z",
    "requestId": "req-abc-12345",
    "path": "/api/v1/policies/motor",
    "method": "POST"
  }
}
```

### 16.3 Reference Links
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [React Documentation](https://react.dev/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

**Document Control:**
- **Author:** GenApp Modernization Team
- **Reviewers:** Technical Architects, Business Analysts, Security Team
- **Approval:** CTO, VP of Engineering
- **Next Review Date:** February 17, 2027

---

**End of Specification Document**
