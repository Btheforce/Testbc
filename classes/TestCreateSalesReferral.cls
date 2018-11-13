@isTest //Depricated
private class TestCreateSalesReferral
{
    /*
	private static List<Account> testAccounts;
	private static List<Contact> testContacts;
	private static List<Opportunity> testOpportunities;
	private static List<Case> testCases;
	private static List<Store__c> testStores;

	/**
	 * Tests creating a referral from a case
	 * @author Steve O'Neal
	 * @date   2018-02-16
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6840
	 * @return [description]
	 
	@isTest static void testFromCase() 
	{
		createTestObjects();

		setPageReferenceCreateSalesReferral(testCases[0].Id);
		CreateSalesReferralController controller = new CreateSalesReferralController(createStandardController());

		System.assert(controller.SalesReferral.Contact__c == testContacts[0].Id);
		System.assert(controller.SalesReferral.Account__c == testAccounts[0].Id);
		System.assert(controller.SalesReferral.Store__c == testStores[0].Id);

		controller.Save();
	}
	

	/**
	 * Tests creating a referral from an account
	 * @author Steve O'Neal
	 * @date   2018-02-16
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6840
	 * @return [description]
	 
	@isTest static void testFromAccount() 
	{
		createTestObjects();

		setPageReferenceCreateSalesReferral(testAccounts[0].Id);
		CreateSalesReferralController controller = new CreateSalesReferralController(createStandardController());

		System.assert(controller.SalesReferral.Contact__c == testContacts[0].Id);
		System.assert(controller.SalesReferral.Account__c == testAccounts[0].Id);
		System.assert(controller.SalesReferral.Store__c == testStores[0].Id);

		controller.Save();
	}


	/**
	 * Tests creating a referral from a Contact
	 * @author Steve O'Neal
	 * @date   2018-02-16
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6840
	 * @return [description]
	 
	@isTest static void testFromContact() 
	{
		createTestObjects();

		setPageReferenceCreateSalesReferral(testContacts[0].Id);
		CreateSalesReferralController controller = new CreateSalesReferralController(createStandardController());

		System.assert(controller.SalesReferral.Contact__c == testContacts[0].Id);
		System.assert(controller.SalesReferral.Account__c == testAccounts[0].Id);
		System.assert(controller.SalesReferral.Store__c == testStores[0].Id);

		controller.Save();
	}


	/**
	 * Tests creating a referral from a Contact
	 * @author Steve O'Neal
	 * @date   2018-02-16
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6840
	 * @return [description]
	 
	@isTest static void testFromStore() 
	{
		createTestObjects();

		setPageReferenceCreateSalesReferral(testStores[0].Id);
		CreateSalesReferralController controller = new CreateSalesReferralController(createStandardController());

		System.assert(controller.SalesReferral.Contact__c == testContacts[0].Id);
		System.assert(controller.SalesReferral.Account__c == testAccounts[0].Id);
		System.assert(controller.SalesReferral.Store__c == testStores[0].Id);

		controller.Save();
	}


	/**
	 * Tests creating a referral from an Opportunity
	 * @author Steve O'Neal
	 * @date   2018-02-16
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6840
	 * @return [description]
	 
	@isTest static void testFromOpportunity() 
	{
		createTestObjects();

		setPageReferenceCreateSalesReferral(testOpportunities[0].Id);
		CreateSalesReferralController controller = new CreateSalesReferralController(createStandardController());

		System.assert(controller.SalesReferral.Contact__c == testContacts[0].Id);
		System.assert(controller.SalesReferral.Account__c == testAccounts[0].Id);
		System.assert(controller.SalesReferral.Store__c == testStores[0].Id);

		controller.Save();
	}


    @isTest static void doActionFunctionTest(){
        
    }
    
	/**
	 * Sets the page referral for all tests
	 * @author Steve O'Neal
	 * @date   2018-02-16
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-6840
	 * @param  recordId   Record to set as the retUrl
	 
	private static void setPageReferenceCreateSalesReferral(ID recordId)
	{
		PageReference pageRef = Page.CreateSalesReferral;
		Test.setCurrentPage(new PageReference(pageRef.getUrl() + '?retUrl=' + recordId));


	}


	/**
	 * Generically builds the objects needed for each test
	 * @author Steve O'Neal
	 * @date   2018-02-16
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-6840
	 
	private static void createTestObjects()
	{
		integer numberOfRecords = 1;
		testAccounts = TestDataFactory.CreateTestAccounts(numberOfRecords, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
		testContacts = TestDataFactory.CreateTestContacts(numberOfRecords, testAccounts);
		testOpportunities = TestDataFactory.CreateTestOpportunities(numberOfRecords, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Trial'));
		testStores = TestDataFactory.CreateTestStores(numberOfRecords, testAccounts);
		testCases = TestDataFactory.CreateTestCases(numberOfRecords, testContacts);

		OpportunityContactRole oppContactRole = new OpportunityContactRole();
		oppContactRole.OpportunityId = testOpportunities[0].Id;
		oppContactRole.ContactId = testContacts[0].Id;
		oppContactRole.Role = 'Primary Contact';
		oppContactRole.IsPrimary = true;
		insert oppContactRole;

		Store_Contact_Roles__c storeContactRole = new Store_Contact_Roles__c();
		storeContactRole.Contact__c = testContacts[0].Id;
		storeContactRole.Store__c = testStores[0].Id;
		storeContactRole.Contact_Role__c = 'Primary Contacty';
		insert storeContactRole;

		testOpportunities[0].MBASubscriptionId__c = testStores[0].Hosting_Id__c;
		update testOpportunities;

		testCases[0].Opportunity__c = testOpportunities[0].Id;
		update testCases;
        
	}

	/**
	 * Creates a standard controller for a Sales Referral
	 * @author Steve O'Neal
	 * @date   2018-02-16
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6840
	 * @return Standard Controller
	 
	private static ApexPages.StandardController createStandardController()
	{
		Sales_Referral__c salesReferral = new Sales_Referral__c();
		salesReferral.Notes__c = 'test';
		salesReferral.Products__c = PickListUtils.getRandomPickListValue(Sales_Referral__c.SObjectType, 'Products__c');
        salesReferral.Validation_Products__c = PickListUtils.getRandomPickListValue(Sales_Referral__c.SObjectType, 'Validation_Products__c');
        if(salesReferral.Products__c == 'Other' || salesReferral.Validation_Products__c == 'Other'){
            salesReferral.Other_Product_Description__c = 'Test';
        }

		return new ApexPages.StandardController(salesReferral);
	}


	/**
	 * Tests BatchCreateOppsFromSalesReferral
	 * @author Steve O'Neal
	 * @date   2018-02-26
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6903
	 
	@isTest static void BatchCreateOppsFromSalesReferralTest()
	{
        /*
		createTestObjects();

		Sales_Referral__c salesReferral = new Sales_Referral__c();
		salesReferral.Notes__c = 'test';
		salesReferral.Products__c = 'PS-SLP; Other';
        salesReferral.Validation_Products__c = 'Cross Sell: Domains; Cross Sell: SSL';
		salesReferral.Other_Product_Description__c = 'Test';
		salesReferral.Account__c = testContacts[0].AccountId;
		salesReferral.Contact__c = testContacts[0].Id;
		salesReferral.Store_Opportunity__c = testOpportunities[0].Id;
		salesReferral.Store__c = testStores[0].Id;
		insert salesReferral;
        
        System.debug('>>>>>SalesRef ' + salesReferral);

		Test.startTest();
		BatchCreateOppsFromSalesReferral bcofsr = new BatchCreateOppsFromSalesReferral();
		Database.executeBatch(bcofsr);
		Test.stopTest();

		List<Opportunity> opportunities = [select Id, RecordTypeId, Sales_Referral__c from Opportunity where Sales_Referral__c = :salesReferral.Id];
	
        List<String> lstProducts = salesReferral.Products__c.Split(';');
        	lstProducts.addAll(salesReferral.Validation_Products__c.Split(';'));
        
		System.assertEquals(lstProducts.size(), opportunities.size());
		System.assertNotEquals(opportunities[0].RecordTypeId, opportunities[1].RecordTypeId); 
	}
    
	*/	
}