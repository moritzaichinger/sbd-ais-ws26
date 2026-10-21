package repository

import (
	"ordersystem/model"
	"time"
)

type DatabaseHandler struct {
	// drinks represent all available drinks
	drinks []model.Drink
	// orders serves as order history
	orders []model.Order
}

func NewDatabaseHandler() *DatabaseHandler {
	drinks := []model.Drink{
		{ID: 1, Name: "Beer", Price: 4.00, Description: "Kaiser"},
		{ID: 2, Name: "Spritzer", Price: 3.50, Description: "Wine with soda"},
		{ID: 3, Name: "Coffee", Price: 0.00, Description: "A cup of coffee"},
	}

	now := time.Now()
	orders := []model.Order{
		{DrinkID: 1, CreatedAt: now.Add(-2 * time.Hour), Amount: 2},
		{DrinkID: 2, CreatedAt: now.Add(-time.Hour), Amount: 1},
		{DrinkID: 1, CreatedAt: now, Amount: 3},
	}

	return &DatabaseHandler{
		drinks: drinks,
		orders: orders,
	}
}

func (db *DatabaseHandler) GetDrinks() []model.Drink {
	return db.drinks
}

func (db *DatabaseHandler) GetOrders() []model.Order {
	return db.orders
}

func (db *DatabaseHandler) GetTotalledOrders() map[uint64]uint64 {
	// key = drink ID, value = total quantity ordered
	totalledOrders := make(map[uint64]uint64)
	for _, order := range db.orders {
		totalledOrders[order.DrinkID] += order.Amount
	}
	return totalledOrders
}

func (db *DatabaseHandler) AddOrder(order *model.Order) {
	db.orders = append(db.orders, *order)
}
