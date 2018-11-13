@isTest
private class TestTerritoryUtil 
{
	
	/**
	 * Tests accounts for territory mapping
	 * @author Steve O'Neal
	 * @date   2017-12-19
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-6573
	 */
	@isTest 
	static void testAccounts() 
	{
		List<Account> accounts = TestDataFactory.createTestAccounts(3, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
		List<Lead> leads = TestDataFactory.createTestLeads(3, false, RecordTypeTools.GetRecordTypeByDeveloperName(Lead.GetSObjectType(), 'Client_Prospect'));
		Set<Id> testAccountIDs = new Set<Id>();
		Set<Id> testLeadIDs = new Set<Id>();

		for (Account testAccount : accounts)
		{
			testAccountIDs.add(testAccount.Id);
		}
		for (Lead testLead : leads)
		{
			testLeadIDs.add(testLead.Id);
		}

		List<Account> accountsForUpdate = [Select Id, BillingState, BillingCountry, Territory__c from Account where Id = :testAccountIDs];
		List<Lead> leadsForUpdate = [Select Id, State, Country, Territory__c from Lead where Id = :testLeadIDs];

		for (Account testAccount : accountsForUpdate)
		{
			testAccount.BillingPostalCode = '90210';
			testAccount.BillingState = 'CA';
			testAccount.BillingCountry = 'US';
		}
		for (Lead testLead : leadsForUpdate)
		{
			testLead.PostalCode = '9999';
			testLead.State = 'NSW';
			testLead.Country = 'AU';
		}

		// explicitly test the code
		TerritoryUtil tUtil = new TerritoryUtil();
        TerritoryUtil territoryUtility = new TerritoryUtil();
        territoryUtility.SetTerritory(accountsForUpdate);
        territoryUtility.SetTerritory(leadsForUpdate);

        for (Account accountVerify : accountsForUpdate)
        {
        	System.assertEquals(accountVerify.Territory__c, 'Southern California');
        }
        for (Lead leadVerify : leadsForUpdate)
        {
        	System.assertEquals(leadVerify.Territory__c, 'Australia');
        }

		// test the trigger
		update accountsForUpdate;
		update leadsForUpdate;
	}
}