@isTest(SeeAllData=true)
private class TestRVlogic {
    
    private static testMethod void partnerLeadTest(){
        TestDataGenerator td = new TestDataGenerator();  
        List<string> profiles = new List<String>();
        
        Profiles.add('Sales Rep');
        List<User> salesusers = td.getUsers(Profiles);
        integer counter = 1;
        for (user u:salesusers){
            u.firstName = u.firstName + counter;
            u.lastName = u.lastName + counter;
            system.debug('user '+u.lastName);
            counter = counter + 1;
        }
        update salesusers;
        
        list <User> newUsers = [SELECT Id, full_name__c FROM User WHERE Id IN :salesusers];
        system.debug(' user name '+newusers[0].Full_Name__c);
        /**
         * Moved the creation of RV Account and RV Member to the TestDataFactory
         * @author Steve O'Neal
         * @date   2018-04-30
         * @ticket link          https://jira.bigcommerce.com/browse/BAP-7204
         */
        List<rvpe__RVAccount__c> rvas = TestDataFactory.createTestRVAccounts(1);
        List<rvpe__RVMember__c> rvms = TestDataFactory.createTestRVMembers(1, rvas);

        system.debug('*** RVAccount Id: ' + rvas[0].Id);
        system.debug('*** RVMember Id: ' + rvms[0].Id);
        Id sfacctid = [SELECT rvpe__SFAccount__c FROM rvpe__RVAccount__c WHERE Id = :rvas[0].Id LIMIT 1].rvpe__SFAccount__c;
        Account acct = [SELECT Id, Name FROM Account 
                        WHERE Id = :sfacctid
                        LIMIT 1];
        System.assertEquals(rvas[0].Name, acct.Name);
        
        rvpe__RVAccount__c rva1 = [SELECT Id, OwnerId, Owner.Name FROM rvpe__RVAccount__c  rvaOne 
                                   WHERE ID = :rvas[0].Id];
        system.debug(' rv owner '+rva1.Owner.Name);
        
        List<Lead> lstLeads = td.getLeads(false); 
        
        for (Lead l:lstLeads){
            l.rvpe__RVAccount__c = rva1.Id;
        }
        insert lstLeads;
        
        List<Opportunity> opps =  td.getOpportunities(false);
        for (Opportunity o:opps){
            o.rvpe__RVAccount__c = rva1.Id;
            o.OwnerId = salesusers[0].Id;
        }
        insert opps;
    }
}