;; Reputus - Web3 Reputation System for Freelancers
;; Core contract for tracking immutable job records and reputation scores

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_RATING (err u101))
(define-constant ERR_JOB_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_REVIEWED (err u103))
(define-constant ERR_INVALID_PARTICIPANT (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))

;; Data Variables
(define-data-var next-job-id uint u1)

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
    reputation-score: uint
  }
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
    { total-jobs: u0, completed-jobs: u0, total-rating: u0, review-count: u0, reputation-score: u0 }
    (map-get? user-stats { user: user })
  )
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

(define-read-only (get-next-job-id)
  (var-get next-job-id)
)

;; Public functions
(define-public (create-job (freelancer principal) (client principal) (amount uint))
  (let (
    (job-id (var-get next-job-id))
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
        created-at: job-id,
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
  )
    (asserts! (or (is-eq tx-sender (get freelancer job-data)) 
                  (is-eq tx-sender (get client job-data))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status job-data) "active") ERR_UNAUTHORIZED)
    
    (map-set jobs
      { job-id: job-id }
      (merge job-data { 
        status: "completed",
        completed-at: (some job-id)
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
        reviewed-at: job-id
      }
    )
    
    ;; Update freelancer rating stats
    (let (
      (freelancer (get freelancer job-data))
      (freelancer-stats (get-user-stats freelancer))
      (updated-rating (+ (get total-rating freelancer-stats) rating))
      (updated-count (+ (get review-count freelancer-stats) u1))
      (new-reputation (calculate-reputation-score freelancer))
    )
      (map-set user-stats
        { user: freelancer }
        (merge freelancer-stats { 
          total-rating: updated-rating,
          review-count: updated-count,
          reputation-score: new-reputation
        })
      )
    )
    
    (ok true)
  )
)