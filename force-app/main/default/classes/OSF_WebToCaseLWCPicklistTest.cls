@isTest
private class OSF_WebToCaseLWCPicklistTest {
    @isTest static void testGetValues() {
        OSF_WebToCaseLWCPicklist picklist = new OSF_WebToCaseLWCPicklist();
        VisualEditor.DynamicPickListRows rows = picklist.getValues();
        System.assertEquals(2, rows.size(), 'Expected two options.');
    }
}