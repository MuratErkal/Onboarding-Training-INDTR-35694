@isTest
private class OSF_PersonAccountKPITest {
    private static void init(String actionToInit) {
        switch on actionToInit {
            when 'testGetData' {
                List<Account> accountList = new List<Account>{new Account(LastName='Smith', PersonEmail='some@some.com', Brand__c='Force')};
                insert accountList;
        
                List<Contract> contractList = new List<Contract>{new Contract(AccountId=accountList[0].Id, Status='Draft', StartDate=Date.today(), ContractTerm=3)};
                insert contractList;
        
                Product2 p = new Product2(Name='Test Product', Description='Test Product Desc', productCode='ABC', isActive=true);
                insert p;

                Id pricebookId = Test.getStandardPricebookId();

                PricebookEntry standardPrice = new PricebookEntry();
                standardPrice.Pricebook2Id = pricebookId;
                standardPrice.Product2Id = p.Id;
                standardPrice.UnitPrice = 1;
                standardPrice.IsActive = true;
                standardPrice.UseStandardPrice = false;
                insert standardPrice ;

                List<Order> orderList = new List<Order>{new Order(AccountId=accountList[0].Id, Pricebook2Id=pricebookId, ContractId=contractList[0].Id, Status='Draft', billingCity='Phone', EffectiveDate=Date.today().addDays(30))};
                insert orderList;

                OrderItem i = new OrderItem();
                i.OrderId = orderList[0].id;
                i.Quantity = 1;
                i.UnitPrice = 1;
                i.Product2id = p.id;
                i.PricebookEntryId=standardPrice.id;
                insert i;
        
                List<Order> orderListAfter = [SELECT Id, OrderNumber FROM Order];
        
                List<Case> caseList = new List<Case>{new Case(AccountId=accountList[0].Id, Status='New', Origin='ForceWeb')};
        
                insert caseList;
        
                caseList[0].Order_Number__c = orderListAfter[0].OrderNumber;
                update caseList;
            }
        }
    }


    @isTest static void testGetData() {
        init('testGetData');
        List<Account> pAccList = [SELECT Id FROM Account WHERE PersonEmail = 'some@some.com'];
        Test.startTest();
        String res = OSF_PersonAccountKPI.getData(pAccList[0].Id);
        OSF_PersonAccountKPI.OSF_PersonAccountKPIModel kpi = (OSF_PersonAccountKPI.OSF_PersonAccountKPIModel)JSON.deserialize(res, OSF_PersonAccountKPI.OSF_PersonAccountKPIModel.class);
        Test.stopTest();

        System.assertEquals(1, kpi.personAccount.Cases.size(), 'Expected 1 case');
        System.assertEquals(1, kpi.personAccount.Orders.size(), 'Expected 1 order');
    }
}