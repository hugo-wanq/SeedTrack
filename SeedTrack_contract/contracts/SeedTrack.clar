
;; title: SeedTrack
;; version: 1.0.0
;; summary: Supply chain tracking smart contract for agricultural seed origin and genetic verification
;; description: This contract provides comprehensive tracking of agricultural seeds from origin through
;;              the supply chain, including genetic verification, quality assurance, and provenance tracking.

;; Error codes
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-UNAUTHORIZED (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-STAGE (err u104))
(define-constant ERR-INVALID-INPUT (err u105))

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Seed batch counter
(define-data-var next-batch-id uint u1)

;; Data structures
(define-map seed-batches
  { batch-id: uint }
  {
    origin-farm: (string-ascii 100),
    seed-variety: (string-ascii 50),
    genetic-hash: (string-ascii 64),
    planting-date: uint,
    harvest-date: (optional uint),
    quantity-kg: uint,
    quality-grade: (string-ascii 10),
    certifier: principal,
    certification-date: uint,
    current-stage: (string-ascii 20),
    current-holder: principal,
    is-organic: bool,
    treatment-history: (list 10 (string-ascii 100))
  }
)

(define-map supply-chain-events
  { batch-id: uint, event-id: uint }
  {
    event-type: (string-ascii 30),
    timestamp: uint,
    location: (string-ascii 100),
    actor: principal,
    metadata: (string-ascii 200),
    quality-metrics: (optional (string-ascii 100))
  }
)

(define-map batch-event-counter
  { batch-id: uint }
  { count: uint }
)

(define-map authorized-certifiers
  { certifier: principal }
  { name: (string-ascii 100), authorized: bool }
)

(define-map genetic-verification
  { genetic-hash: (string-ascii 64) }
  {
    variety-name: (string-ascii 50),
    parent-genetics: (list 5 (string-ascii 64)),
    verified-by: principal,
    verification-date: uint,
    purity-percentage: uint
  }
)

;; Public functions

;; Initialize a new seed batch
(define-public (register-seed-batch
    (origin-farm (string-ascii 100))
    (seed-variety (string-ascii 50))
    (genetic-hash (string-ascii 64))
    (planting-date uint)
    (quantity-kg uint)
    (quality-grade (string-ascii 10))
    (is-organic bool)
    (treatment-history (list 10 (string-ascii 100))))
  (let ((batch-id (var-get next-batch-id)))
    (begin
      ;; Verify caller is authorized certifier
      (asserts! (is-authorized-certifier tx-sender) ERR-UNAUTHORIZED)

      ;; Store seed batch information
      (map-set seed-batches
        { batch-id: batch-id }
        {
          origin-farm: origin-farm,
          seed-variety: seed-variety,
          genetic-hash: genetic-hash,
          planting-date: planting-date,
          harvest-date: none,
          quantity-kg: quantity-kg,
          quality-grade: quality-grade,
          certifier: tx-sender,
          certification-date: block-height,
          current-stage: "CERTIFIED",
          current-holder: tx-sender,
          is-organic: is-organic,
          treatment-history: treatment-history
        }
      )

      ;; Initialize event counter
      (map-set batch-event-counter
        { batch-id: batch-id }
        { count: u0 }
      )

      ;; Record initial certification event
      (unwrap-panic (add-supply-chain-event
        batch-id
        "CERTIFICATION"
        origin-farm
        "Initial seed batch certification and registration"
        (some quality-grade)))

      ;; Increment batch counter
      (var-set next-batch-id (+ batch-id u1))

      (ok batch-id)
    )
  )
)

;; Update harvest information
(define-public (update-harvest-info (batch-id uint) (harvest-date uint))
  (let ((batch (unwrap! (map-get? seed-batches { batch-id: batch-id }) ERR-NOT-FOUND)))
    (begin
      ;; Verify caller is the certifier
      (asserts! (is-eq tx-sender (get certifier batch)) ERR-UNAUTHORIZED)

      ;; Update batch with harvest date
      (map-set seed-batches
        { batch-id: batch-id }
        (merge batch {
          harvest-date: (some harvest-date),
          current-stage: "HARVESTED"
        })
      )

      ;; Record harvest event
      (unwrap-panic (add-supply-chain-event
        batch-id
        "HARVEST"
        (get origin-farm batch)
        "Seed harvest completed"
        none))

      (ok true)
    )
  )
)

;; Transfer seed batch to new holder
(define-public (transfer-batch
    (batch-id uint)
    (new-holder principal)
    (location (string-ascii 100))
    (metadata (string-ascii 200)))
  (let ((batch (unwrap! (map-get? seed-batches { batch-id: batch-id }) ERR-NOT-FOUND)))
    (begin
      ;; Verify caller is current holder
      (asserts! (is-eq tx-sender (get current-holder batch)) ERR-UNAUTHORIZED)

      ;; Update current holder
      (map-set seed-batches
        { batch-id: batch-id }
        (merge batch {
          current-holder: new-holder,
          current-stage: "IN_TRANSIT"
        })
      )

      ;; Record transfer event
      (unwrap-panic (add-supply-chain-event
        batch-id
        "TRANSFER"
        location
        metadata
        none))

      (ok true)
    )
  )
)

