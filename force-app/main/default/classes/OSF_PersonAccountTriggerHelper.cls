public without sharing class OSF_PersonAccountTriggerHelper {
    private static final String EXISTING_ACCOUNT_ERROR_STRING = 'Email is in use with the same brand, please use another email or brand.';
    private static final String BRAND_REQUIRED_ERROR_STRING = 'Brand is required.';
    private static final String EMAIL_REQUIRED_ERROR_STRING = 'Email is required.';
    private static final String PERSON_ACCOUNTS_WITH_MASTER_STRING = 'pAccsWithMasterMap';
    private static final String PERSON_ACCOUNTS_WITHOUT_MASTER_STRING = 'pAccsWithoutMasterMap';

    public OSF_PersonAccountTriggerHelper() {
        System.debug('Inside AccountTriggerHelper Constructor');
    }

    public List<Account> filterPersonAccounts(List<Account> accountList) {
        List<Account> newPersonAccounts = new List<Account>();

        for (Account acc : accountList) {
            if (acc.isPersonAccount) {
                newPersonAccounts.add(acc);
            }
        }

        return newPersonAccounts;
    }

    public Map<String, List<Account>> getPersonAccountMap(List<Account> accountList) {
        Map<String, List<Account>> personAccountMap = new Map<String, List<Account>>();

        for (Account acc : accountList) {
            if (String.isEmpty(acc.Brand__c)) {
                acc.addError(BRAND_REQUIRED_ERROR_STRING);
            }

            if (String.isEmpty(acc.PersonEmail)) {
                acc.addError(EMAIL_REQUIRED_ERROR_STRING);
            }

            if (personAccountMap.containsKey(acc.PersonEmail)) {
                for (Account pAcc : personAccountMap.get(acc.PersonEmail)) {
                    if (pAcc.Brand__c == acc.Brand__c) {
                        acc.addError(EXISTING_ACCOUNT_ERROR_STRING);
                    }
                }
                personAccountMap.get(acc.PersonEmail).add(acc);
            } else {
                List<Account> accList = new List<Account>();
                accList.add(acc);
                personAccountMap.put(acc.PersonEmail, accList);
            }
        }
        return personAccountMap;
    }

    public List<Master_Account__c> getMasterAccounts(Set<String> emailSet) {
        List<Master_Account__c> masterAccounts = new List<Master_Account__c>();
        try {
            masterAccounts = [
            SELECT Id, Email__c, Name, 
                   (SELECT Id, Brand__c, PersonEmail FROM PersonAccounts__r) 
            FROM Master_Account__c
            WHERE Email__c IN :emailSet];
        } catch (Exception e) {
            System.debug('Error ---> ' + e.getMessage());
        }
        return masterAccounts;
    }

    public void checkForDuplicatePersonAccounts(Map<String, List<Account>> personAccountMap, List<Master_Account__c> masterAccounts) {
        
        for (Master_Account__c mAcc : masterAccounts) {
            for (Account acc : personAccountMap.get(mAcc.Email__c)) {
                for (Account pAcc : mAcc.PersonAccounts__r) {
                    //check for duplicates.
                    
                    if (pAcc.PersonEmail == acc.PersonEmail && pAcc.Brand__c == acc.Brand__c) {
                        acc.addError(EXISTING_ACCOUNT_ERROR_STRING);
                    }

                    //update the ones that aren't a duplicate.
                    acc.Master_Account__c = mAcc.Id;
                }
            }
        }
    }

    public void createMasterAccounts(Map<String, List<Account>> personAccountMap) {

        List<Master_Account__c> masterAccountList = new List<Master_Account__c>();
        //create a new master account for each person email.
        for (String email : personAccountMap.keyset()) {
            Master_Account__c masterAccount = new Master_Account__c();
            masterAccount.Name = email;
            masterAccount.Email__c = email;
            masterAccountList.add(masterAccount);
        }
        
        try {
            insert masterAccountList;
        } catch (Exception e) {
            System.debug('Error --> ' + e.getMessage());
        }

        //update the person accounts' corresponding field.
        for (Master_Account__c mAcc : masterAccountList) {
            for (Account pAcc : personAccountMap.get(mAcc.Email__c)) {
                pAcc.Master_Account__c = mAcc.Id;
            }
        }
    }

    public Map<String, Map<String, List<Account>>> filterPersonAccountsByMasterAccounts(Map<String, List<Account>> personAccountsMap,
                                                                                        List<Master_Account__c> masterAccounts) {
        Map<String, Map<String, List<Account>>> resultMap = new Map<String, Map<String, List<Account>>>();
        Map<String, List<Account>> pAccsWithMasterMap = new Map<String, List<Account>>();
        Map<String, List<Account>> pAccsWithoutMasterMap = new Map<String, List<Account>>();

        //check if there are any person accounts with the same email as the master accounts.
        for (Master_Account__c mAcc : masterAccounts) {
            if (personAccountsMap.containsKey(mAcc.Email__c)) {
                pAccsWithMasterMap.put(mAcc.Email__c, personAccountsMap.get(mAcc.Email__c));
            } else {
                pAccsWithoutMasterMap.put(mAcc.Email__c, personAccountsMap.get(mAcc.Email__c));
            }
        }
        
        resultMap.put(PERSON_ACCOUNTS_WITH_MASTER_STRING, pAccsWithMasterMap);
        resultMap.put(PERSON_ACCOUNTS_WITHOUT_MASTER_STRING, pAccsWithoutMasterMap);
        return resultMap;
    }

    public void updateFilteredPersonAccounts(Map<String, List<Account>> updatedPersonAccountMap, List<Master_Account__c> masterAccounts) {
        //filter the person accounts as "those who has master account" and "ones that dont".
        Map<String, Map<String, List<Account>>> resultMap = new Map<String, Map<String, List<Account>>>();
        resultMap = filterPersonAccountsByMasterAccounts(updatedPersonAccountMap, masterAccounts);
        
        if (resultMap.get(PERSON_ACCOUNTS_WITH_MASTER_STRING).size() > 0) {
            //if there is an existing person account with the same email and brand, throw an error.
            //else, update the master account field.
            checkForDuplicatePersonAccounts(resultMap.get(PERSON_ACCOUNTS_WITH_MASTER_STRING), masterAccounts);
        }
            
        if (resultMap.get(PERSON_ACCOUNTS_WITHOUT_MASTER_STRING).size() > 0) {
            //create master accounts and update the person accounts' corresponding field.
            createMasterAccounts(resultMap.get(PERSON_ACCOUNTS_WITHOUT_MASTER_STRING));
        }
    }

    public void deleteEmptyMasterAccounts(List<Account> oldAccounts) {
        List<Id> oldMasterAccountIds = new List<Id>();
        for (Account acc : oldAccounts) {
            oldMasterAccountIds.add(acc.Master_Account__c);
        }

        //get old master accounts
        try {
            List<Master_Account__c> masterAccounts = [SELECT Id, Email__c, Name, 
                                                        (SELECT Id, Brand__c, PersonEmail FROM PersonAccounts__r) 
                                                    FROM Master_Account__c
                                                    WHERE Id IN :oldMasterAccountIds];
            List<Master_Account__c> masterAccountsToDelete = new List<Master_Account__c>();

            //check if there's any empty ones, if so, delete them.
            for (Master_Account__c mAcc : masterAccounts) {
                if (mAcc.PersonAccounts__r.size() == 0) {
                    masterAccountsToDelete.add(mAcc);
                }
            }

            delete masterAccountsToDelete;
        } catch (Exception e) {
            System.debug('Error ---> ' + e.getMessage());
        }
    }
}