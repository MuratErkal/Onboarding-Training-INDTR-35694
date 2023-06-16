public class OSF_WebToCaseLWC {
    private static final String FORCE_STRING = 'Force';
    private static final String SALES_STRING = 'Sales';
    
    @AuraEnabled
    public static OSF_WtC_Form__mdt getMetadata(String brand) {
        List<OSF_WtC_Form__mdt> metadataList = new List<OSF_WtC_Form__mdt>();

        try {
            if (brand == FORCE_STRING) {
                metadataList = [SELECT (SELECT Name__c, Developer_Name__c, Label__c, Placeholder__c, Type__c, Max_Length__c, Min_Length__c, Default_Value__c, isVisible__c, Index__c FROM OSF_WtC_Form_Fields__r) FROM OSF_WtC_Form__mdt WHERE MasterLabel = 'Force WtC Form'];
            } else if (brand == SALES_STRING) {
                metadataList = [SELECT (SELECT Name__c, Developer_Name__c, Label__c, Placeholder__c, Type__c, Max_Length__c, Min_Length__c, Default_Value__c, isVisible__c, Index__c FROM OSF_WtC_Form_Fields__r) FROM OSF_WtC_Form__mdt WHERE MasterLabel = 'Sales WtC Form'];
            }
        } catch(Exception e) {
            System.debug('error: ' + e.getMessage());
        }

        return metadataList[0];
    }

    @AuraEnabled
    public static List<Case> getCases(String caseEmail, String brand){
        try {
            List<Case> caseList = [SELECT Id, Subject, Description, Status FROM Case WHERE SuppliedEmail = :caseEmail AND Brand__c = :brand];
            return caseList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}