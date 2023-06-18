public without sharing class OSF_CaseTriggerHelper {
    private static String FORCE_EMAIL_STRING = 'ForceEmail';
    private static String FORCE_WEB_STRING = 'ForceWeb';
    private static String SALES_EMAIL_STRING = 'SalesEmail';
    private static String SALES_WEB_STRING = 'SalesWeb';
    private static final String FORCE_STRING = 'Force';
    private static final String SALES_STRING = 'Sales';
    private static final String ADD_STRING = 'add';
    private static final String REMOVE_STRING = 'remove';

    private static final String PHONE_STRING = 'Phone';
    private static final String EMAIL_STRING = 'Email';
    private static final String WEB_STRING = 'Web';
    
    private static final String DETECT_LANGUAGE_ENDPOINT = 'https://ws.detectlanguage.com/0.2/detect?q=';
    private static final String DETECT_LANGUAGE_API_KEY = '0ab78e61f04de6d1b65257de7a3cfec5';
    private static final String ENGLISH_STRING = 'English';
    private static final String GERMAN_STRING = 'German';

    private static final String ONE_CASE_ALLOWED_ERROR_STRING = 'An order can only have one case.';
    private static final String ORDER_NUMBER_ERROR_STRING = 'Order numbers must be 8 characters.';

    public OSF_CaseTriggerHelper() {
        System.debug('Inside AccountTriggerHelper Constructor');
    }

    public Map<String, List<Case>> filterCasesByOrigin(List<Case> caseList) {
        Map<String, List<Case>> caseMapByOrigin = new Map<String, List<Case>>();
        List<Case> webCases = new List<Case>();
        List<Case> emailCases = new List<Case>();
        List<Case> phoneCases = new List<Case>();

        for (Case c : caseList) {
            if (c.Origin == FORCE_WEB_STRING || c.Origin == SALES_WEB_STRING) {
                webCases.add(c);
            }

            if (c.Origin == FORCE_EMAIL_STRING || c.Origin == SALES_EMAIL_STRING) {
                emailCases.add(c);
            }
            
            if (c.Origin == PHONE_STRING) {
                phoneCases.add(c);
            }
        }

        caseMapByOrigin.put(WEB_STRING, webCases);
        caseMapByOrigin.put(EMAIL_STRING, emailCases);
        caseMapByOrigin.put(PHONE_STRING, phoneCases);

        return caseMapByOrigin;
    }

    public List<Case> getEmailCasesToUpdateLang(List<Case> newEmailCases) {
        List<Case> emailCasesToUpdateLang = new List<Case>();

        for (Integer i = 0; i < newEmailCases.size(); i++) {
            // if (oldEmailCases[i].SourceId == null && newEmailCases[i].SourceId != null) {
                emailCasesToUpdateLang.add(newEmailCases[i]);
            // }
        }

        return emailCasesToUpdateLang;
    }

    @future(callout=true)
    public static void updateEmailCasesLang(Set<Id> emailCasesToUpdateLangIds) {
        List<Case> emailCasesToUpdateLang = [SELECT Id, Description, Subject, Language__c FROM Case WHERE Id IN :emailCasesToUpdateLangIds];

        for (Case c : emailCasesToUpdateLang) {
            String lang;
            if (c.Description == null && c.Subject == null) {
                lang = ENGLISH_STRING;
            } else {
                String text = c.Description == null ? c.Subject : c.Description;
                String endpoint = DETECT_LANGUAGE_ENDPOINT + EncodingUtil.urlEncode(text,'UTF-8');
                
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + DETECT_LANGUAGE_API_KEY);
                HttpResponse res = h.send(req);
                if (res.getStatusCode() == 200) {
                    DetectLanguageWrapper result = DetectLanguageWrapper.parse(res.getBody());
                    String resultLang = result.data.detections[0]?.language;
                    lang = resultLang == 'de' ? GERMAN_STRING : ENGLISH_STRING;
                }
            }
            c.Language__c = lang;
        }

        List<Database.SaveResult> results = Database.update(emailCasesToUpdateLang, false);
    }

    public void createPersonAccountsFromCases(List<Case> cases, Boolean updateManually) {
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

        List<String> emailsToCheck = new List<String>();
        for (Case c : cases) {
            if (c.AccountId == null && c.SuppliedEmail != null) {
                emailsToCheck.add(c.SuppliedEmail);
            }
        }

        List<Account> accountsToCheck = [SELECT Id, PersonEmail, Brand__c FROM Account WHERE PersonEmail IN :emailsToCheck];

        Map<String, List<Account>> accountsToCheckMap = getAccountsToCheckMap(accountsToCheck);

        List<Case> casesToUpdate = new List<Case>();
        List<Case> casesToCreatePersonAccounts = new List<Case>();

        if (accountsToCheckMap.size() > 0) {
            for (String aEmail : accountsToCheckMap.keySet()) {
                for (Case c : cases) {
                    List<Account> accounts = accountsToCheckMap.get(aEmail);
                    String caseBrand = getCaseBrand(c.Origin);
    
                    if (accounts.size() == 2) {
                        for (Account acc : accounts) {
                            if (acc.PersonEmail == c.SuppliedEmail && acc.Brand__c == caseBrand) {
                                c.ContactId = null;
                                c.AccountId = acc.Id;
                                casesToUpdate.add(c);
                            }
                        }
                    } else if (accounts.size() == 1) {
                        if (accounts[0].PersonEmail == c.SuppliedEmail && accounts[0].Brand__c == caseBrand) {
                            c.ContactId = null;
                            c.AccountId = accounts[0].Id;
                            casesToUpdate.add(c);
                        } else {
                            casesToCreatePersonAccounts.add(c);
                        }
                    } else {
                        casesToCreatePersonAccounts.add(c);
                    }
                }
            }
        } else {
            casesToCreatePersonAccounts = cases;
        }

        List<Account> personAccountsToCreate = new List<Account>();
        for (Case c : casesToCreatePersonAccounts) {
            List<String> names = c.SuppliedName.split(' ');

            Account a = new Account();
            a.RecordTypeId = personAccountRecordTypeId;

            if (names.size() == 1) {
                a.LastName = c.SuppliedName;
            } else {
                for (Integer i = 0; i < names.size(); i++) {
                    if (i == names.size() - 1) {
                        a.LastName = names[i];
                    } else {
                        a.FirstName = a.FirstName == null ? names[i] : a.FirstName + ' ' + names[i];
                    }
                }
            }

            a.PersonEmail = c.SuppliedEmail;
            a.Brand__c = getCaseBrand(c.Origin);
            personAccountsToCreate.add(a);
        }

        if(personAccountsToCreate.size() > 0) {
            
            insert personAccountsToCreate;
            
            for (Account a : personAccountsToCreate) {
                for (Case c : casesToCreatePersonAccounts) {
                    if (a.PersonEmail == c.SuppliedEmail && a.Brand__c == getCaseBrand(c.Origin)) {
                        c.ContactId = null;
                        c.AccountId = a.Id;
                        casesToUpdate.add(c);
                    }
                }
            }
        }


        if (updateManually) {
            update casesToUpdate;
        }
    }

    public Map<String, List<Account>> getAccountsToCheckMap(List<Account> accountsToCheck) {
        Map<String, List<Account>> accountsToCheckMap = new Map<String, List<Account>>();
        for (Account a : accountsToCheck) {
            if (accountsToCheckMap.containsKey(a.PersonEmail)) {
                accountsToCheckMap.get(a.PersonEmail).add(a);
            } else {
                accountsToCheckMap.put(a.PersonEmail, new List<Account>{a});
            }
        }
        return accountsToCheckMap;
    }

    public String getCaseBrand(String caseOrigin) {
        String caseBrand;
        if (caseOrigin == FORCE_EMAIL_STRING || caseOrigin == FORCE_WEB_STRING) {
            caseBrand = FORCE_STRING;
        } else if (caseOrigin == SALES_EMAIL_STRING || caseOrigin == SALES_WEB_STRING) {
            caseBrand = SALES_STRING;
        }
        return caseBrand;
    }

    public Map<String, Map<String, Case>> getOrdersToUpdateMap(List<Case> oldCases, List<Case> newCases) {
        Map<String, Map<String, Case>> ordersToUpdateMap = new Map<String, Map<String, Case>>();
        ordersToUpdateMap.put(ADD_STRING, new Map<String, Case>());
        ordersToUpdateMap.put(REMOVE_STRING, new Map<String, Case>());

        for (Integer i = 0; i < oldCases.size(); i++) {

            if (oldCases[i].Order_Number__c != newCases[i].Order_Number__c) {

                if (validateOrderNumber(newCases[i])) {

                    //if was empty but now not
                    if (oldCases[i].Order_Number__c == null && newCases[i].Order_Number__c != null) {
                        for (String orderNumber : getOrderNumbers(newCases[i])) {
                            if (ordersToUpdateMap.get(ADD_STRING).containsKey(orderNumber)) {
                                newCases[i].addError(ONE_CASE_ALLOWED_ERROR_STRING);
                            } else {
                                ordersToUpdateMap.get(ADD_STRING).put(orderNumber, newCases[i]);
                            }
                        }
                    } 

                    //if wasn't empty but now empty
                    else if (oldCases[i].Order_Number__c != null && newCases[i].Order_Number__c == null) {
                        for (String orderNumber : getOrderNumbers(oldCases[i])) {
                            ordersToUpdateMap.get(REMOVE_STRING).put(orderNumber, oldCases[i]);
                        }
                    }

                    //if orders was changed
                    else {
                        List<String> oldOrderNumbers = getOrderNumbers(oldCases[i]);
                        List<String> newOrderNumbers = getOrderNumbers(newCases[i]);
                        
                        for (String newOrderNumber : newOrderNumbers) {
                            if (!oldOrderNumbers.contains(newOrderNumber)) {
                                if (ordersToUpdateMap.get(ADD_STRING).containsKey(newOrderNumber)) {
                                    newCases[i].addError(ONE_CASE_ALLOWED_ERROR_STRING);
                                } else {
                                    ordersToUpdateMap.get(ADD_STRING).put(newOrderNumber, newCases[i]);
                                }
                            }

                            for (String oldOrderNumber : oldOrderNumbers) {
                                if (!newOrderNumbers.contains(oldOrderNumber)) {
                                    ordersToUpdateMap.get(REMOVE_STRING).put(oldOrderNumber, oldCases[i]);
                                }
                            }
                        }
                    }
                } else {
                    newCases[i].addError(ORDER_NUMBER_ERROR_STRING);
                }
            }
        }
        return ordersToUpdateMap;
    }

    public void updateOrders(Map<String, Map<String, Case>> ordersToUpdateMap) {
        try {
            //Remove case relations from orders.
            List<Order> ordersToRemove = [SELECT Id, Case__c, OrderNumber FROM Order WHERE OrderNumber IN :ordersToUpdateMap.get(REMOVE_STRING).keySet()];
            for (Order order : ordersToRemove) {
                order.Case__c = null;
            }
            update ordersToRemove;

            //check if orders already have a case and add them to the case if not.
            List<Order> ordersToCheck = [SELECT Id, Case__c, OrderNumber FROM Order WHERE OrderNumber IN :ordersToUpdateMap.get(ADD_STRING).keySet()];
            List<Order> ordersToAdd = new List<Order>();
            for (Order order : ordersToCheck) {
                if (order.Case__c != null) {
                    Case caseToFail = ordersToUpdateMap.get(ADD_STRING).get(order.OrderNumber);
                    caseToFail.addError(getOneCasePerOrderErrorString(String.valueOf(order.OrderNumber)));
                } else {
                    order.Case__c = ordersToUpdateMap.get(ADD_STRING).get(order.OrderNumber).Id;
                    ordersToadd.add(order);
                }
            }
            update ordersToAdd;

        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage());
        }
    }

    public String getOneCasePerOrderErrorString(String orderNumber) {
        return 'An order can only have one case. Please remove the order (' + orderNumber + ') from the other case.';
    }

    public Boolean validateOrderNumber(Case c) {
        if (c.Order_Number__c != null) {
            for (String orderNumber : getOrderNumbers(c)) {
                if (orderNumber.length() > 8 || orderNumber.length() < 8) {
                    return false;
                }
            }
        }
        return true;
    }

    public List<String> getOrderNumbers(Case c) {
        return c.Order_Number__c.split(',');
    }
}