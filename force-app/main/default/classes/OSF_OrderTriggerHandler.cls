public with sharing class OSF_OrderTriggerHandler implements OSF_TriggerHandler {
    public OSF_OrderTriggerHelper helper;

    public OSF_OrderTriggerHandler() {
        this.helper = new OSF_OrderTriggerHelper();
    }

    public void beforeInsert(List<Order> newOrders) {
        helper.addMasterAccountId(newOrders);
    }

    public void beforeUpdate(List<Order> oldOrders, List<Order> newOrders, 
                            Map<ID, SObject> oldOrderMap, Map<ID, SObject> newOrderMap) {
        helper.handleEmailChange(oldOrders, newOrders);
    }
    
    public void beforeDelete(List<Order> oldOrders, Map<ID, SObject> oldOrderMap) {
    }

    public void afterInsert(List<Order> newOrders, Map<ID, SObject> newOrderMap) {
    }

    public void afterUpdate(List<Order> oldOrders, List<Order> newOrders, Map<ID, SObject> oldOrderMap, Map<ID, SObject> newOrderMap) {
    }

    public void afterDelete(List<Order> oldOrders, Map<ID, SObject> oldOrderMap) {
    }

    public void afterUndelete(List<Order> newOrders, Map<ID, SObject> newOrderMap) {
    }
}