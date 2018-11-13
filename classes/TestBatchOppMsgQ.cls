/**
 * Test class for BatchOppMsgQ suite of classes
 * @author Steve O'Neal
 * @date   2017-04-13
 * @ticket link       https://jira.bigcommerce.com/browse/BAP-4327
 */
@isTest
private class TestBatchOppMsgQ 
{
	/**
	 * Test method for BatchOppMsgQ_GarbageCollection class
	 * @author Steve O'Neal
	 * @date   2017-04-13
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-4327
	 */
	@isTest 
	static void testBatchOppMsgQ_GarbageCollection() 
	{
		integer numberOfRecords = 1;
		integer numberOfResaves = 4;
		// create test data
        List<Account> testAccounts = TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
		List<Opportunity> testOpportunities = TestDataFactory.createTestOpportunities(1, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase'));
		List<Zuora__Subscription__c> testSubscriptions = TestDataFactory.createFullSuiteOfTestZuoraSubscriptionData(numberOfRecords, testOpportunities);
		System.debug(testSubscriptions);

		// save the subscriptions a few times to create additional records
		for (integer i = 0; i < numberOfResaves; i++)
		{
			update testSubscriptions;
		}

		// fetch the records from the message queue
		List<Opportunity_Message_Queue__c> OMQs = [Select Id, Status__c from Opportunity_Message_Queue__c where Status__c = 'New' and Task__c = :MessageQueueUtilities.taskStringUpdateOpportunity order by ID desc];

		System.assertEquals(numberOfRecords * (1 + numberOfResaves), OMQs.size());

		// mark one of the records as ready for garbage collection
		OMQs[0].Status__c = 'Garbage Collect';
		update OMQs[0];

		// run the batch job
		Test.startTest();
		BatchOppMsgQ_GarbageCollection bomq_gc = new BatchOppMsgQ_GarbageCollection();
		Database.executeBatch(bomq_gc);
		Test.stopTest();

		// fetch the records again and make sure the dupes are removed
		List<Opportunity_Message_Queue__c> OMQsAfterBatch = [Select Id from Opportunity_Message_Queue__c where Status__c = 'New' and Task__c = :MessageQueueUtilities.taskStringUpdateOpportunity];
		System.assertEquals(numberOfRecords, OMQsAfterBatch.size());
	}


	/**
	 * Test method for BatchOppMsgQ_OppLineItems class
	 * @author Steve O'Neal
	 * @date   2017-04-13
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-4327
	 */
	@isTest
	static void testBatchOppMsgQ_OppLineItems()
	{
		integer numberOfRecords = 1;
        List<Account> testAccounts = TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
		List<Opportunity> testOpportunities = TestDataFactory.createTestOpportunities(1, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase'));
		List<Zuora__Subscription__c> testSubscriptions = TestDataFactory.createFullSuiteOfTestZuoraSubscriptionData(numberOfRecords, testOpportunities);

		// make sure the message made it into the queue
		List<Opportunity_Message_Queue__c> OMQs = [Select Id from Opportunity_Message_Queue__c where Status__c = 'New' and Task__c = :MessageQueueUtilities.taskStringCreateOpportunityLineItems];
		System.assertEquals(numberOfRecords, OMQs.size());

		List<Id> zSubIds = new List<Id>();
		for (Zuora__Subscription__c zSub : testSubscriptions)
		{
			zSubIds.add(zSub.Id);
		}

		// find out how many products were added to the subscription
		List<Zuora__SubscriptionProductCharge__c> zSubCharges = [Select Id from Zuora__SubscriptionProductCharge__c where Zuora__Subscription__c = :zSubIds];

		// run the batch job
		Test.startTest();
		BatchOppMsgQ_OppLineItems bomsq_oli = new BatchOppMsgQ_OppLineItems();
		Database.executeBatch(bomsq_oli);
		Test.stopTest();

		List<Id> opportunityIds = new List<Id>();
		for (Opportunity testOpportunity : testOpportunities)
		{
			opportunityIds.add(testOpportunity.Id);
		}

		// check the results
		List<OpportunityLineItem> oppProducts = [Select Id from OpportunityLineItem where OpportunityId = :opportunityIds];
		System.assertEquals(zSubCharges.size(), oppProducts.size());


		// save the records again and run the job again to cover deletion code
		update testSubscriptions;
		Database.executeBatch(bomsq_oli);
	}


	/**
	 * Test method for BatchOppMsgQ_OppProductHistory class
	 * @author Steve O'Neal
	 * @date   2017-04-13
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-4327
	 */
	@isTest
	static void testBatchOppMsgQ_OppProductHistory()
	{
		integer numberOfRecords = 2;
        List<Account> testAccounts = TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
		List<Opportunity> testOpportunities = TestDataFactory.createTestOpportunities(1, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase'));
		List<Zuora__Subscription__c> testSubscriptions = TestDataFactory.createFullSuiteOfTestZuoraSubscriptionData(numberOfRecords, testOpportunities);

		// make sure the message made it into the queue
		List<Opportunity_Message_Queue__c> OMQs = [Select Id from Opportunity_Message_Queue__c where Status__c = 'New' and Task__c = :MessageQueueUtilities.taskStringCreateOpportunityProductHistory];
		System.assertEquals(numberOfRecords, OMQs.size());

		List<Id> zSubIds = new List<Id>();
		for (Zuora__Subscription__c zSub : testSubscriptions)
		{
			zSubIds.add(zSub.Id);
		}

		testOpportunities[0].PurchaseDate__c = Date.today().addDays(-100);
		update testOpportunities[0];

		// find out how many products were added to the subscription
		List<Zuora__SubscriptionProductCharge__c> zSubCharges = [Select Id from Zuora__SubscriptionProductCharge__c where Zuora__Subscription__c = :zSubIds];

		// run the batch job
		Test.startTest();
		BatchOppMsgQ_OppProductHistory bomsq_oph = new BatchOppMsgQ_OppProductHistory();
		Database.executeBatch(bomsq_oph);
		Test.stopTest();

		List<Id> opportunityIds = new List<Id>();
		for (Opportunity testOpportunity : testOpportunities)
		{
			opportunityIds.add(testOpportunity.Id);
		}

		// check the results
		List<Opportunity_Product__c> OPHRecords = [Select Id from Opportunity_Product__c where OpportunityID__c = :opportunityIds];
		System.assertEquals(zSubCharges.size(), OPHRecords.size());

		// try saving the zSub again and running the batch again to get code coverage on overwriting the existing values.  Make some slight changes
		update testSubscriptions;

		// create an upgrade opportunity
		List<Opportunity> testUpgradeOpportunities = TestDataFactory.createTestOpportunities(1, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Upgrade_Store'));
		for (Opportunity upgradeOpp : testUpgradeOpportunities)
		{
			// associate the opp with one we created above
			upgradeOpp.ParentOpportunity__c = testOpportunities[0].Id;
		}
		update testUpgradeOpportunities;


		// create a sub without any charges to force a failure
        List<Zuora__CustomerAccount__c> testBillingAccounts = TestDataFactory.createTestZuoraBillingAccounts(1, testAccounts);
        List<Zuora__Subscription__c> testSubscriptionsNoCharges = TestDataFactory.createTestZuoraSubscriptions(2, testBillingAccounts, testOpportunities);
        // set one of the charge records to a high attempt number to mimic Zuora failing to send us charges
        List<Opportunity_Message_Queue__c> oppMsgQNoChargeList = [Select Id, Attempt_Number__c from Opportunity_Message_Queue__c where Status__c = 'New' and Task__c = :MessageQueueUtilities.taskStringCreateOpportunityProductHistory and Zuora_Subscription_Id__c = :testSubscriptionsNoCharges[0].Id];
        for (Opportunity_Message_Queue__c oppMsqQNoCharge : oppMsgQNoChargeList)
        {
        	oppMsqQNoCharge.Attempt_Number__c = 100;
        }
        update oppMsgQNoChargeList;

		Database.executeBatch(bomsq_oph);
	}


	/**
	 * Test method for BatchOppMsgQ_UpdateOpportunity class
	 * @author Steve O'Neal
	 * @date   2017-04-13
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-4327
	 */
	@isTest
	static void testBatchOppMsgQ_UpdateOpportunity()
	{
		integer numberOfRecords = 1;
        List<Account> testAccounts = TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
		List<Opportunity> testOpportunities = TestDataFactory.createTestOpportunities(1, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase'));
		List<Zuora__Subscription__c> testSubscriptions = TestDataFactory.createFullSuiteOfTestZuoraSubscriptionData(numberOfRecords, testOpportunities);

		// make sure the message made it into the queue
		List<Opportunity_Message_Queue__c> OMQs = [Select Id from Opportunity_Message_Queue__c where Status__c = 'New' and Task__c = :MessageQueueUtilities.taskStringUpdateOpportunity];
		System.assertEquals(numberOfRecords, OMQs.size());

		List<Id> zSubIds = new List<Id>();
		for (Zuora__Subscription__c zSub : testSubscriptions)
		{
			zSubIds.add(zSub.Id);
		}

		// find out how many products were added to the subscription
		List<Zuora__SubscriptionProductCharge__c> zSubCharges = [Select Id from Zuora__SubscriptionProductCharge__c where Zuora__Subscription__c = :zSubIds];

		// run the batch job
		Test.startTest();
		BatchOppMsgQ_UpdateOpportunity bomsq_uo = new BatchOppMsgQ_UpdateOpportunity();
		Database.executeBatch(bomsq_uo);
		Test.stopTest();
	}


	/**
	 * Test method for BatchOppMsgQ_OppContactRoles class
	 * @author Steve O'Neal
	 * @date   2017-04-13
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-4327
	 */
	@isTest
	static void testBatchOppMsgQ_OppContactRoles()
	{
		integer numberOfRecords = 1;
        List<Account> testAccounts = TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        List<Contact> testContacts = TestDataFactory.createTestContacts(1, testAccounts);
		List<Opportunity> testOpportunities = TestDataFactory.createTestOpportunities(numberOfRecords, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase'));

		// make sure the message made it into the queue
		List<Opportunity_Message_Queue__c> OMQs = [Select Id from Opportunity_Message_Queue__c where Status__c = 'New' and Task__c = :MessageQueueUtilities.taskStringCreateOpportunityContactRoles];
		System.assert(OMQs.size() >= 1);

		// run the batch job
		Test.startTest();
		BatchOppMsgQ_OppContactRoles bomsq_ocr = new BatchOppMsgQ_OppContactRoles();
		Database.executeBatch(bomsq_ocr);
		Test.stopTest();

		// see how many contact roles were created
		List<Id> opportunityIds = new List<Id>();
		for (Opportunity testOpportunity : testOpportunities)
		{
			opportunityIds.add(testOpportunity.Id);
		}

		// check the results
		List<OpportunityContactRole> OCRRecords = [Select Id from OpportunityContactRole where OpportunityId = :opportunityIds];
		System.assertEquals(testContacts.size(), OCRRecords.size());

	}


	/**
	 * Test functionality that prevents multiple OPH records from being flagged as "Purchase" for a given store
	 * @author Steve O'Neal
	 * @date   2017-06-01
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-5737
	 */
	@isTest
	static void test_BAP_5737()
	{
		integer numberOfRecords = 1;
		// create test data
        List<Account> testAccounts = TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
		List<Opportunity> testOpportunities = TestDataFactory.createTestOpportunities(1, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase'));
		List<Zuora__Subscription__c> testSubscriptions = TestDataFactory.createFullSuiteOfTestZuoraSubscriptionData(numberOfRecords, testOpportunities);
		System.debug(testSubscriptions);

		// create some pre-existing OPH records
		List<Opportunity_Product__c> preExistingOPH = TestDataFactory.createTestOpportunityProductHistories(testOpportunities, 6);
		// make some of the records purchases and some of them trials
		boolean isTrial = true;
		Date startDate = Date.today();
		for (Opportunity_Product__c oph : preExistingOPH)
		{
			oph.isTrial__c = isTrial;
			oph.StartDate__c = startDate;
			oph.ExpirationDate__c = oph.StartDate__c.addYears(1);

			if (isTrial)
			{
				oph.MonthlyRecurringRevenue__c = 0;
				oph.Product__c = 'Trial';
				oph.RevenueChange__c = -50;
			}
			else
			{
				oph.MonthlyRecurringRevenue__c = 50;
				oph.Product__c = 'Enterprise';
				oph.RevenueChange__c = 50;
				oph.Purchase__c = true;
			}

			isTrial = !isTrial;
			startDate = startDate.addYears(1);
		}

		update preExistingOPH;
		
		// run the batch job
		Test.startTest();
		BatchOppMsgQ_OppProductHistory bomsq_oph = new BatchOppMsgQ_OppProductHistory();
		Database.executeBatch(bomsq_oph);
		Test.stopTest();

		List<Id> opportunityIds = new List<Id>();
		for (Opportunity testOpportunity : testOpportunities)
		{
			opportunityIds.add(testOpportunity.Id);
		}

		// make sure only one of the OPH records is marked as a purchase
		List<Opportunity_Product__c> OPHRecordsPurchased = [Select Id, Purchase__c from Opportunity_Product__c where OpportunityID__c = :opportunityIds and Purchase__c = true];
		System.assertEquals(1, OPHRecordsPurchased.size());
	}


	/**
	 * Create cases from Message Queue records
	 * @author Steve O'Neal
	 * @date   2018-04-16
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-7040
	 */
	@isTest
	static void TestBatchOppMsgQ_CreateCase()
	{
		integer numberOfRecords = 1;
        List<Account> testAccounts = TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        List<Contact> testContacts = TestDataFactory.createTestContacts(1, testAccounts);
		List<Opportunity> testStoreOpportunities = TestDataFactory.createTestOpportunities(1, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Trial'));
		List<Opportunity> testOpportunities = TestDataFactory.createTestOpportunities(numberOfRecords, testAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Professional_Services'));
		BatchOppMsgQ_CreateCase bomq_cc = new BatchOppMsgQ_CreateCase();

		// set the opportunity line items
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
        List<Product2> products = TestDataFactory.createTestProduct2s(bomq_cc.productFamiliesForCases.size());
        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();

        for (integer i = 0; i < products.size(); i++)
        {
        	products[i].Family = bomq_cc.productFamiliesForCases[i];
        	priceBookEntries.add(new PricebookEntry(pricebook2id = ZuoraUtility.ZuoraPriceBookId, product2Id = products[i].Id, unitPrice = 100, isActive = true));
        }
        update products;
        insert priceBookEntries;


        for (PricebookEntry pbentry : [Select id, UnitPrice from PricebookEntry where IsActive = true and Product2.Family in :bomq_cc.productFamiliesForCases])
		{
	        for (Opportunity testOpportunity : testOpportunities)
	        {
				lineItems.add(new OpportunityLineItem());
				lineItems[lineItems.size()-1].PricebookEntryId = pbentry.Id;
				lineItems[lineItems.size()-1].OpportunityId = testOpportunity.Id;
				lineItems[lineItems.size()-1].Quantity = 1;
				lineItems[lineItems.size()-1].TotalPrice = pbentry.UnitPrice;
			}
	    }

	    insert lineItems;
	    System.debug(lineItems);

        for (Opportunity testOpportunity : testOpportunities)
        {
		    testOpportunity.StageName = 'Closed Won';
		    testOpportunity.Migration_Platform__c  = 'test';
		    testOpportunity.Current_Store_URL__c = 'test.com';
		    testOpportunity.Store_Opportunity__c = testStoreOpportunities[0].Id;
		}

	    System.debug(testOpportunities);
	    // close the opportunity
	    update testOpportunities;

	    // verify that the createcase omq was created
		List<Opportunity_Message_Queue__c> OMQs = [Select Id from Opportunity_Message_Queue__c where Task__c = :MessageQueueUtilities.taskStringCreateCase];

		System.assert(OMQs.size() == testOpportunities.size());


		Test.startTest();
		Database.executeBatch(bomq_cc);
		Test.stopTest();


	}
}