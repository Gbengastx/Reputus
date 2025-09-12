;; Reputus - Web3 Reputation System for Freelancers with NFT Support
;; Core contract for tracking immutable job records and reputation scores
;; Now includes dynamic reputation NFTs that upgrade based on milestones

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

;; NFT Definition
(define-non-fungible-token reputation-nft uint)

;; Data Variables
(define-data-var next-job-id uint u1)
(define-data-var next-nft-id uint u1)

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

;; Private functions
(define-private (mint-reputation-nft (user principal) (reputation-score uint) (tier (string-ascii 20)))
  (let (
    (nft-id (var-get next-nft-id))
    (current-height stacks-block-height)
  )
    (unwrap! (nft-mint? reputation-nft nft-id user) (err u999))
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
          (unwrap! (update-nft-metadata existing-nft-id new-reputation new-tier) (err u999))
          (ok true)
        )
        ;; Mint new NFT if reputation score is >= 25
        (if (>= new-reputation u25)
          (let (
            (minted-nft-id (unwrap! (mint-reputation-nft freelancer new-reputation new-tier) (err u999)))
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
      (minted-nft-id (unwrap! (mint-reputation-nft tx-sender reputation-score tier) (err u999)))
    )
      (map-set user-stats
        { user: tx-sender }
        (merge current-stats { nft-id: (some minted-nft-id) })
      )
      (ok minted-nft-id)
    )
  )
)