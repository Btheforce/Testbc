/**
 * For creating cases based on events in Opportunities
 * @author Steve O'Neal
 * @date   2018-04-05
 * @ticket link          https://jira.bigcommerce.com/browse/BAP-7040
 */
global class BatchOppMsgQ_CreateCase implements Database.Batchable<sObject> 
{
	Set<string> tasks = new Set<string>();
	string status = 'New';
	
	public String query;
	public List<string> productFamiliesForCases = new List<string>();

	public RecordType caseMigrationRecordType = RecordTypeTools.GetRecordTypeByDeveloperName(Case.getSObjectType(), 'Migration');
	public RecordType caseProserveRecordType = RecordTypeTools.GetRecordTypeByDeveloperName(Case.getSObjectType(), 'Professional_Services');

	// collect the list of records that need to be processed
	Map<Id, List<Opportunity_Message_Queue__c>> changeQueueMap = new Map<Id, List<Opportunity_Message_Queue__c>>();
	
	/**
	 * Creates an instance of the batch class
	 * @author Steve O'Neal
	 * @date   2018-04-05
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-7040
	 */
	global BatchOppMsgQ_CreateCase() 
	{
		System.debug('Instantiating');
		tasks.add(MessageQueueUtilities.taskStringCreateCase);
		productFamiliesForCases.add('Consulting Services');
		productFamiliesForCases.add('Migrations');
		productFamiliesForCases.add('Migration');

		// the query will be against the Staging_Object_Message_Queue__c object, which represents an update event to an MBA Staging record
		query = 'Select ID, Status__c, Task__c, Opportunity__c, Message__c, Attempt_Number__c, Retry_Processing_On_Error__c, Zuora_Subscription_Id__c, Zuora_Subscription_Serialized__c from Opportunity_Message_Queue__c where Task__c = :tasks and Status__c = :status order by Opportunity__c, Task__c desc';
	}
	

	/**
	 * Gets the records from the DB
	 * @author Steve O'Neal
	 * @date   2018-04-05
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-7040
	 * @param  BC         Batchable Context
	 * @return            A Query Locator representing all of the records that need to be processed
	 */
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
		System.debug('Querying');
		System.debug('Query: ' + query);
		System.debug('Task(s): ' + tasks + ' - Status: ' + status);
		return Database.getQueryLocator(query);
	}

   	
   	/**
   	 * Processes a subset of the records
   	 * @author Steve O'Neal
   	 * @date   2018-04-05
   	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-7040
   	 * @param  BC         Batchable Context
   	 * @param  scope      The subset of records to be processed
   	 */
   	global void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
   		System.debug('Executing');
	
   		// get unique opportunity Ids
   		for (sObject sobj : scope)
   		{
   			Opportunity_Message_Queue__c OMQ = (Opportunity_Message_Queue__c)sobj;

   			// fill the change queue map for easier updating
   			Id key = OMQ.Opportunity__c;
   			if (!changeQueueMap.containsKey(key))
   			{
	   			changeQueueMap.put(key, new List<Opportunity_Message_Queue__c>());
	   		}

	   		changeQueueMap.get(key).add(OMQ);
   		}

   		System.debug('Get Opportunities from the database by Opportunity Id: ' + changeQueueMap.keySet());


        Map<Id, Id> map_OppId_ContactId = OpportunityHelper.getContactFromRole(changeQueueMap.keySet(),'Professional Services Contact');
        Map<Id, Id> map_StoreOppId_ProserveOppId = new Map<Id, Id>();

   		List<Case> serviceCases = new List<Case>();
   		// get the line items from the affected opportunities
   		for (OpportunityLineItem oppLineItem : [SELECT Id, OpportunityId, UnitPrice, Family__c, TotalPrice, Opportunity.Current_Store_URL__c, Opportunity.Migration_Platform__c, Opportunity.Sales_Notes__c, Opportunity.OwnerId, Opportunity.RecordTypeId, Opportunity.Amount, Opportunity.IsClosed, Opportunity.AccountId, Opportunity.Subscription__c, Opportunity.Store_Opportunity__c, PricebookEntry.Product2.Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.Family 
   			 									FROM OpportunityLineItem 
   			 									WHERE OpportunityId = :changeQueueMap.keySet() 
   			 									  and PricebookEntry.Product2.Family in :productFamiliesForCases])
   		{
   			// create a case for each item sold
			serviceCases.add(createFulfillmentCase(oppLineItem, map_OppId_ContactId.get(oppLineItem.OpportunityId)));
			map_StoreOppId_ProserveOppId.put(oppLineItem.Opportunity.Store_Opportunity__c, oppLineItem.OpportunityId);
   		}

   		if (serviceCases.size() > 0)
   		{
   			Database.insert(serviceCases, false);
 
    		// upsert the opportunity product history
    		System.debug(serviceCases);
	   		List<Database.UpsertResult> upsertResults = Database.upsert(serviceCases, false);
	   		System.debug(upsertResults);

			for (integer i = 0; i < upsertResults.size(); i++)
			{
				Case saveRecord = serviceCases[i];
				Database.UpsertResult saveResult = upsertResults[i];

				if (!changeQueueMap.containsKey(map_StoreOppId_ProserveOppId.get(saveRecord.Opportunity__c)))
				{
					System.debug(saveRecord.Opportunity__c);
					System.debug(changeQueueMap);
				}

				for (Opportunity_Message_Queue__c messageQueue : changeQueueMap.get(map_StoreOppId_ProserveOppId.get(saveRecord.Opportunity__c)))
				{
					MessageQueueUtilities.setStatusForMessageQueue(messageQueue, saveResult);
				}
			}
  		}
   		
	    // update the processed records
	    update scope;

	    System.debug(scope);

	    // retry failed records in the scope
	    MessageQueueUtilities.createRetryMessages(scope);
	}


	/**
	 * Post-processing functionality
	 * @author Steve O'Neal
	 * @date   2018-04-05
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-7040
	 * @param  BC         Batchable Context
	 */
	global void finish(Database.BatchableContext BC) 
	{
		System.debug('Finishing');
		BatchableChain.Execute(this);
	}


    private Case createFulfillmentCase(OpportunityLineItem oppLineItem, Id caseContact)
    {
        Case newCase = new Case();
        
		Database.DMLOptions dmlOpts = new Database.DMLOptions();
   		dmlOpts.assignmentRuleHeader.useDefaultRule= true;
   		newCase.setOptions(dmlOpts);

        newCase.Origin = 'Internal Request';
        newCase.Subject = 'Client purchase of product';
        newCase.Description = 'Client has purchased ' + oppLineItem.PricebookEntry.Product2.Name;
        newCase.Department__c = 'Professional Services';
        newCase.AccountId = oppLineItem.Opportunity.AccountId;
        newCase.Subscription__c = oppLineItem.Opportunity.Subscription__c;
        newCase.Opportunity__c = oppLineItem.Opportunity.Store_Opportunity__c;
    	newCase.ContactId = caseContact;
    	newCase.Reason = 'New client purchase';

        newCase.Price__c = oppLineItem.TotalPrice;
        newCase.Product_Sold__c = oppLineItem.PricebookEntry.Product2.Name;
        newCase.Sold_by__c = oppLineItem.Opportunity.OwnerId;
        newCase.Sales_Notes__c = oppLineItem.Opportunity.Sales_Notes__c;
        
        
        if (oppLineItem.PricebookEntry.Product2.Family.contains('Migration'))
        {
        	newCase.RecordTypeId = caseMigrationRecordType.Id;
            newCase.Current_Store_URL__c = oppLineItem.Opportunity.Current_Store_URL__c;
            newCase.Migration_Platform__c = oppLineItem.Opportunity.Migration_Platform__c;
            newCase.Subject = 'Your Bigcommerce Migration';
        }
        else
        {
        	newCase.RecordTypeId = caseProserveRecordType.Id;
            newCase.Subject = 'Bigcommerce Professional Services';
        }

        return newCase;
    }
	
}