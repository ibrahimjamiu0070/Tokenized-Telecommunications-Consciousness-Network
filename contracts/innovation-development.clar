;; Innovation Development Contract
;; Advances consciousness network technology

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_PROPOSAL_EXISTS (err u501))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u502))
(define-constant ERR_INVALID_VOTE (err u503))

(define-map innovation-proposals
  { proposal-id: uint }
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    innovation-type: (string-ascii 30),
    funding-required: uint,
    votes-for: uint,
    votes-against: uint,
    status: (string-ascii 20),
    created-at: uint,
    deadline: uint
  }
)

(define-map research-projects
  { project-id: uint }
  {
    lead-researcher: principal,
    title: (string-ascii 100),
    progress: uint,
    funding-allocated: uint,
    milestones-completed: uint,
    total-milestones: uint,
    status: (string-ascii 20)
  }
)

(define-map voter-records
  { proposal-id: uint, voter: principal }
  { vote: bool, voted-at: uint }
)

(define-map innovation-metrics
  { metric-type: (string-ascii 30) }
  { value: uint, last-updated: uint }
)

(define-public (submit-proposal (proposal-id uint) (title (string-ascii 100)) (description (string-ascii 500)) (innovation-type (string-ascii 30)) (funding uint) (deadline uint))
  (begin
    (asserts! (is-none (map-get? innovation-proposals { proposal-id: proposal-id })) ERR_PROPOSAL_EXISTS)

    (map-set innovation-proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        title: title,
        description: description,
        innovation-type: innovation-type,
        funding-required: funding,
        votes-for: u0,
        votes-against: u0,
        status: "voting",
        created-at: block-height,
        deadline: deadline
      }
    )
    (ok true)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let ((proposal (unwrap! (map-get? innovation-proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (is-none (map-get? voter-records { proposal-id: proposal-id, voter: tx-sender })) ERR_INVALID_VOTE)
    (asserts! (is-eq (get status proposal) "voting") ERR_INVALID_VOTE)

    ;; Record vote
    (map-set voter-records
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote-for, voted-at: block-height }
    )

    ;; Update proposal vote counts
    (map-set innovation-proposals
      { proposal-id: proposal-id }
      (merge proposal {
        votes-for: (if vote-for (+ (get votes-for proposal) u1) (get votes-for proposal)),
        votes-against: (if vote-for (get votes-against proposal) (+ (get votes-against proposal) u1))
      })
    )
    (ok true)
  )
)

(define-public (approve-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? innovation-proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR_INVALID_VOTE)

    (map-set innovation-proposals
      { proposal-id: proposal-id }
      (merge proposal { status: "approved" })
    )
    (ok true)
  )
)

(define-public (create-research-project (project-id uint) (title (string-ascii 100)) (funding uint) (milestones uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set research-projects
      { project-id: project-id }
      {
        lead-researcher: tx-sender,
        title: title,
        progress: u0,
        funding-allocated: funding,
        milestones-completed: u0,
        total-milestones: milestones,
        status: "active"
      }
    )
    (ok true)
  )
)

(define-public (update-project-progress (project-id uint) (progress uint) (milestones-completed uint))
  (let ((project (unwrap! (map-get? research-projects { project-id: project-id }) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get lead-researcher project)) ERR_UNAUTHORIZED)

    (map-set research-projects
      { project-id: project-id }
      (merge project {
        progress: progress,
        milestones-completed: milestones-completed,
        status: (if (is-eq milestones-completed (get total-milestones project)) "completed" "active")
      })
    )
    (ok true)
  )
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? innovation-proposals { proposal-id: proposal-id })
)

(define-read-only (get-research-project (project-id uint))
  (map-get? research-projects { project-id: project-id })
)

(define-read-only (get-vote-record (proposal-id uint) (voter principal))
  (map-get? voter-records { proposal-id: proposal-id, voter: voter })
)
