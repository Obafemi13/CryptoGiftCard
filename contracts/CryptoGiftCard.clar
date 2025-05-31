;; ------------------------------------------------------------
;; Contract: CryptoGiftCard
;; Description: Send STX gift cards that can be redeemed with a secret code
;; Language: Clarity (Stacks blockchain)
;; Author: ChatGPT
;; License: MIT
;; ------------------------------------------------------------

(define-map gifts
  ;; key: SHA256 hash of the secret code
  {hash-code: (buff 32)}
  {
    sender: principal,
    amount: uint,
    claimed: bool,
    expiry-block: uint
  }
)

;; --------------------
;; Error Codes
;; --------------------
(define-constant ERR_ALREADY_EXISTS (err u100))
(define-constant ERR_ALREADY_CLAIMED (err u101))
(define-constant ERR_INVALID_SECRET (err u102))
(define-constant ERR_NOT_FOUND (err u103))
(define-constant ERR_NOT_EXPIRED (err u104))
(define-constant ERR_UNAUTHORIZED (err u105))
(define-constant ERR_STX_TRANSFER_FAIL (err u106))
(define-constant ERR_INVALID_AMOUNT (err u107))
(define-constant ERR_INVALID_EXPIRY (err u108))

;; --------------------
;; Public Functions
;; --------------------

;; Create a new gift card by submitting a hash of a secret and transferring STX
(define-public (create-gift (hash-code (buff 32)) (amount uint) (expiry-block uint))
  (begin
    ;; Validate input
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> expiry-block stacks-block-height) ERR_INVALID_EXPIRY)
    (asserts! (is-none (map-get? gifts {hash-code: hash-code})) ERR_ALREADY_EXISTS)

    ;; Save the gift data
    (map-set gifts
      {hash-code: hash-code}
      {
        sender: tx-sender,
        amount: amount,
        claimed: false,
        expiry-block: expiry-block
      }
    )

    ;; Transfer the STX to the contract
    (stx-transfer? amount tx-sender (as-contract tx-sender))
  )
)

;; Redeem a gift card using the original secret code
(define-public (redeem-gift (secret (buff 32)))
  (let ((hash-code (hash160 secret)))
    (match (map-get? gifts {hash-code: hash-code})
      gift
      (if (get claimed gift)
          ERR_ALREADY_CLAIMED
          (begin
            ;; Mark as claimed
            (map-set gifts
              {hash-code: hash-code}
              (merge gift { claimed: true })
            )
            
            ;; Send funds to redeemer
            (stx-transfer? (get amount gift) (as-contract tx-sender) tx-sender)
          )
      )
      ERR_INVALID_SECRET
    )
  )
)

;; Cancel an expired and unclaimed gift, reclaim funds
(define-public (cancel-gift (hash-code (buff 32)))
  (match (map-get? gifts {hash-code: hash-code})
    gift
    (if (not (is-eq tx-sender (get sender gift))) 
        ERR_UNAUTHORIZED
        (if (get claimed gift)
            ERR_ALREADY_CLAIMED
            (if (> stacks-block-height (get expiry-block gift))
                (begin
                  (map-delete gifts {hash-code: hash-code})
                  (stx-transfer? (get amount gift) (as-contract tx-sender) (get sender gift))
                )
                ERR_NOT_EXPIRED
            )
        )
    )
    ERR_NOT_FOUND
  )
)

;; --------------------
;; Read-Only View
;; --------------------

;; View the gift card info (useful for debugging/auditing)
(define-read-only (get-gift (hash-code (buff 32)))
  (map-get? gifts {hash-code: hash-code})
)
