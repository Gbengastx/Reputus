# Reputus 🏅

**Web3 Reputation System for Freelancers with Dynamic NFTs**

A blockchain-based reputation system that tracks and verifies freelance work with immutable job records, transparent ratings, and dynamic reputation NFTs that upgrade based on milestones on the Stacks blockchain.

## 🌟 Features

- **Immutable Job Records**: All freelance jobs are permanently recorded on the blockchain
- **Review & Rating Logic**: Transparent rating system with anti-manipulation measures  
- **Reputation Scoring**: Algorithmic calculation of reputation based on job completion and ratings
- **Dynamic Reputation NFTs**: Mint and upgrade NFTs based on reputation milestones
- **Decentralized Trust**: No central authority controlling reputation data

## 🎖️ Reputation NFT Tiers

The system mints dynamic NFTs that automatically upgrade as users reach reputation milestones:

- **Bronze** (25+ reputation): Entry-level achievement
- **Silver** (50+ reputation): Consistent performer
- **Gold** (100+ reputation): Trusted professional
- **Platinum** (250+ reputation): Expert freelancer
- **Diamond** (500+ reputation): Elite reputation

NFTs are automatically minted when users reach 25 reputation points and upgrade dynamically as higher tiers are achieved.

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

- `create-job(freelancer, client, amount)` - Creates a new job record
- `complete-job(job-id)` - Marks a job as completed
- `submit-review(job-id, rating, comment)` - Submits a review for completed work
- `mint-initial-nft()` - Manually mints initial NFT for qualified users
- `transfer(token-id, sender, recipient)` - Transfers reputation NFT

### Read-Only Functions

- `get-job(job-id)` - Retrieves job details
- `get-review(job-id)` - Gets review for a specific job
- `get-user-stats(user)` - Returns user's reputation statistics including NFT info
- `calculate-reputation-score(user)` - Calculates current reputation score
- `get-reputation-tier(reputation-score)` - Returns tier based on score
- `get-nft-metadata(token-id)` - Gets NFT metadata including tier and score
- `get-owner(token-id)` - Returns NFT owner
- `get-token-uri(token-id)` - Returns NFT metadata URI

## 🏗️ Architecture

The system consists of four main data structures:

1. **Jobs Map**: Stores job details including participants, amount, and status
2. **Reviews Map**: Contains ratings and comments for completed jobs
3. **User Stats Map**: Tracks aggregate statistics and NFT information for reputation calculation
4. **NFT Metadata Map**: Stores dynamic NFT data including tier and reputation score

## 🔐 Security Features

- Input validation for all parameters
- Access control for job operations
- Prevention of duplicate reviews
- Protection against invalid ratings
- NFT ownership verification
- Proper error handling for all edge cases

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
clarinet test
```

## 📈 Reputation Algorithm

Reputation Score = (Average Rating × 10) + (Completed Jobs × 5)

This algorithm rewards both quality work (high ratings) and consistent delivery (job completion).

### NFT Minting Logic

- NFTs are automatically minted when users reach 25+ reputation points
- Existing NFTs are dynamically updated when reputation tiers change
- Each NFT contains metadata about the user's current reputation tier and score
- NFTs can be transferred between wallets while maintaining reputation data

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure `clarinet check` passes
5. Submit a pull request

