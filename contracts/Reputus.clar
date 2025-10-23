;; Reputus - Web3 Reputation System for Freelancers with NFT Support
;; Core contract for tracking immutable job records and reputation scores
;; Now includes dynamic reputation NFTs that upgrade based on milestones
;; Includes decentralized dispute resolution and arbitration system

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_RATING (err u101))
(define-constant ERR_JOB_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_REVIEWED (err u103))
(define-constant ERR_INVALID_PARTICIPANT (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))
(define-constant ERR_NFT_NOT_FOUND (err u106))
(define-constant ERR_NFT_NOT_OWNED (err u107))
(define-constant ERR_NFT_EXISTS (err u108))
(define-constant ERR_DISPUTE_NOT_FOUND (err u109))
(define-constant ERR_DISPUTE_EXISTS (err u110))
(define-constant ERR_DISPUTE_RESOLVED (err u111))
(define-constant ERR_INVALID_ARBITRATOR (err u112))
(define-constant ERR_ALREADY_VOTED (err u113))
(define-constant ERR_VOTING_CLOSED (err u114))
(define-constant ERR_INSUFFICIENT_STAKE (err u115))
(define-constant ERR_INVALID_DECISION (err u116))

;; Arbitration Constants
(define-constant MIN_ARBITRATOR_REPUTATION u100)
(define-constant DISPUTE_STAKE_AMOUNT u1000000) ;; 1 STX in micro-STX
(define-constant VOTING_PERIOD u144) ;; ~24 hours in blocks
(define-constant MIN_ARBITRATORS u3)

;; NFT Definition
(define-non-fungible-token reputation-nft uint)

;; Data Variables
(define-data-var next-job-id uint u1)
(define-data-var next-nft-id uint u1)
(define-data-var next-dispute-id uint u1)

;; Data Maps
(define-map jobs
  { job-id: uint }
  {
    freelancer: principal,
    client: principal,
    amount: uint,
    status: (string-ascii 20),
    created-at: uint,
    completed-at: (optional uint)
  }
)

(define-map reviews
  { job-id: uint }
  {
    rating: uint,
    comment: (string-utf8 500),
    reviewer: principal,
    reviewed-at: uint
  }
)

(define-map user-stats
  { user: principal }
  {
    total-jobs: uint,
    completed-jobs: uint,
    total-rating: uint,
    review-count: uint,
    reputation-score: uint,
    nft-id: (optional uint),
    reputation-tier: (string-ascii 20)
  }
)

(define-map nft-metadata
  { token-id: uint }
  {
    owner: principal,
    reputation-tier: (string-ascii 20),
    reputation-score: uint,
    minted-at: uint,
    last-updated: uint
  }
)

;; Dispute Resolution Maps
(define-map disputes
  { dispute-id: uint }
  {
    job-id: uint,
    initiator: principal,
    respondent: principal,
    reason: (string-utf8 500),
    status: (string-ascii 20),
    created-at: uint,
    voting-ends-at: uint,
    resolved-at: (optional uint),
    decision: (optional (string-ascii 20)),
    stake-locked: uint
  }
)

(define-map arbitrator-votes
  { dispute-id: uint, arbitrator: principal }
  {
    decision: (string-ascii 20),
    voted-at: uint,
    justification: (string-utf8 300)
  }
)

(define-map dispute-vote-counts
  { dispute-id: uint }
  {
    favor-freelancer: uint,
    favor-client: uint,
    total-votes: uint
  }
)

(define-map arbitrator-registry
  { arbitrator: principal }
  {
    registered-at: uint,
    total-disputes: uint,
    successful-resolutions: uint,
    is-active: bool
  }
)

;; NFT Implementation Functions
(define-read-only (get-last-token-id)
  (ok (- (var-get next-nft-id) u1))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (some "https://api.reputus.io/nft/metadata"))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? reputation-nft token-id))
)

