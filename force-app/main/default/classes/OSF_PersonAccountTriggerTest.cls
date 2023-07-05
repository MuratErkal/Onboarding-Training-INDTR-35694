@isTest
private class OSF_PersonAccountTriggerTest {

    private static void init(String actionToInit) {
        switch on actionToInit {
            when 'testUpdatePersonAccountBrandSuccess', 'testUpdatePersonAccountBrandError', 'testUpdatePersonAccountEmailSuccess', 
                'testUpdatePersonAccountEmailError', 'testDeletePersonAccounts', 'testEmptyFields' {
                List<Account> accountList = new List<Account>{new Account(LastName='Smith', PersonEmail='some@some.com', Brand__c='Force'),
                                                             new Account(LastName='Smith', PersonEmail='some@some.com', Brand__c='Sales'),
                                                             new Account(LastName='Wall', PersonEmail='any@any.com', Brand__c='Force')};
                insert accountList;
            }
        }
    }

    @isTest static void testUpdatePersonAccountBrandSuccess() {
        init('testUpdatePersonAccountBrandSuccess');

        Test.startTest();
        List<Account> wallAnyForce = [SELECT Id, Brand__c, PersonEmail FROM Account WHERE PersonEmail = 'any@any.com' AND Brand__c = 'Force'];
        wallAnyForce[0].Brand__c = 'Sales';
        List<Database.SaveResult> result = Database.update(wallAnyForce, false);
        Test.stopTest();

        System.assert(result[0].isSuccess(), 'Expected update to succeed.');
        System.assert(result[0].getErrors().size() == 0, 'Expected update to succeed.');
    }

    @isTest static void testUpdatePersonAccountBrandError() {
        init('testUpdatePersonAccountBrandError');

        Test.startTest();
        List<Account> smithSomeSales = [SELECT Id, Brand__c, PersonEmail FROM Account WHERE PersonEmail = 'some@some.com' AND Brand__c = 'Sales'];
        smithSomeSales[0].Brand__c = 'Force';
        List<Database.SaveResult> result = Database.update(smithSomeSales, false);
        Test.stopTest();

        System.assert(!result[0].isSuccess(), 'Expected update to fail.');
        System.assert(result[0].getErrors().size() > 0, 'Expected update to have errors.');
        System.assertEquals('Email is in use with the same brand, please use another email or brand.',
                             result[0].getErrors()[0].getMessage(), 'Expected the error message to be: \'Email is in use with the same brand, please use another email or brand.\'');
    }

    @isTest static void testUpdatePersonAccountEmailSuccess() {
        init('testUpdatePersonAccountEmailSuccess');

        Test.startTest();
        List<Account> smithSomeSales = [SELECT Id, Brand__c, PersonEmail FROM Account WHERE PersonEmail = 'some@some.com' AND Brand__c = 'Sales'];
        smithSomeSales[0].PersonEmail = 'any@any.com';
        List<Database.SaveResult> result = Database.update(smithSomeSales, false);
        Test.stopTest();
        
        Master_Account__c masterAccountSome = [SELECT Id, (SELECT Id FROM PersonAccounts__r) FROM Master_Account__c WHERE Email__c = 'some@some.com'];
        Master_Account__c masterAccountAny = [SELECT Id, (SELECT Id FROM PersonAccounts__r) FROM Master_Account__c WHERE Email__c = 'any@any.com'];
        Account updatedAcc = [SELECT Id, Master_Account__c FROM Account WHERE Id = :smithSomeSales[0].Id];

        System.assert(result[0].isSuccess(), 'Update wasn\'t successful.');
        System.assert(result[0].getErrors().size() == 0, 'There were errors in update.');
        System.assertNotEquals(masterAccountSome.Id, updatedAcc.Master_Account__c, 'Person account\'s master account field didn\'t get updated.');
        System.assertEquals(masterAccountAny.Id, updatedAcc.Master_Account__c, 'Person account\'s master account field didn\'t get updated.');
        System.assertEquals(2, masterAccountAny.PersonAccounts__r.size(), 'Person account\'s master account field didn\'t get updated.');
    }

    @isTest static void testUpdatePersonAccountEmailError() {
        init('testUpdatePersonAccountEmailError');

        Test.startTest();
        List<Account> wallAnyForce = [SELECT Id, Brand__c, PersonEmail FROM Account WHERE PersonEmail = 'any@any.com' AND Brand__c = 'Force'];
        wallAnyForce[0].PersonEmail = 'some@some.com';
        List<Database.SaveResult> result = Database.update(wallAnyForce, false);
        Test.stopTest();

        Master_Account__c masterAccountSome = [SELECT Id FROM Master_Account__c WHERE Email__c = 'some@some.com'];
        Account updatedAcc = [SELECT Id, Master_Account__c FROM Account WHERE IsPersonAccount = True AND Id = :wallAnyForce[0].Id];

        System.assert(!result[0].isSuccess(), 'Expected update to fail.');
        System.assert(result[0].getErrors().size() > 0, 'Expected update to have errors.');
        System.assertNotEquals(masterAccountSome.Id, updatedAcc.Master_Account__c, 'Person account\'s master account field got updated.');
        System.assertEquals('Email is in use with the same brand, please use another email or brand.',
                             result[0].getErrors()[0].getMessage(), 'Expected the error message to be: \'Email is in use with the same brand, please use another email or brand.\'');
    }

    @isTest static void testDeletePersonAccounts() {
        init('testDeletePersonAccounts');

        Test.startTest();
        List<Account> wallAnyList = [SELECT Id, Brand__c, PersonEmail FROM Account WHERE PersonEmail = 'any@any.com'];
        List<Database.DeleteResult> result = Database.delete(wallAnyList, false);
        Test.stopTest();

        List<Master_Account__c> masterAccountAny = [SELECT Id FROM Master_Account__c WHERE Email__c = 'any@any.com'];

        System.assert(result[0].isSuccess(), 'Expected delete to succeed.');
        System.assert(result[0].getErrors().size() == 0, 'Expected delete to succeed.');
        System.assertEquals(0, masterAccountAny.size(), 'Expected master account to be deleted.');
    }

    @isTest static void testEmptyFields() {
        init('testEmptyFields');

        Test.startTest();
        List<Account> accountList = new List<Account>{new Account(LastName='Smith', PersonEmail=null, Brand__c='Force'),
                                                     new Account(LastName='Smith', PersonEmail='some@some.com', Brand__c=null)};
        List<Database.SaveResult> result = Database.insert(accountList, false);
        Test.stopTest();

        System.assert(!result[0].isSuccess(), 'Expected insert to fail.');
        System.assert(!result[1].isSuccess(), 'Expected insert to fail.');
    }
}