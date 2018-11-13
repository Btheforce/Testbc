@isTest
private class TestOpportunityTrigger
{
    /**
     * Rewrote the test method to no longer use SeeAllData
     * @author Steve O'Neal
     * @date   2018-04-17
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-7040
     * @return [description]
     */
	static testMethod void testOppTeamRetention() 
    {
        List<Account> testAccounts = TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        List<Contact> testContacts = TestDataFactory.createTestContacts(1, testAccounts);
        List<Opportunity> testOpportunities = TestDataFactory.createTestOpportunities(3, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase'));

        List<Id> opportunityIds = new List<Id>();
        for (Opportunity testOpportunity : testOpportunities)
        {
            opportunityIds.add(testOpportunity.Id);
        }

    	List<OpportunityTeamMember> otms = [select Id from OpportunityTeamMember where OpportunityId in :opportunityIds];

		System.assertEquals(otms.size(), testOpportunities.size());
		
		User usr1 = [Select Id,Name, Department from User Where IsActive=true and Department =:Label.Inbound_Sales LIMIT 1];
		
        for (Opportunity testOpportunity : testOpportunities)
        {
            testOpportunity.OwnerId = usr1.Id;
        }
  		update testOpportunities;
  		   	
  		List<OpportunityTeamMember> otmsa = [select Id from OpportunityTeamMember where OpportunityId in :opportunityIds];
  		System.assertEquals(testOpportunities.size() * 2, otmsa.size());
  		
    }
    /**
     * Added test method to cover RVAccount-populating logic. BAP-6795
     * @author 		Ezra Kenigsberg
     * @date   		2018-06-05
     * @ticket link	https://jira.bigcommerce.com/browse/BAP-6795
     */
	static testMethod void testPopulateRVAccount() 
    {
		test.startTest();
        // create 2 RV Account recs and set their Ext Account IDs to existing MBAReferralId2ExtAccountId Custom Metadata recs
        List<rvpe__RVAccount__c> lstRVAccts = TestDataFactory.createTestRVAccounts(2);
		MBAReferralId2ExtAccountId__mdt m2e0 = [SELECT Referral_ID__c, ExtAccountId__c FROM MBAReferralId2ExtAccountId__mdt LIMIT 1];
		MBAReferralId2ExtAccountId__mdt m2e1 = [SELECT Referral_ID__c, ExtAccountId__c FROM MBAReferralId2ExtAccountId__mdt 
                                                WHERE ExtAccountId__c != :m2e0.ExtAccountId__c LIMIT 1];
        lstRVAccts[0].rvpe__ExtAccountId__c = m2e0.ExtAccountId__c;
        lstRVAccts[1].rvpe__ExtAccountId__c = m2e1.ExtAccountId__c;
        update lstRVAccts;
        // insert 1 Account and 3 Opty recs
        List<Account> lstAccts = TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        List<Opportunity> lstOptys = TestDataFactory.createTestOpportunities(3, lstAccts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase'));
        // test #0: RVAccount should get written
        lstOptys[0].Referral_ID__c = m2e0.Referral_ID__c;
        update lstOptys[0];
        Opportunity optyTest0 = [SELECT Referral_ID__c, rvpe__RVAccount__c, rvpe__IsDealRegistration__c FROM Opportunity WHERE Id = :lstOptys[0].Id];
        // test #1: RVAccount should not get written (there'll already be a value in RVAccount)
        lstOptys[1].Referral_ID__c = m2e0.Referral_ID__c;
        lstOptys[1].rvpe__RVAccount__c = lstRVAccts[1].Id;
        update lstOptys[1];
        Opportunity optyTest1 = [SELECT Referral_ID__c, rvpe__RVAccount__c, rvpe__IsDealRegistration__c FROM Opportunity WHERE Id = :lstOptys[1].Id];
        // test #2: RVAccount should not get written (no match)
        lstOptys[2].Referral_ID__c = 'totally bogus text';
        update lstOptys[2];
        Opportunity optyTest2 = [SELECT Referral_ID__c, rvpe__RVAccount__c, rvpe__IsDealRegistration__c FROM Opportunity WHERE Id = :lstOptys[2].Id];
		// do all the asserting
        test.stopTest();
        System.assertEquals(optyTest0.rvpe__RVAccount__c, lstRVAccts[0].Id);
        System.assertEquals(optyTest0.rvpe__IsDealRegistration__c, True);
        System.assertEquals(optyTest1.Referral_ID__c, m2e0.Referral_ID__c);  
        System.assertEquals(optyTest1.rvpe__RVAccount__c, lstRVAccts[1].Id);
        System.assertEquals(optyTest1.rvpe__IsDealRegistration__c, False);
        System.assertEquals(optyTest2.rvpe__RVAccount__c, null);
        System.assertEquals(optyTest2.rvpe__IsDealRegistration__c, False);
    }
}