;; Read-only functions
(define-read-only (get-job (job-id uint))
  (map-get? jobs { job-id: job-id })
)

(define-read-only (get-review (job-id uint))
  (map-get? reviews { job-id: job-id })
)

(define-read-only (get-user-stats (user principal))
  (default-to
    { 
      total-jobs: u0, 
      completed-jobs: u0, 
      total-rating: u0, 
      review-count: u0, 
      reputation-score: u0,
      nft-id: none,
      reputation-tier: "bronze"
    }
    (map-get? user-stats { user: user })
  )
)

(define-read-only (get-nft-metadata (token-id uint))
  (map-get? nft-metadata { token-id: token-id })
)

(define-read-only (calculate-reputation-score (user principal))
  (let (
    (stats (get-user-stats user))
    (review-count (get review-count stats))
    (total-rating (get total-rating stats))
    (completed-jobs (get completed-jobs stats))
  )
    (if (> review-count u0)
      (+ (* (/ total-rating review-count) u10) (* completed-jobs u5))
      u0
    )
  )
)

(define-read-only (get-reputation-tier (reputation-score uint))
  (if (>= reputation-score u500)
    "diamond"
    (if (>= reputation-score u250)
      "platinum"
      (if (>= reputation-score u100)
        "gold"
        (if (>= reputation-score u50)
          "silver"
          "bronze"
        )
      )
    )
  )
)

(define-read-only (get-next-job-id)
  (var-get next-job-id)
)

(define-read-only (get-next-nft-id)
  (var-get next-nft-id)
)

(define-read-only (get-next-dispute-id)
  (var-get next-dispute-id)
)

;; Dispute Resolution Read-only Functions
(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

(define-read-only (get-arbitrator-vote (dispute-id uint) (arbitrator principal))
  (map-get? arbitrator-votes { dispute-id: dispute-id, arbitrator: arbitrator })
)

(define-read-only (get-dispute-vote-counts (dispute-id uint))
  (default-to
    { favor-freelancer: u0, favor-client: u0, total-votes: u0 }
    (map-get? dispute-vote-counts { dispute-id: dispute-id })
  )
)

(define-read-only (get-arbitrator-info (arbitrator principal))
  (map-get? arbitrator-registry { arbitrator: arbitrator })
)

(define-read-only (is-eligible-arbitrator (arbitrator principal))
  (let (
    (stats (get-user-stats arbitrator))
    (reputation (get reputation-score stats))
    (registry-info (get-arbitrator-info arbitrator))
  )
    (and 
      (>= reputation MIN_ARBITRATOR_REPUTATION)
      (match registry-info
        info (get is-active info)
        true
      )
    )
  )
)

(define-read-only (can-vote-on-dispute (dispute-id uint) (arbitrator principal))
  (let (
    (dispute-data (get-dispute dispute-id))
    (current-height stacks-block-height)
  )
    (match dispute-data
      dispute
      (and
        (is-eligible-arbitrator arbitrator)
        (is-eq (get status dispute) "open")
        (<= current-height (get voting-ends-at dispute))
        (is-none (get-arbitrator-vote dispute-id arbitrator))
        (not (is-eq arbitrator (get initiator dispute)))
        (not (is-eq arbitrator (get respondent dispute)))
      )
      false
    )
  )
)

;; Private functions
(define-private (mint-reputation-nft (user principal) (reputation-score uint) (tier (string-ascii 20)))
  (let (
    (nft-id (var-get next-nft-id))
    (current-height stacks-block-height)
  )
    (try! (nft-mint? reputation-nft nft-id user))
    (map-set nft-metadata
      { token-id: nft-id }
      {
        owner: user,
        reputation-tier: tier,
        reputation-score: reputation-score,
        minted-at: current-height,
        last-updated: current-height
      }
    )
    (var-set next-nft-id (+ nft-id u1))
    (ok nft-id)
  )
)

(define-private (update-nft-metadata (token-id uint) (reputation-score uint) (tier (string-ascii 20)))
  (let (
    (metadata (unwrap! (get-nft-metadata token-id) ERR_NFT_NOT_FOUND))
    (current-height stacks-block-height)
  )
    (map-set nft-metadata
      { token-id: token-id }
      (merge metadata {
        reputation-tier: tier,
        reputation-score: reputation-score,
        last-updated: current-height
      })
    )
    (ok true)
  )
)

(define-private (finalize-dispute-decision (dispute-id uint))
  (let (
    (vote-counts (get-dispute-vote-counts dispute-id))
    (favor-freelancer (get favor-freelancer vote-counts))
    (favor-client (get favor-client vote-counts))
    (total-votes (get total-votes vote-counts))
    (dispute-data (unwrap! (get-dispute dispute-id) ERR_DISPUTE_NOT_FOUND))
    (current-height stacks-block-height)
  )
    (if (>= total-votes MIN_ARBITRATORS)
      (let (
        (decision (if (> favor-freelancer favor-client) "freelancer" "client"))
      )
        (map-set disputes
          { dispute-id: dispute-id }
          (merge dispute-data {
            status: "resolved",
            resolved-at: (some current-height),
            decision: (some decision)
          })
        )
        (ok decision)
      )
      (ok "pending")
    )
  )
)

;; Public functions
(define-public (create-job (freelancer principal) (client principal) (amount uint))
  (let (
    (job-id (var-get next-job-id))
    (current-height stacks-block-height)
  )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (not (is-eq freelancer client)) ERR_INVALID_PARTICIPANT)
    
    (map-set jobs
      { job-id: job-id }
      {
        freelancer: freelancer,
        client: client,
        amount: amount,
        status: "active",
        created-at: current-height,
        completed-at: none
      }
    )
    
    ;; Update freelancer stats
    (let (
      (freelancer-stats (get-user-stats freelancer))
      (updated-total (+ (get total-jobs freelancer-stats) u1))
    )
      (map-set user-stats
        { user: freelancer }
        (merge freelancer-stats { total-jobs: updated-total })
      )
    )
    
    (var-set next-job-id (+ job-id u1))
    (ok job-id)
  )
)

