@isTest
private class OSF_CaseTriggerTest {

    private static void init(String actionToInit) {
        switch on actionToInit {
            when 'testCaseUpdate', 'testCaseUpdateError', 'testCaseDelete', 'testUpdateCaseLanguage', 'testCreatePersonAccountFromCase' {
                List<Account> accountList = new List<Account>{new Account(LastName='Smith', PersonEmail='some@some.com', Brand__c='Force')};
                insert accountList;
        
                List<Contract> contractList = new List<Contract>{new Contract(AccountId=accountList[0].Id, Status='Draft', StartDate=Date.today(), ContractTerm=3)};
                insert contractList;
        
                List<Order> orderList = new List<Order>{new Order(AccountId=accountList[0].Id, ContractId=contractList[0].Id, Status='Draft', billingCity='Phone', EffectiveDate=Date.today().addDays(30)),
                                                        new Order(AccountId=accountList[0].Id, ContractId=contractList[0].Id, Status='Draft', billingCity='Web', EffectiveDate=Date.today().addDays(30)),
                                                        new Order(AccountId=accountList[0].Id, ContractId=contractList[0].Id, Status='Draft', billingCity='Email', EffectiveDate=Date.today().addDays(30)),
                                                        new Order(AccountId=accountList[0].Id, ContractId=contractList[0].Id, Status='Draft', billingCity='Email', EffectiveDate=Date.today().addDays(30))};
                insert orderList;
        
                List<Order> orderListAfter = [SELECT Id, OrderNumber FROM Order];
        
                List<Case> caseList = new List<Case>{new Case(AccountId=accountList[0].Id, Status='New', Origin='ForceWeb'),
                                                    new Case(AccountId=accountList[0].Id, Status='New', Origin='Phone'),
                                                    new Case(AccountId=accountList[0].Id, Status='New', Origin='ForceEmail')};
        
                insert caseList;
        
                caseList[0].Order_Number__c = orderListAfter[0].OrderNumber;
                caseList[1].Order_Number__c = null;
                caseList[2].Order_Number__c = orderListAfter[1].OrderNumber+','+orderListAfter[2].OrderNumber;
                update caseList;
            }
            when 'testAssignPersonAccountFromCase' {
                Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
                Account acc = new Account(FirstName='Other', LastName='Other', Brand__c = 'Sales', RecordTypeId=personAccountRecordTypeId, PersonEmail='other@other.com');
                insert acc;
            }
        }
    }

    @isTest static void testCaseUpdate() {
        init('testCaseUpdate');
        
        List<Order> orderList = [SELECT Id, OrderNumber, Case__c, BillingCity FROM Order];
        List<Case> caseList = [SELECT Id, Order_Number__c, Origin FROM Case];
        Map<String, Case> caseMap = new Map<String, Case>();

        Boolean emailB = false;
        for (Case c : caseList) {
            if (c.Origin == 'ForceWeb' || c.Origin == 'SalesWeb') {
                c.Order_Number__c = null;
                caseMap.put('Web', c);
            }

            for (Order o : orderList) {
                if (c.Origin == 'Phone' && o.BillingCity == 'Phone') {
                    c.Order_Number__c = o.OrderNumber;
                    caseMap.put('Phone', c);
                }

                if ((c.Origin == 'ForceEmail' || c.Origin == 'SalesEmail') && o.BillingCity == 'Email') {
                    if (!emailB) {
                        c.Order_Number__c = null;
                        emailB = true;
                    }

                    if (c.Order_Number__c == null) {
                        c.Order_Number__c = o.OrderNumber;
                    } else {
                        c.Order_Number__c = c.Order_Number__c + ',' + o.OrderNumber;
                        caseMap.put('Email', c);
                    }
                }
            }
        }
        
        Test.startTest();
        List<Database.SaveResult> result = Database.update(caseList);
        List<Order> orderListNew = [SELECT Id, OrderNumber, Case__c, BillingCity FROM Order];
        Test.stopTest();

        if (orderListNew.size() > 0) {
            for (Order o : orderListNew) {
                if (o.BillingCity == 'Web') {
                    System.assertEquals(null, o.Case__c, 'Expected case to be null.');
                }
    
                if (o.BillingCity == 'Phone') {
                    System.debug(caseMap.get('Phone').Id + ' - ' + o.Case__c);
                    System.assertEquals(caseMap.get('Phone').Id, o.Case__c, 'Expected case to be updated.');
                }
    
                if (o.BillingCity == 'Email') {
                    System.assertEquals(caseMap.get('Email').Id, o.Case__c, 'Expected case to be updated.');
                }
            }
        }

        for (Database.SaveResult r : result) {
            System.assert(r.isSuccess(), 'Expected update to succeed.');
            System.assert(r.getErrors().size() == 0, 'Expected update to succeed.');
        }
    }

