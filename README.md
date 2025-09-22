# SeedTrack

A comprehensive supply chain tracking smart contract for agricultural seed origin and genetic verification built on the Stacks blockchain using Clarity.

## Description

SeedTrack provides end-to-end traceability for agricultural seeds through the supply chain, ensuring authenticity, quality, and proper handling from farm to final distribution. The system enables genetic verification, certifier management, and comprehensive event tracking for seed batches.

## Features

- **Seed Batch Registration**: Register new seed batches with comprehensive metadata including origin farm, variety, genetic hash, and treatment history
- **Genetic Verification**: Store and verify genetic information with purity percentages and parent genetics tracking
- **Supply Chain Tracking**: Complete event logging for each stage of the supply chain journey
- **Certifier Management**: Authorize and manage trusted certifiers who can register and verify seed batches
- **Quality Assurance**: Track quality grades, organic certification, and treatment histories
- **Transfer Management**: Secure transfer of seed batches between holders with location tracking
- **Authenticity Verification**: Verify seed authenticity using genetic hashes and certification data
- **Stage Management**: Track seeds through various stages (CERTIFIED, HARVESTED, IN_TRANSIT, PROCESSING, PACKAGING, DISTRIBUTION)

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Testing Framework**: Vitest with Clarinet SDK
- **Contract Version**: 1.0.0

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) v18 or higher
- [Git](https://git-scm.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd SeedTrack
```

2. Navigate to the contract directory:
```bash
cd SeedTrack_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Initialize the Contract

Deploy the contract to authorize the first certifier (contract owner):

```clarity
;; The contract owner is automatically set to tx-sender during deployment
```

### Authorize a Certifier

Only the contract owner can authorize new certifiers:

```clarity
(contract-call? .SeedTrack authorize-certifier 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "Organic Seeds Certification Authority")
```

### Register a Seed Batch

Authorized certifiers can register new seed batches:

```clarity
(contract-call? .SeedTrack register-seed-batch
  "Green Valley Organic Farm"
  "Heirloom Tomato"
  "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"
  u1704067200  ;; planting date (timestamp)
  u1000        ;; quantity in kg
  "Grade A"
  true         ;; is organic
  (list "No pesticides" "Organic fertilizer only"))
```

### Update Harvest Information

```clarity
(contract-call? .SeedTrack update-harvest-info
  u1           ;; batch-id
  u1711843200) ;; harvest date (timestamp)
```

### Transfer Seed Batch

```clarity
(contract-call? .SeedTrack transfer-batch
  u1           ;; batch-id
  'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE  ;; new holder
  "Distribution Center Alpha"
  "Transferred for processing and packaging")
```

### Register Genetic Verification

```clarity
(contract-call? .SeedTrack register-genetic-verification
  "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"
  "Heirloom Tomato Variety X"
  (list "parent1hash" "parent2hash")
  u95) ;; 95% purity
```

### Query Seed Batch Information

```clarity
(contract-call? .SeedTrack get-seed-batch u1)
```

### Verify Seed Authenticity

```clarity
(contract-call? .SeedTrack verify-seed-authenticity
  u1
  "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456")
```

## Contract Functions Documentation

### Public Functions

#### `register-seed-batch`
Registers a new seed batch with comprehensive metadata.

**Parameters:**
- `origin-farm` (string-ascii 100): Name/identifier of the originating farm
- `seed-variety` (string-ascii 50): Seed variety name
- `genetic-hash` (string-ascii 64): Unique genetic identifier hash
- `planting-date` (uint): Unix timestamp of planting date
- `quantity-kg` (uint): Quantity in kilograms
- `quality-grade` (string-ascii 10): Quality grade (e.g., "Grade A")
- `is-organic` (bool): Organic certification status
- `treatment-history` (list 10 string-ascii 100): List of treatments applied

**Returns:** `(response uint uint)` - Batch ID on success

#### `update-harvest-info`
Updates harvest information for an existing batch.

**Parameters:**
- `batch-id` (uint): Unique batch identifier
- `harvest-date` (uint): Unix timestamp of harvest date

**Returns:** `(response bool uint)` - Success confirmation

#### `transfer-batch`
Transfers ownership of a seed batch to a new holder.

**Parameters:**
- `batch-id` (uint): Unique batch identifier
- `new-holder` (principal): Address of the new holder
- `location` (string-ascii 100): Transfer location
- `metadata` (string-ascii 200): Additional transfer information

**Returns:** `(response bool uint)` - Success confirmation

#### `update-batch-stage`
Updates the current stage of a seed batch.

**Parameters:**
- `batch-id` (uint): Unique batch identifier
- `new-stage` (string-ascii 20): New stage name
- `location` (string-ascii 100): Current location
- `metadata` (string-ascii 200): Stage update metadata
- `quality-metrics` (optional string-ascii 100): Quality assessment data

**Returns:** `(response bool uint)` - Success confirmation

#### `register-genetic-verification`
Registers genetic verification data for a genetic hash.

**Parameters:**
- `genetic-hash` (string-ascii 64): Genetic identifier hash
- `variety-name` (string-ascii 50): Variety name
- `parent-genetics` (list 5 string-ascii 64): Parent genetic hashes
- `purity-percentage` (uint): Genetic purity (0-100)

**Returns:** `(response bool uint)` - Success confirmation

#### `authorize-certifier`
Authorizes a new certifier (contract owner only).

**Parameters:**
- `certifier` (principal): Certifier address
- `name` (string-ascii 100): Certifier organization name

**Returns:** `(response bool uint)` - Success confirmation

#### `revoke-certifier`
Revokes certifier authorization (contract owner only).

**Parameters:**
- `certifier` (principal): Certifier address to revoke

**Returns:** `(response bool uint)` - Success confirmation

### Read-Only Functions

#### `get-seed-batch`
Retrieves complete seed batch information.

**Parameters:**
- `batch-id` (uint): Unique batch identifier

**Returns:** Batch data tuple or none

#### `get-supply-chain-event`
Retrieves a specific supply chain event.

**Parameters:**
- `batch-id` (uint): Unique batch identifier
- `event-id` (uint): Event sequence number

**Returns:** Event data tuple or none

#### `get-genetic-verification`
Retrieves genetic verification data.

**Parameters:**
- `genetic-hash` (string-ascii 64): Genetic identifier hash

**Returns:** Genetic verification data or none

#### `is-authorized-certifier`
Checks if a principal is an authorized certifier.

**Parameters:**
- `certifier` (principal): Address to check

**Returns:** `bool` - Authorization status

#### `verify-seed-authenticity`
Verifies seed authenticity using genetic hash and certification.

**Parameters:**
- `batch-id` (uint): Unique batch identifier
- `expected-genetic-hash` (string-ascii 64): Expected genetic hash

**Returns:** `bool` - Authenticity verification result

## Data Structures

### Seed Batch
- Origin farm information
- Seed variety and genetic hash
- Planting and harvest dates
- Quantity and quality grade
- Certifier and certification date
- Current stage and holder
- Organic status and treatment history

### Supply Chain Events
- Event type and timestamp
- Location and actor information
- Metadata and quality metrics
- Complete audit trail

### Genetic Verification
- Variety name and parent genetics
- Verification authority and date
- Purity percentage assessment

## Error Codes

- `ERR-OWNER-ONLY` (100): Operation restricted to contract owner
- `ERR-NOT-FOUND` (101): Requested resource not found
- `ERR-UNAUTHORIZED` (102): Caller not authorized for operation
- `ERR-ALREADY-EXISTS` (103): Resource already exists
- `ERR-INVALID-STAGE` (104): Invalid stage transition
- `ERR-INVALID-INPUT` (105): Invalid input parameters

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

3. Test contract functions:
```clarity
(contract-call? .SeedTrack get-next-batch-id)
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Testing

Run the test suite:

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## Security Notes

### Access Control
- Only authorized certifiers can register seed batches
- Only current holders can transfer batches
- Only the contract owner can manage certifier authorization
- Genetic verification requires certifier authorization

### Data Integrity
- Immutable event logging ensures audit trail integrity
- Genetic hashes provide tamper-evident seed identification
- Batch IDs are sequential and cannot be duplicated
- All critical operations emit supply chain events

### Best Practices
- Verify certifier authorization before trusting batch data
- Cross-reference genetic hashes with verification records
- Monitor supply chain events for complete traceability
- Regularly audit certifier authorization status

### Known Limitations
- Event history retrieval is limited to individual event queries
- Treatment history is capped at 10 entries per batch
- String lengths are constrained by Clarity limits
- No built-in batch splitting or merging functionality

## License

This project is licensed under the ISC License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## Support

For questions and support, please open an issue in the repository or contact the development team.