;; Update batch stage (e.g., PROCESSING, PACKAGING, DISTRIBUTION)
(define-public (update-batch-stage
    (batch-id uint)
    (new-stage (string-ascii 20))
    (location (string-ascii 100))
    (metadata (string-ascii 200))
    (quality-metrics (optional (string-ascii 100))))
  (let ((batch (unwrap! (map-get? seed-batches { batch-id: batch-id }) ERR-NOT-FOUND)))
    (begin
      ;; Verify caller is current holder or authorized certifier
      (asserts! (or (is-eq tx-sender (get current-holder batch))
                   (is-authorized-certifier tx-sender)) ERR-UNAUTHORIZED)

      ;; Update stage
      (map-set seed-batches
        { batch-id: batch-id }
        (merge batch { current-stage: new-stage })
      )

      ;; Record stage update event
      (try! (add-supply-chain-event
        batch-id
        "STAGE_UPDATE"
        location
        metadata
        quality-metrics))

      (ok true)
    )
  )
)

;; Register genetic verification
(define-public (register-genetic-verification
    (genetic-hash (string-ascii 64))
    (variety-name (string-ascii 50))
    (parent-genetics (list 5 (string-ascii 64)))
    (purity-percentage uint))
  (begin
    ;; Verify caller is authorized certifier
    (asserts! (is-authorized-certifier tx-sender) ERR-UNAUTHORIZED)

    ;; Verify purity percentage is valid (0-100)
    (asserts! (<= purity-percentage u100) ERR-INVALID-INPUT)

    ;; Store genetic verification
    (map-set genetic-verification
      { genetic-hash: genetic-hash }
      {
        variety-name: variety-name,
        parent-genetics: parent-genetics,
        verified-by: tx-sender,
        verification-date: block-height,
        purity-percentage: purity-percentage
      }
    )

    (ok true)
  )
)

;; Authorize certifier (only contract owner)
(define-public (authorize-certifier (certifier principal) (name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)

    (map-set authorized-certifiers
      { certifier: certifier }
      { name: name, authorized: true }
    )

    (ok true)
  )
)

;; Revoke certifier authorization (only contract owner)
(define-public (revoke-certifier (certifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)

    (map-set authorized-certifiers
      { certifier: certifier }
      { name: "", authorized: false }
    )

    (ok true)
  )
)

;; Private function to add supply chain event
(define-private (add-supply-chain-event
    (batch-id uint)
    (event-type (string-ascii 30))
    (location (string-ascii 100))
    (metadata (string-ascii 200))
    (quality-metrics (optional (string-ascii 100))))
  (let ((event-count (default-to u0 (get count (map-get? batch-event-counter { batch-id: batch-id })))))
    (begin
      ;; Validate batch exists
      (unwrap! (map-get? seed-batches { batch-id: batch-id }) ERR-NOT-FOUND)

      ;; Store event
      (map-set supply-chain-events
        { batch-id: batch-id, event-id: event-count }
        {
          event-type: event-type,
          timestamp: block-height,
          location: location,
          actor: tx-sender,
          metadata: metadata,
          quality-metrics: quality-metrics
        }
      )

      ;; Increment event counter
      (map-set batch-event-counter
        { batch-id: batch-id }
        { count: (+ event-count u1) }
      )

      (ok true)
    )
  )
)

;; Read-only functions

;; Get seed batch information
(define-read-only (get-seed-batch (batch-id uint))
  (map-get? seed-batches { batch-id: batch-id })
)

;; Get supply chain event
(define-read-only (get-supply-chain-event (batch-id uint) (event-id uint))
  (map-get? supply-chain-events { batch-id: batch-id, event-id: event-id })
)

;; Get genetic verification
(define-read-only (get-genetic-verification (genetic-hash (string-ascii 64)))
  (map-get? genetic-verification { genetic-hash: genetic-hash })
)

;; Check if certifier is authorized
(define-read-only (is-authorized-certifier (certifier principal))
  (default-to false (get authorized (map-get? authorized-certifiers { certifier: certifier })))
)

;; Get batch event count
(define-read-only (get-batch-event-count (batch-id uint))
  (default-to u0 (get count (map-get? batch-event-counter { batch-id: batch-id })))
)

;; Get current batch ID counter
(define-read-only (get-next-batch-id)
  (var-get next-batch-id)
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; Verify seed authenticity by checking genetic hash and certification
(define-read-only (verify-seed-authenticity (batch-id uint) (expected-genetic-hash (string-ascii 64)))
  (match (get-seed-batch batch-id)
    batch (and
            (is-eq (get genetic-hash batch) expected-genetic-hash)
            (is-some (get-genetic-verification expected-genetic-hash)))
    false
  )
)

;; Get complete supply chain history for a batch (returns event count for now)
(define-read-only (get-supply-chain-history (batch-id uint))
  (get-batch-event-count batch-id)
)
