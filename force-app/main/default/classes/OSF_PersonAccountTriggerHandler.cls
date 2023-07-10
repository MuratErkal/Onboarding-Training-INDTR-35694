public with sharing class OSF_PersonAccountTriggerHandler implements OSF_TriggerHandler {
    private static final String EXISTING_ACCOUNT_ERROR_STRING = 'Email is in use with the same brand, please use another email or brand.';

    public OSF_PersonAccountTriggerHelper helper;
    
    public OSF_PersonAccountTriggerHandler() {
        this.helper = new OSF_PersonAccountTriggerHelper();
    }

    public void beforeInsert(List<Account> newAccounts) {
        //get person accounts
        List<Account> newPersonAccounts = new List<Account>();
        newPersonAccounts = helper.filterPersonAccounts(newAccounts);

        //if person accounts list isn't empty, continue.
        if (newPersonAccounts.size() > 0) {
            //map the person accounts list with their personemails.
            Map<String, List<Account>> personAccountMap = new Map<String, List<Account>>();
            personAccountMap = helper.getPersonAccountMap(newPersonAccounts);

            //get the master accounts and their person accounts
            List<Master_Account__c> masterAccounts = new List<Master_Account__c>();
            masterAccounts = helper.getMasterAccounts(personAccountMap.keyset());

            if (masterAccounts.size() > 0) {
                helper.updateFilteredPersonAccounts(personAccountMap, masterAccounts);
            } else {
                helper.createMasterAccounts(personAccountMap);
            }
        }
    }

    public void beforeUpdate(List<Account> oldAccounts, List<Account> newAccounts, 
                            Map<ID, SObject> oldAccountMap, Map<ID, SObject> newAccountMap) {
        //get person accounts
        List<Account> oldPersonAccounts = new List<Account>();
        List<Account> newPersonAccounts = new List<Account>();
        oldPersonAccounts = helper.filterPersonAccounts(oldAccounts);
        newPersonAccounts = helper.filterPersonAccounts(newAccounts);

        if (newPersonAccounts.size() > 0) {
            List<Account> updatedPersonAccounts = new List<Account>();
            List<Account> updatedPersonAccountsOld = new List<Account>();
            List<Account> brandUpdatedPersonAccounts = new List<Account>();

            for (Integer i = 0; i < newPersonAccounts.size(); i++) {
                //check if email was changed
                if (oldPersonAccounts[i].PersonEmail != newPersonAccounts[i].PersonEmail) {
                    updatedPersonAccounts.add(newPersonAccounts[i]);
                    updatedPersonAccountsOld.add(oldPersonAccounts[i]);
                //check if brand was changed
                } else if (oldPersonAccounts[i].Brand__c != newPersonAccounts[i].Brand__c) {
                    brandUpdatedPersonAccounts.add(newPersonAccounts[i]);
                }
            }

            if (updatedPersonAccounts.size() > 0 ) {
                Map<String, List<Account>> updatedPersonAccountMap = new Map<String, List<Account>>();
                updatedPersonAccountMap = helper.getPersonAccountMap(updatedPersonAccounts);

                //get the master accounts and their person accounts
                List<Master_Account__c> masterAccounts = new List<Master_Account__c>();
                masterAccounts = helper.getMasterAccounts(updatedPersonAccountMap.keyset());

                if (masterAccounts.size() > 0) {
                    helper.updateFilteredPersonAccounts(updatedPersonAccountMap, masterAccounts);
                } else {
                    helper.createMasterAccounts(updatedPersonAccountMap);
                }
            }

            if (brandUpdatedPersonAccounts.size() > 0) {
                Map<String, List<Account>> brandUpdatedPersonAccountMap = new Map<String, List<Account>>();
                brandUpdatedPersonAccountMap = helper.getPersonAccountMap(brandUpdatedPersonAccounts);

                //get the master accounts and their person accounts
                List<Master_Account__c> brandMasterAccounts = new List<Master_Account__c>();
                brandMasterAccounts = helper.getMasterAccounts(brandUpdatedPersonAccountMap.keyset());

                for (Master_Account__c mAcc : brandMasterAccounts) {
                    for (Account acc : brandUpdatedPersonAccounts) {
                        for (Account pAcc : mAcc.PersonAccounts__r) {
                            if (pAcc.Brand__c == acc.Brand__c) {
                                //please use constants for errors
                                acc.addError(EXISTING_ACCOUNT_ERROR_STRING);
                            }
                        }
                    }              
                }
            }
        }
    }
    
    public void beforeDelete(List<Account> oldAccounts, Map<ID, SObject> oldAccountMap) {
    }

    public void afterInsert(List<Account> newAccounts, Map<ID, SObject> newAccountMap) {
    }

    public void afterUpdate(List<Account> oldAccounts, List<Account> newAccounts, Map<ID, SObject> oldAccountMap, Map<ID, SObject> newAccountMap) {
        helper.deleteEmptyMasterAccounts(oldAccounts);
    }

    public void afterDelete(List<Account> oldAccounts, Map<ID, SObject> oldAccountMap) {
        helper.deleteEmptyMasterAccounts(oldAccounts);
    }

    public void afterUndelete(List<Account> newAccounts, Map<ID, SObject> newAccountMap) {
    }
}