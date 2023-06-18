@isTest
private class OSF_ContractTriggerTest {

    private static void init(String actionToInit) {
        switch on actionToInit {
            when 'testContractUpdate', 'testContractDelete' {
                List<Account> accountList = new List<Account>{new Account(LastName='Smith', PersonEmail='some@some.com', Brand__c='Force'),
                                                             new Account(LastName='Wall', PersonEmail='any@any.com', Brand__c='Force')};
                insert accountList;
        
                List<Contract> contractList = new List<Contract>{new Contract(AccountId=accountList[0].Id, Status='Draft', StartDate=Date.today(), ContractTerm=3),
                                                                new Contract(AccountId=accountList[1].Id, Status='Draft', StartDate=Date.today(), ContractTerm=3)};
                insert contractList;
        
                List<Order> orderList = new List<Order>{new Order(AccountId=accountList[0].Id, ContractId=contractList[0].Id, Status='Draft', EffectiveDate=Date.today().addDays(30)),
                                                        new Order(AccountId=accountList[1].Id, ContractId=contractList[1].Id, Status='Draft', EffectiveDate=Date.today().addDays(30))};
                insert orderList;
            }
        }
    }

    @isTest static void testContractUpdate() {
        init('testContractUpdate');
        
        
        Test.startTest();
        List<Account> accountSome = [SELECT Id, PersonEmail, Master_Account__c FROM Account WHERE PersonEmail = 'some@some.com'];
        List<Contract> contractAny = [SELECT Id, AccountId, Status FROM Contract WHERE AccountId != :accountSome[0].Id];
        List<Order> orderAny = [SELECT Id, AccountId, ContractId, Status, Master_Account__c FROM Order WHERE AccountId != :accountSome[0].Id];
        List<Master_Account__c> masterAccount = [SELECT Id FROM Master_Account__c WHERE Email__c = 'some@some.com'];

        contractAny[0].AccountId = accountSome[0].Id;
        
        List<Database.SaveResult> result = Database.update(contractAny, false);
        Test.stopTest();

        List<Order> orderAnyNew = [SELECT Id, AccountId, ContractId, Status, Master_Account__c FROM Order WHERE Id = :orderAny[0].Id];

        System.assert(result[0].isSuccess(), 'Expected update to succeed.');
        System.assert(result[0].getErrors().size() == 0, 'Expected update to succeed.');
        System.assertEquals(masterAccount[0].Id, orderAnyNew[0].Master_Account__c, 'Expected master account field to be updated.');
    }

    @isTest static void testContractDelete() {
        init('testContractDelete');

        Test.startTest();
        List<Account> accountSome = [SELECT Id, PersonEmail, Master_Account__c FROM Account WHERE PersonEmail = 'some@some.com'];
        List<Contract> contractAny = [SELECT Id, AccountId, Status FROM Contract WHERE AccountId != :accountSome[0].Id];

        List<Database.DeleteResult> result = Database.delete(contractAny, false);
        undelete contractAny;
        Test.stopTest();

        System.assert(result[0].isSuccess(), 'Expected update to succeed.');
        System.assert(result[0].getErrors().size() == 0, 'Expected update to succeed.');
    }
}