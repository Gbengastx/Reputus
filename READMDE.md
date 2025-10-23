# Reputus 🏅

**Web3 Reputation System for Freelancers with Dynamic NFTs & Decentralized Dispute Resolution**

A blockchain-based reputation system that tracks and verifies freelance work with immutable job records, transparent ratings, dynamic reputation NFTs that upgrade based on milestones, and a decentralized arbitration system for resolving job conflicts on the Stacks blockchain.

## 🌟 Features

- **Immutable Job Records**: All freelance jobs are permanently recorded on the blockchain
- **Review & Rating Logic**: Transparent rating system with anti-manipulation measures  
- **Reputation Scoring**: Algorithmic calculation of reputation based on job completion and ratings
- **Dynamic Reputation NFTs**: Mint and upgrade NFTs based on reputation milestones
- **Decentralized Dispute Resolution**: Community-driven arbitration system for job conflicts
- **Arbitrator Registry**: Qualified users can register as arbitrators to resolve disputes
- **Transparent Voting**: On-chain voting with justifications for complete transparency
- **Decentralized Trust**: No central authority controlling reputation data or dispute outcomes

## 🎖️ Reputation NFT Tiers

The system mints dynamic NFTs that automatically upgrade as users reach reputation milestones:

- **Bronze** (25+ reputation): Entry-level achievement
- **Silver** (50+ reputation): Consistent performer
- **Gold** (100+ reputation): Trusted professional
- **Platinum** (250+ reputation): Expert freelancer
- **Diamond** (500+ reputation): Elite reputation

NFTs are automatically minted when users reach 25 reputation points and upgrade dynamically as higher tiers are achieved.

## ⚖️ Dispute Resolution System

### How It Works

1. **Dispute Creation**: Either party (freelancer or client) can open a dispute for any job
2. **Arbitrator Voting**: Qualified arbitrators (100+ reputation) vote on the dispute
3. **Decision Making**: Majority vote determines the outcome after minimum 3 votes
4. **Transparent Process**: All votes and justifications are recorded on-chain
5. **Time-Bound**: 24-hour voting period (~144 blocks) for timely resolution

### Arbitrator Requirements

- Minimum reputation score of 100
- Must be registered in the arbitrator registry
- Cannot be involved in the dispute (not initiator or respondent)
- Can vote with justification explaining their decision

### Dispute Parameters