(define-public (complete-job (job-id uint))
  (let (
    (job-data (unwrap! (get-job job-id) ERR_JOB_NOT_FOUND))
    (current-height stacks-block-height)
  )
    (asserts! (or (is-eq tx-sender (get freelancer job-data)) 
                  (is-eq tx-sender (get client job-data))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status job-data) "active") ERR_UNAUTHORIZED)
    
    (map-set jobs
      { job-id: job-id }
      (merge job-data { 
        status: "completed",
        completed-at: (some current-height)
      })
    )
    
    ;; Update freelancer completed jobs count
    (let (
      (freelancer (get freelancer job-data))
      (freelancer-stats (get-user-stats freelancer))
      (updated-completed (+ (get completed-jobs freelancer-stats) u1))
    )
      (map-set user-stats
        { user: freelancer }
        (merge freelancer-stats { completed-jobs: updated-completed })
      )
    )
    
    (ok true)
  )
)

(define-public (submit-review (job-id uint) (rating uint) (comment (string-utf8 500)))
  (let (
    (job-data (unwrap! (get-job job-id) ERR_JOB_NOT_FOUND))
    (comment-length (len comment))
    (current-height stacks-block-height)
  )
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
    (asserts! (and (> comment-length u0) (<= comment-length u500)) ERR_INVALID_RATING)
    (asserts! (is-eq (get status job-data) "completed") ERR_UNAUTHORIZED)
    (asserts! (is-eq tx-sender (get client job-data)) ERR_UNAUTHORIZED)
    (asserts! (is-none (get-review job-id)) ERR_ALREADY_REVIEWED)
    
    (map-set reviews
      { job-id: job-id }
      {
        rating: rating,
        comment: comment,
        reviewer: tx-sender,
        reviewed-at: current-height
      }
    )
    
    ;; Update freelancer rating stats and handle NFT
    (let (
      (freelancer (get freelancer job-data))
      (freelancer-stats (get-user-stats freelancer))
      (updated-rating (+ (get total-rating freelancer-stats) rating))
      (updated-count (+ (get review-count freelancer-stats) u1))
      (new-reputation (+ (* (/ updated-rating updated-count) u10) 
                         (* (get completed-jobs freelancer-stats) u5)))
      (new-tier (get-reputation-tier new-reputation))
      (current-nft-id (get nft-id freelancer-stats))
    )
      ;; Update user stats
      (map-set user-stats
        { user: freelancer }
        (merge freelancer-stats { 
          total-rating: updated-rating,
          review-count: updated-count,
          reputation-score: new-reputation,
          reputation-tier: new-tier
        })
      )
      
      ;; Handle NFT minting or updating
      (match current-nft-id
        existing-nft-id
        ;; Update existing NFT
        (begin
          (try! (update-nft-metadata existing-nft-id new-reputation new-tier))
          (ok true)
        )
        ;; Mint new NFT if reputation score is >= 25
        (if (>= new-reputation u25)
          (let (
            (minted-nft-id (try! (mint-reputation-nft freelancer new-reputation new-tier)))
          )
            (map-set user-stats
              { user: freelancer }
              (merge (get-user-stats freelancer) { nft-id: (some minted-nft-id) })
            )
            (ok true)
          )
          (ok true)
        )
      )
    )
  )
)

