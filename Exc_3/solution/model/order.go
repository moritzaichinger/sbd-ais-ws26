package model

import "time"

type Order struct {
	DrinkID   uint64    `json:"drink_id" example:"1"` // foreign key
	CreatedAt time.Time `json:"created_at" format:"date-time" example:"2026-10-21T10:00:00Z"`
	Amount    uint64    `json:"amount" example:"2"`
}