    @isTest static void testCaseUpdateError() {
        init('testCaseUpdateError');

        List<Case> caseWeb = [SELECT Id, Order_Number__c, Origin FROM Case WHERE Origin = 'ForceWeb'];
        List<Case> casePhone = [SELECT Id, Order_Number__c, Origin FROM Case WHERE Origin = 'Phone'];

        casePhone[0].Order_Number__c = caseWeb[0].Order_Number__c;

        Test.startTest();
        Database.saveResult result = Database.update(casePhone[0], false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Expected update to fail');
    }

    @isTest static void testCaseDelete() {
        init('testCaseDelete');

        List<Case> caseList = [SELECT Id, Origin FROM Case WHERE Origin = 'ForceWeb'];

        Test.startTest();
        Database.deleteResult result = Database.delete(caseList[0]);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Expected delete to succeed');
    }

    @isTest static void testUpdateCaseLanguage() {
        init('testUpdateCaseLanguage');

        List<Account> accountList = [SELECT Id FROM Account];
        Case c = new Case(AccountId=accountList[0].Id, Status='New', Origin='ForceEmail', Subject = 'Testing');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DetectLanguageWrapperMock());
        Database.SaveResult result = Database.insert(c);
        Test.stopTest();

        Case cAfter = [SELECT Id, Language__c FROM CASE Where Id = :c.Id];

        System.assertEquals('English', cAfter.Language__c, 'Expected language to be updated as English');
    }

    @isTest static void testCreatePersonAccountFromCase() {
        init('testCreatePersonAccountFromCase');
        Case c = new Case(Status='New', Origin='ForceEmail', Subject = 'Testing', SuppliedEmail= 'other@other.com', SuppliedName='Other Other');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DetectLanguageWrapperMock());
        Database.SaveResult result = Database.insert(c);
        Test.stopTest();

        List<Account> accCreated = [SELECT Id, PersonEmail, Brand__c FROM Account WHERE PersonEmail = 'other@other.com'];
        List<Case> caseUpdated = [SELECT Id, AccountId, Language__c, Brand__c FROM Case WHERE Id = :c.Id];

        System.assertEquals(accCreated[0].Brand__c, caseUpdated[0].Brand__c, 'Expected case brand to be updated too');
        System.assertEquals(accCreated[0].Id, caseUpdated[0].AccountId, 'Expected case to be updated with account id');
        System.assertEquals(1, accCreated.size(), 'Expected account to be created');
    }

    @isTest static void testAssignPersonAccountFromCase() {
        init('testAssignPersonAccountFromCase');
        Account acc = [SELECT Id, Brand__c FROM Account WHERE PersonEmail = 'other@other.com'];

        Case c = new Case(Status='New', Origin='SalesEmail', Subject = 'Testing', SuppliedEmail= 'other@other.com', SuppliedName='Other Other');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DetectLanguageWrapperMock());
        Database.SaveResult result = Database.insert(c);
        Test.stopTest();

        List<Case> caseUpdated = [SELECT Id, AccountId, Language__c, Brand__c FROM Case WHERE Id = :c.Id];

        System.assertEquals(acc.Brand__c, caseUpdated[0].Brand__c, 'Expected case brand to be updated too');
        System.assertEquals(acc.Id, caseUpdated[0].AccountId, 'Expected case to be updated with account id');
    }
}