(define-public (mint-initial-nft)
  (let (
    (current-stats (get-user-stats tx-sender))
    (reputation-score (get reputation-score current-stats))
    (current-nft-id (get nft-id current-stats))
  )
    (asserts! (>= reputation-score u25) ERR_UNAUTHORIZED)
    (asserts! (is-none current-nft-id) ERR_NFT_EXISTS)
    
    (let (
      (tier (get-reputation-tier reputation-score))
      (minted-nft-id (try! (mint-reputation-nft tx-sender reputation-score tier)))
    )
      (map-set user-stats
        { user: tx-sender }
        (merge current-stats { nft-id: (some minted-nft-id) })
      )
      (ok minted-nft-id)
    )
  )
)

;; Dispute Resolution Public Functions

(define-public (register-as-arbitrator)
  (let (
    (current-stats (get-user-stats tx-sender))
    (reputation (get reputation-score current-stats))
    (current-height stacks-block-height)
  )
    (asserts! (>= reputation MIN_ARBITRATOR_REPUTATION) ERR_INSUFFICIENT_STAKE)
    
    (map-set arbitrator-registry
      { arbitrator: tx-sender }
      {
        registered-at: current-height,
        total-disputes: u0,
        successful-resolutions: u0,
        is-active: true
      }
    )
    (ok true)
  )
)

(define-public (create-dispute (job-id uint) (reason (string-utf8 500)))
  (let (
    (job-data (unwrap! (get-job job-id) ERR_JOB_NOT_FOUND))
    (dispute-id (var-get next-dispute-id))
    (current-height stacks-block-height)
    (reason-length (len reason))
  )
    (asserts! (> reason-length u0) ERR_INVALID_AMOUNT)
    (asserts! (<= reason-length u500) ERR_INVALID_AMOUNT)
    (asserts! (or (is-eq tx-sender (get freelancer job-data))
                  (is-eq tx-sender (get client job-data))) ERR_UNAUTHORIZED)
    
    (let (
      (respondent (if (is-eq tx-sender (get freelancer job-data))
                     (get client job-data)
                     (get freelancer job-data)))
    )
      (map-set disputes
        { dispute-id: dispute-id }
        {
          job-id: job-id,
          initiator: tx-sender,
          respondent: respondent,
          reason: reason,
          status: "open",
          created-at: current-height,
          voting-ends-at: (+ current-height VOTING_PERIOD),
          resolved-at: none,
          decision: none,
          stake-locked: DISPUTE_STAKE_AMOUNT
        }
      )
      
      (map-set dispute-vote-counts
        { dispute-id: dispute-id }
        {
          favor-freelancer: u0,
          favor-client: u0,
          total-votes: u0
        }
      )
      
      (var-set next-dispute-id (+ dispute-id u1))
      (ok dispute-id)
    )
  )
)

