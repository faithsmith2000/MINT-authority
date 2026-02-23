;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Supply Authority
;;
;; Overview:
;; This contract governs mint permissions for an external token
;; contract implementing a compatible mint function.
;;
;; Core Guarantees:
;; - Only authorized minters may mint
;; - Global supply cap enforced
;; - Emergency pause capability
;; - Total minted tracking
;;
;; Assumption:
;; This contract must be granted mint privileges inside the token
;; contract it controls.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ============================================================
;; SECTION 1 - OWNERSHIP
;; ============================================================

;; Deployer becomes initial owner.
(define-data-var contract-owner principal tx-sender)

;; ============================================================
;; SECTION 2 - MINTER REGISTRY
;; ============================================================

;; Stores authorized minters.
(define-map minters
  { minter: principal }
  { enabled: bool }
)

;; ============================================================
;; SECTION 3 - SUPPLY CONTROL
;; ============================================================

;; Tracks total tokens minted via this authority.
(define-data-var total-minted uint u0)

;; Hard cap on mintable supply.
(define-data-var max-supply uint u1000000000)

;; ============================================================
;; SECTION 4 - EMERGENCY PAUSE
;; ============================================================

;; When true, minting is disabled globally.
(define-data-var paused bool false)

;; ============================================================
;; SECTION 5 - TOKEN TRAIT
;; ============================================================

;; External token must implement this mint interface.
(define-trait mintable-trait
  (
    (mint (principal uint) (response bool uint))
  )
)

;; ============================================================
;; SECTION 6 - ERROR CONSTANTS
;; ============================================================

(define-constant ERR-UNAUTHORIZED      (err u100))
(define-constant ERR-PAUSED            (err u101))
(define-constant ERR-INVALID-AMOUNT    (err u102))
(define-constant ERR-SUPPLY-EXCEEDED   (err u103))

;; ============================================================
;; SECTION 7 - INTERNAL HELPERS
;; ============================================================

;; Returns true if caller is owner.
(define-private (is-owner (caller principal))
  (is-eq caller (var-get contract-owner))
)

;; Returns true if caller is authorized minter.
;; Owner implicitly has mint authority.
(define-private (is-minter (caller principal))
  (or
    (is-owner caller)
    (default-to false
      (get enabled (map-get? minters { minter: caller }))
    )
  )
)

;; Returns true if contract is active.
(define-private (is-active)
  (not (var-get paused))
)

;; ============================================================
;; SECTION 8 - READ-ONLY FUNCTIONS
;; ============================================================

(define-read-only (get-owner)
  (var-get contract-owner)
)

(define-read-only (get-total-minted)
  (var-get total-minted)
)

(define-read-only (get-max-supply)
  (var-get max-supply)
)

(define-read-only (is-authorized-minter (who principal))
  (is-minter who)
)

(define-read-only (is-paused)
  (var-get paused)
)

;; ============================================================
;; SECTION 9 - CORE MINT LOGIC
;; ============================================================

;; Mints tokens to a recipient via the external token contract.
;; This function enforces:
;; - Role authorization
;; - Pause state
;; - Non-zero mint amount
;; - Supply cap constraint
(define-public (mint
  (token <mintable-trait>)
  (recipient principal)
  (amount uint)
)
  (begin
    ;; Authorization check
    (asserts! (is-minter tx-sender) ERR-UNAUTHORIZED)

    ;; Pause check
    (asserts! (is-active) ERR-PAUSED)

    ;; Basic validation
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    (let (
          (current-total (var-get total-minted))
          (new-total (+ current-total amount))
         )

      ;; Enforce max supply
      (asserts! (<= new-total (var-get max-supply)) ERR-SUPPLY-EXCEEDED)

      ;; External mint call
      ;; Will revert automatically if token contract fails
      (try! (contract-call? token mint recipient amount))

      ;; State update AFTER successful external call
      (var-set total-minted new-total)

      (ok true)
    )
  )
)

;; ============================================================
;; SECTION 10 - MINTER MANAGEMENT
;; ============================================================

;; Adds a new authorized minter.
(define-public (add-minter (minter principal))
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)

    (map-set minters
      { minter: minter }
      { enabled: true }
    )

    (ok true)
  )
)

;; Removes an authorized minter.
(define-public (remove-minter (minter principal))
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)

    (map-delete minters { minter: minter })

    (ok true)
  )
)

;; ============================================================
;; SECTION 11 - SUPPLY CONFIGURATION
;; ============================================================

;; Updates maximum supply.
;; Cannot set below already minted supply.
(define-public (set-max-supply (new-max uint))
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)

    (asserts!
      (>= new-max (var-get total-minted))
      ERR-SUPPLY-EXCEEDED
    )

    (var-set max-supply new-max)

    (ok true)
  )
)

;; ============================================================
;; SECTION 12 - EMERGENCY CONTROLS
;; ============================================================

;; Globally pauses minting.
(define-public (pause)
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)
    (var-set paused true)
    (ok true)
  )
)

;; Resumes minting.
(define-public (unpause)
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)
    (var-set paused false)
    (ok true)
  )
)