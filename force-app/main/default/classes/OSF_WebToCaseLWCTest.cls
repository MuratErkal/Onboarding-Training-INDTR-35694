@isTest
private class OSF_WebToCaseLWCTest {
    private static void init(String actionToInit) {
        switch on actionToInit {
            when 'testGetCases' {
                List<Account> accountList = new List<Account>{new Account(LastName='Smith', PersonEmail='some@some.com', Brand__c='Force')};
                insert accountList;
        
                List<Case> caseList = new List<Case>{new Case(AccountId=accountList[0].Id, SuppliedEmail = accountList[0].PersonEmail, Status='New', Origin='ForceWeb'),
                                                    new Case(AccountId=accountList[0].Id, SuppliedEmail = accountList[0].PersonEmail, Status='New', Origin='Phone'),
                                                    new Case(AccountId=accountList[0].Id, SuppliedEmail = accountList[0].PersonEmail, Status='New', Origin='ForceEmail')};
        
                insert caseList;
            }
        }
    }

    @isTest static void testGetCases() {
        init('testGetCases');

        List<Account> accList = [SELECT Id, PersonEmail, Brand__c FROM Account];

        Test.startTest();
        List<Case> caseList = OSF_WebToCaseLWC.getCases(accList[0].PersonEmail, accList[0].Brand__c);
        Test.stopTest();

        System.assertEquals(3, caseList.size(), 'Expected the cases to be fetched.');
    }

    @isTest static void testGetMetadata() {
        Test.startTest();
        OSF_WtC_Form__mdt forceResult = OSF_WebToCaseLWC.getMetadata('Force');
        OSF_WtC_Form__mdt salesResult = OSF_WebToCaseLWC.getMetadata('Sales');
        Test.stopTest();

        System.assertEquals(7, forceResult.OSF_WtC_Form_Fields__r.size(), 'Expected the correct metadata to be fetched');
        System.assertEquals(7, salesResult.OSF_WtC_Form_Fields__r.size(), 'Expected the correct metadata to be fetched');
    }
}