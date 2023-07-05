trigger OSF_ContractTrigger on Contract (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (Org_Specific_Setting__mdt.getInstance('Run_All_Triggers')?.Value__c) {
        // OSF_TriggerHandler handler = new OSF_OrderTriggerHandler(Trigger.isExecuting, Trigger.size);
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                // handler.beforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
            }
            when BEFORE_DELETE {
                // handler.beforeDelete(Trigger.old, Trigger.oldMap);
            }
            when AFTER_INSERT {
                // handler.afterInsert(Trigger.new, Trigger.newMap);
            }
            when AFTER_UPDATE {
                List<Contract> updatedContracts = new List<Contract>();
                List<Id> accountIds = new List<Id>();

                for (Integer i = 0; i < Trigger.new.size(); i++) {
                    if (Trigger.new[i].AccountId != Trigger.old[i].AccountId) {
                        updatedContracts.add(Trigger.new[i]);
                        accountIds.add(Trigger.new[i].AccountId);
                    }
                }

                List<Account> accounts = new List<Account>();
                List<Order> orders = new List<Order>();
                try {
                    accounts = [SELECT Id, Master_Account__c FROM Account WHERE Id IN :accountIds AND IsPersonAccount = true];
                    orders = [SELECT Id, Master_Account__c, ContractId FROM Order WHERE ContractId IN :updatedContracts];

                    for (Contract contract : updatedContracts) {
                        for (Order order : orders) {
                            for (Account acc : accounts) {
                                if (contract.Id == order.ContractId && contract.AccountId == acc.Id) {
                                    order.AccountId = contract.AccountId;
                                    order.Master_Account__c = acc.Master_Account__c;
                                }
                            }
                        }
                    }
    
                    update orders;
                } catch (Exception e) {
                    System.debug('Error in OSF_ContractTrigger:' + e.getMessage());
                }
            }
            when AFTER_DELETE {
                // handler.afterDelete(Trigger.old, Trigger.oldMap);
            }
            when AFTER_UNDELETE {
                // handler.afterUndelete(Trigger.new, Trigger.newMap);
            }
        }
    }
}