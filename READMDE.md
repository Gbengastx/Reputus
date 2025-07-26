# Reputus 🏅

**Web3 Reputation System for Freelancers**

A blockchain-based reputation system that tracks and verifies freelance work with immutable job records, transparent ratings, and reputation NFTs on the Stacks blockchain.

## 🌟 Features

- **Immutable Job Records**: All freelance jobs are permanently recorded on the blockchain
- **Review & Rating Logic**: Transparent rating system with anti-manipulation measures  
- **Reputation Scoring**: Algorithmic calculation of reputation based on job completion and ratings
- **Decentralized Trust**: No central authority controlling reputation data

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

### Read-Only Functions

- `get-job(job-id)` - Retrieves job details
- `get-review(job-id)` - Gets review for a specific job
- `get-user-stats(user)` - Returns user's reputation statistics
- `calculate-reputation-score(user)` - Calculates current reputation score

## 🏗️ Architecture

The system consists of three main data structures:

1. **Jobs Map**: Stores job details including participants, amount, and status
2. **Reviews Map**: Contains ratings and comments for completed jobs
3. **User Stats Map**: Tracks aggregate statistics for reputation calculation

## 🔐 Security Features

- Input validation for all parameters
- Access control for job operations
- Prevention of duplicate reviews
- Protection against invalid ratings

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
clarinet test
```

## 📈 Reputation Algorithm

Reputation Score = (Average Rating × 10) + (Completed Jobs × 5)

This algorithm rewards both quality work (high ratings) and consistent delivery (job completion).

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure `clarinet check` passes
5. Submit a pull request


## 🔮 Future Roadmap

See the project issues for upcoming features including reputation NFTs, dispute resolution, and advanced analytics.

