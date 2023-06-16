public with sharing class OSF_GetMasterAccountMostPurchased {
    //add try/catch to the method
    @AuraEnabled(cacheable=true)
    public static String getProducts(String mAccId) {
        List<Order> orders = new List<Order>();
        List<TableRow> result = new List<TableRow>();

        try {
        orders = [SELECT Id, Status, 
                            (SELECT Id, Product2Id, TotalPrice, Quantity, OrderId 
                            FROM OrderItems) 
                    FROM Order
                    WHERE Master_Account__c = :mAccId];

        List<Id> productIds = new List<Id>();
        Map<Id, TableRow> orderProducts = new Map<Id, TableRow>();
        for (Order o : orders) {
            for (OrderItem oi : o.OrderItems) {
                productIds.add(oi.Product2Id);
                            
                if (orderProducts.containsKey(oi.Product2Id)) {
                    orderProducts.get(oi.Product2Id).quantity += oi.Quantity;
                    orderProducts.get(oi.Product2Id).total += oi.TotalPrice;
                } else {
                    orderProducts.put(oi.Product2Id, new TableRow('placeholder', oi.Quantity, oi.TotalPrice));
                }
            }
        }
            
        List<Product2> products = [SELECT Id, Name 
                                FROM Product2 
                                WHERE Id IN :productIds];
            
        for (Product2 p : products) {
            orderProducts.get(p.Id).product = p.Name;
            result.add(orderProducts.get(p.Id));
        }
        } catch (Exception e) {
            System.debug('Error in OSF_GetMasterAccountsMostPurchased: ' + e.getMessage());
        }

        return JSON.serialize(result);
    }

        //usually we put such sub classes to the bottom of the main class
        public class TableRow {
            public String product;
            public Decimal quantity;
            public Decimal total;
            public TableRow(String product, Decimal quantity, Decimal total) {
                this.product = product;
                this.quantity = quantity;
                this.total = total;
            }
        }
}