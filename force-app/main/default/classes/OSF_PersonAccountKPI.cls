public with sharing class OSF_PersonAccountKPI {

    @AuraEnabled(cacheable=true)
    public static String getData(String pAccId) {
        List<Account> pAcc = new List<Account>();
        List<AggregateResult> ytd = new List<AggregateResult>();
        List<AggregateResult> ytd5 = new List<AggregateResult>();
        try {
            pAcc = [SELECT Id, CreatedDate, PersonBirthdate, 
                                        (SELECT Id, Subject, Status FROM Cases),
                                        (SELECT Id, TotalAmount FROM Orders) 
                                    FROM Account WHERE Id = :pAccId];
            ytd = [SELECT SUM(TotalAmount) FROM Order WHERE AccountId = :pAccId AND EffectiveDate = THIS_YEAR];
            ytd5 = [SELECT SUM(TotalAmount) FROM Order WHERE AccountId = :pAccId AND EffectiveDate > N_YEARS_AGO:5];
            return JSON.serialize(new OSF_PersonAccountKPIModel(pAcc, ytd, ytd5));
        } catch (Exception e) {
            return JSON.serialize(e);
        }
    }

    public class OSF_PersonAccountKPIModel {
        public Account personAccount;
        public AggregateResult ytd;
        public AggregateResult ytd5;

        public OSF_PersonAccountKPIModel(List<Account> pAcc, List<AggregateResult> ytd, List<AggregateResult> ytd5) {
            this.personAccount = pAcc[0];
            this.ytd = ytd[0];
            this.ytd5 = ytd5[0];
        }
    }
}