;; Experience Optimization Contract
;; Enhances consciousness network quality

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_INVALID_SCORE (err u301))
(define-constant ERR_USER_NOT_FOUND (err u302))

(define-map user-experiences
  { user: principal }
  {
    total-sessions: uint,
    average-quality: uint,
    consciousness-growth: uint,
    optimization-level: uint,
    last-session: uint
  }
)

(define-map quality-metrics
  { session-id: (buff 32) }
  {
    latency-score: uint,
    clarity-score: uint,
    consciousness-sync: uint,
    user-satisfaction: uint,
    recorded-at: uint
  }
)

(define-map optimization-algorithms
  { algorithm-id: uint }
  {
    name: (string-ascii 30),
    effectiveness: uint,
    active: bool
  }
)

(define-public (record-session-quality (session-id (buff 32)) (latency uint) (clarity uint) (sync uint) (satisfaction uint))
  (begin
    (asserts! (<= latency u100) ERR_INVALID_SCORE)
    (asserts! (<= clarity u100) ERR_INVALID_SCORE)
    (asserts! (<= sync u100) ERR_INVALID_SCORE)
    (asserts! (<= satisfaction u100) ERR_INVALID_SCORE)

    (map-set quality-metrics
      { session-id: session-id }
      {
        latency-score: latency,
        clarity-score: clarity,
        consciousness-sync: sync,
        user-satisfaction: satisfaction,
        recorded-at: block-height
      }
    )

    ;; Update user experience
    (let ((current-exp (default-to
          { total-sessions: u0, average-quality: u0, consciousness-growth: u0, optimization-level: u0, last-session: u0 }
          (map-get? user-experiences { user: tx-sender }))))
      (map-set user-experiences
        { user: tx-sender }
        {
          total-sessions: (+ (get total-sessions current-exp) u1),
          average-quality: (/ (+ (* (get average-quality current-exp) (get total-sessions current-exp)) satisfaction) (+ (get total-sessions current-exp) u1)),
          consciousness-growth: (+ (get consciousness-growth current-exp) (/ sync u10)),
          optimization-level: (get optimization-level current-exp),
          last-session: block-height
        }
      )
    )
    (ok true)
  )
)

(define-public (optimize-user-experience (user principal))
  (let ((user-exp (unwrap! (map-get? user-experiences { user: user }) ERR_USER_NOT_FOUND)))
    (let ((new-optimization-level
           (if (> (get average-quality user-exp) u80)
               (+ (get optimization-level user-exp) u1)
               (get optimization-level user-exp))))
      (map-set user-experiences
        { user: user }
        (merge user-exp { optimization-level: new-optimization-level })
      )
      (ok new-optimization-level)
    )
  )
)

(define-public (register-algorithm (algorithm-id uint) (name (string-ascii 30)) (effectiveness uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set optimization-algorithms
      { algorithm-id: algorithm-id }
      {
        name: name,
        effectiveness: effectiveness,
        active: true
      }
    )
    (ok true)
  )
)

(define-read-only (get-user-experience (user principal))
  (map-get? user-experiences { user: user })
)

(define-read-only (get-session-quality (session-id (buff 32)))
  (map-get? quality-metrics { session-id: session-id })
)

(define-read-only (get-algorithm (algorithm-id uint))
  (map-get? optimization-algorithms { algorithm-id: algorithm-id })
)
