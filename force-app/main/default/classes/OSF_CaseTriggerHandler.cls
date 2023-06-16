public without sharing class OSF_CaseTriggerHandler implements OSF_TriggerHandler {
    public OSF_CaseTriggerHelper helper;
    private static final String FORCE_EMAIL_STRING = 'ForceEmail';
    private static final String FORCE_WEB_STRING = 'ForceWeb';
    private static final String SALES_EMAIL_STRING = 'SalesEmail';
    private static final String SALES_WEB_STRING = 'SalesWeb';

    public OSF_CaseTriggerHandler() {
        this.helper = new OSF_CaseTriggerHelper();
    }

    public void beforeInsert(List<Case> newCases) {
        List<Case> casesToCreatePersonAccountsFrom = new List<Case>();
        for (Case c : newCases) {
            if(c.AccountId == null && (c.Origin == FORCE_EMAIL_STRING || c.Origin == SALES_EMAIL_STRING || c.Origin == FORCE_WEB_STRING || c.Origin == SALES_WEB_STRING)) {
                casesToCreatePersonAccountsFrom.add(c);
            }
        }

        if (casesToCreatePersonAccountsFrom.size() > 0) {
            helper.createPersonAccountsFromCases(casesToCreatePersonAccountsFrom, false);
        }
    }

    public void beforeUpdate(List<Case> oldCases, List<Case> newCases, Map<ID, SObject> oldCaseMap, Map<ID, SObject> newCaseMap) {
        if (System.isFuture()) {
            return;
        }
        
        Map<String, Map<String, Case>> ordersToUpdateMap = new Map<String, Map<String, Case>>();
        ordersToUpdateMap = helper.getOrdersToUpdateMap(oldCases, newCases);
        helper.updateOrders(ordersToUpdateMap);
    }
    
    public void beforeDelete(List<Case> oldCases, Map<ID, SObject> oldCaseMap) {
    }

    public void afterInsert(List<Case> newCases, Map<ID, SObject> newCaseMap) {
        if (System.isFuture()) {
            return;
        }
        Map<String, List<Case>> casesByOriginMapNew = helper.filterCasesByOrigin(newCases);

        if (casesByOriginMapNew.get('Email').size() > 0) {

            List<Case> emailCasesToUpdateLang = helper.getEmailCasesToUpdateLang(casesByOriginMapNew.get('Email'));
        
            if (emailCasesToUpdateLang.size() > 0) {
                Set<Id> emailCasesToUpdateLangIds = (new Map<Id,Case>(emailCasesToUpdateLang)).keySet();
                OSF_CaseTriggerHelper.updateEmailCasesLang(emailCasesToUpdateLangIds);
            }
        }
    }

    public void afterUpdate(List<Case> oldCases, List<Case> newCases, Map<ID, SObject> oldCaseMap, Map<ID, SObject> newCaseMap) {
    }

    public void afterDelete(List<Case> oldCases, Map<ID, SObject> oldCaseMap) {
    }

    public void afterUndelete(List<Case> newCases, Map<ID, SObject> newCaseMap) {
    }
}