- **Minimum Arbitrators**: 3 votes required for resolution
- **Voting Period**: 144 blocks (~24 hours)
- **Stake Amount**: 1 STX locked per dispute
- **Decisions**: Favor freelancer or favor client

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for testing

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd reputus
```

2. Check contract validity:
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

## 📋 Contract Functions

### Public Functions

**Job Management**
- `create-job(freelancer, client, amount)` - Creates a new job record
- `complete-job(job-id)` - Marks a job as completed
- `submit-review(job-id, rating, comment)` - Submits a review for completed work

**NFT Functions**
- `mint-initial-nft()` - Manually mints initial NFT for qualified users
- `transfer(token-id, sender, recipient)` - Transfers reputation NFT

**Dispute Resolution**
- `register-as-arbitrator()` - Register as an arbitrator (requires 100+ reputation)
- `create-dispute(job-id, reason)` - Open a dispute for a job
- `vote-on-dispute(dispute-id, decision, justification)` - Vote on an open dispute
- `close-dispute-voting(dispute-id)` - Finalize dispute after voting period ends

### Read-Only Functions

**Job & Reputation Queries**
- `get-job(job-id)` - Retrieves job details
- `get-review(job-id)` - Gets review for a specific job
- `get-user-stats(user)` - Returns user's reputation statistics including NFT info
- `calculate-reputation-score(user)` - Calculates current reputation score
- `get-reputation-tier(reputation-score)` - Returns tier based on score
- `get-nft-metadata(token-id)` - Gets NFT metadata including tier and score
- `get-owner(token-id)` - Returns NFT owner
- `get-token-uri(token-id)` - Returns NFT metadata URI

**Dispute Queries**
- `get-dispute(dispute-id)` - Retrieves dispute details
- `get-arbitrator-vote(dispute-id, arbitrator)` - Gets specific arbitrator's vote
- `get-dispute-vote-counts(dispute-id)` - Returns vote tally for a dispute
- `get-arbitrator-info(arbitrator)` - Gets arbitrator registry information
- `is-eligible-arbitrator(arbitrator)` - Checks if user can arbitrate
- `can-vote-on-dispute(dispute-id, arbitrator)` - Validates voting eligibility

## 🏗️ Architecture

The system consists of eight main data structures:

1. **Jobs Map**: Stores job details including participants, amount, and status
2. **Reviews Map**: Contains ratings and comments for completed jobs
3. **User Stats Map**: Tracks aggregate statistics and NFT information for reputation calculation
4. **NFT Metadata Map**: Stores dynamic NFT data including tier and reputation score
5. **Disputes Map**: Records all dispute information and resolution status
6. **Arbitrator Votes Map**: Tracks individual arbitrator votes with justifications
7. **Dispute Vote Counts Map**: Aggregates voting results per dispute
8. **Arbitrator Registry Map**: Maintains list of qualified arbitrators

## 🔐 Security Features

- Input validation for all parameters
- Access control for job operations
- Prevention of duplicate reviews and votes
- Protection against invalid ratings and decisions
- NFT ownership verification
- Arbitrator eligibility checks
- Time-bound dispute voting
- Prevention of self-arbitration
- Proper error handling for all edge cases
- Stake locking mechanism for disputes
- String length validation (reasons, comments, justifications)

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
clarinet test
```

Test coverage includes:
- Job creation and completion
- Review submission and reputation calculation
- NFT minting and upgrading
- Dispute creation and arbitration
- Voting mechanisms
- Edge cases and error conditions

## 📈 Reputation Algorithm

**Reputation Score = (Average Rating × 10) + (Completed Jobs × 5)**

This algorithm rewards both quality work (high ratings) and consistent delivery (job completion).

### NFT Minting Logic

- NFTs are automatically minted when users reach 25+ reputation points
- Existing NFTs are dynamically updated when reputation tiers change
- Each NFT contains metadata about the user's current reputation tier and score
- NFTs can be transferred between wallets while maintaining reputation data

### Arbitrator Selection

Arbitrators must maintain a reputation score of 100+ to participate in dispute resolution. Their performance is tracked through:
- Total disputes participated in
- Successful resolutions
- Active status in the registry

## 🔄 Dispute Resolution Flow

```
1. Job Dispute Arises
   ↓
2. Party Creates Dispute (with reason)
   ↓
3. Voting Period Opens (24 hours)
   ↓
4. Arbitrators Vote (with justification)
   ↓
5. Minimum 3 Votes Collected
   ↓
6. Majority Decision Finalized
   ↓
7. Dispute Resolved On-Chain
```

## 💡 Usage Examples

### Creating a Job
```clarity
(contract-call? .reputus create-job 'SP2...FREELANCER 'SP2...CLIENT u50000000)
```

### Completing and Reviewing
```clarity
(contract-call? .reputus complete-job u1)
(contract-call? .reputus submit-review u1 u5 u"Excellent work!")
```

### Registering as Arbitrator
```clarity
(contract-call? .reputus register-as-arbitrator)
```

### Creating and Resolving Disputes
```clarity
;; Create dispute
(contract-call? .reputus create-dispute u1 u"Work not delivered as agreed")

;; Vote on dispute
(contract-call? .reputus vote-on-dispute u1 "freelancer" u"Evidence shows work was completed on time")

;; Close voting after period ends
(contract-call? .reputus close-dispute-voting u1)
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure `clarinet check` passes
5. Submit a pull request