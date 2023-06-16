public without sharing class OSF_OrderTriggerHelper {
    public OSF_OrderTriggerHelper() {
        System.debug('Inside AccountTriggerHelper Constructor');
    }

    public void addMasterAccountId(List<Order> newOrders) {
        List<Id> accountIds = new List<Id>();
        for (Order order : newOrders) {
            accountIds.add(order.AccountId);
        }

        List<Account> personAccounts = new List<Account>();
        try {
            personAccounts = [SELECT Id, Master_Account__c 
                                        FROM Account WHERE Id IN :accountIds
                                        AND IsPersonAccount = true];
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        

        for (Order order : newOrders) {
            for (Account acc : personAccounts) {
                if (order.AccountId == acc.Id) {
                    order.Master_Account__c = acc.Master_Account__c;
                }
            }
        }
    }

    public void handleEmailChange(List<Order> oldOrders, List<Order> newOrders) {
        List<Order> ordersToUpdate = new List<Order>();
        List<Id> accountIds = new List<Id>();
        List<Id> contractIds = new List<Id>();

        for (Integer i = 0; i < newOrders.size(); i++) {
            if (newOrders[i].ContractId != oldOrders[i].ContractId) {
                ordersToUpdate.add(newOrders[i]);
                contractIds.add(newOrders[i].ContractId);
            }
        }

        List<Contract> contracts = new List<Contract>();
        try {
            contracts = [SELECT Id, AccountId
                                  FROM Contract
                                  WHERE Id IN :contractIds];
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        

        for (Contract contract : contracts) {
            accountIds.add(contract.AccountId);
        }

        List<Account> accounts = new List<Account>();
        try {
            accounts = [SELECT Id, Master_Account__c
                                  FROM Account
                                  WHERE Id IN :accountIds
                                  AND IsPersonAccount = true];
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }

            for (Contract contract : contracts) {
                for (Order order : ordersToUpdate) {
                    for (Account acc : accounts) {
                        if (contract.Id == order.ContractId && contract.AccountId == acc.Id) {
                            order.AccountId = contract.AccountId;
                            order.Master_Account__c = acc.Master_Account__c;
                        }
                    }
                }
            }
    } 
}