(define-public (vote-on-dispute (dispute-id uint) (decision (string-ascii 20)) (justification (string-utf8 300)))
  (let (
    (dispute-data (unwrap! (get-dispute dispute-id) ERR_DISPUTE_NOT_FOUND))
    (current-height stacks-block-height)
    (justification-length (len justification))
  )
    (asserts! (> justification-length u0) ERR_INVALID_AMOUNT)
    (asserts! (<= justification-length u300) ERR_INVALID_AMOUNT)
    (asserts! (or (is-eq decision "freelancer") (is-eq decision "client")) ERR_INVALID_DECISION)
    (asserts! (is-eligible-arbitrator tx-sender) ERR_INVALID_ARBITRATOR)
    (asserts! (is-eq (get status dispute-data) "open") ERR_DISPUTE_RESOLVED)
    (asserts! (<= current-height (get voting-ends-at dispute-data)) ERR_VOTING_CLOSED)
    (asserts! (is-none (get-arbitrator-vote dispute-id tx-sender)) ERR_ALREADY_VOTED)
    (asserts! (not (is-eq tx-sender (get initiator dispute-data))) ERR_INVALID_ARBITRATOR)
    (asserts! (not (is-eq tx-sender (get respondent dispute-data))) ERR_INVALID_ARBITRATOR)
    
    ;; Record vote
    (map-set arbitrator-votes
      { dispute-id: dispute-id, arbitrator: tx-sender }
      {
        decision: decision,
        voted-at: current-height,
        justification: justification
      }
    )
    
    ;; Update vote counts
    (let (
      (vote-counts (get-dispute-vote-counts dispute-id))
      (new-freelancer-votes (if (is-eq decision "freelancer")
                               (+ (get favor-freelancer vote-counts) u1)
                               (get favor-freelancer vote-counts)))
      (new-client-votes (if (is-eq decision "client")
                           (+ (get favor-client vote-counts) u1)
                           (get favor-client vote-counts)))
      (new-total-votes (+ (get total-votes vote-counts) u1))
    )
      (map-set dispute-vote-counts
        { dispute-id: dispute-id }
        {
          favor-freelancer: new-freelancer-votes,
          favor-client: new-client-votes,
          total-votes: new-total-votes
        }
      )
      
      ;; Update arbitrator stats
      (let (
        (arbitrator-info (unwrap! (get-arbitrator-info tx-sender) ERR_INVALID_ARBITRATOR))
        (updated-disputes (+ (get total-disputes arbitrator-info) u1))
      )
        (map-set arbitrator-registry
          { arbitrator: tx-sender }
          (merge arbitrator-info { total-disputes: updated-disputes })
        )
      )
      
      ;; Check if we can finalize
      (if (>= new-total-votes MIN_ARBITRATORS)
        (finalize-dispute-decision dispute-id)
        (ok "voted")
      )
    )
  )
)

(define-public (close-dispute-voting (dispute-id uint))
  (let (
    (dispute-data (unwrap! (get-dispute dispute-id) ERR_DISPUTE_NOT_FOUND))
    (current-height stacks-block-height)
  )
    (asserts! (is-eq (get status dispute-data) "open") ERR_DISPUTE_RESOLVED)
    (asserts! (> current-height (get voting-ends-at dispute-data)) ERR_VOTING_CLOSED)
    
    (finalize-dispute-decision dispute-id)
  )
)