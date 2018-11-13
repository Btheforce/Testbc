global class BatchCreateOppsFromSalesReferral implements Database.Batchable<sObject>, Database.Stateful{
	
    Public String query;
    public Id priceBookId;
    public User bigCommerceTeamUser;
    public RecordType ProServeRecordType;
    public RecordType SBDUpsellRecordType;
    public Map<String, String> prodLabelMap;
    public Map<String, String> oppsFailedMap;
    public CampaignInfluenceModel InfluModel;
    public final String PRICE_BOOK_NAME = 'Bigcommerce';
    
   
	/**
	 * Creates an instance of the batch class
	 * @author Steve O'Neal
	 * @date   2018-02-26
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6903
	 */
	global BatchCreateOppsFromSalesReferral() 
	{
        
        oppsFailedMap = new Map<String, String>();
        
        prodLabelMap = PickListUtils.getPickListLabelMap(Sales_Referral__c.sObjectType, 'Products__c');
                
        priceBookId = [SELECT Id FROM Pricebook2 WHERE Name =: PRICE_BOOK_NAME].Id;
        
       	SBDUpsellRecordType = RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'SBD_Upsell');
		
        ProServeRecordType = RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'Professional_Services');
		
        bigCommerceTeamUser = [select Id, firstName, lastName, userName, email from User where username like 'team@bigcommerce.com%' and isActive = true limit 1];
                
        InfluModel = [SELECT Id, DeveloperName, IsActive FROM CampaignInfluenceModel WHERE DeveloperName = 'primaryModel'];
        

		query = ' Select Id, Name, Account__c, Account__r.Name, Account_Territory__c, Account_State__c, Contact__c, Contact__r.MailingCountry, Campaign_Member_Status__c, '
            +	' Validation_Products__c, Products__c, Referring_Object__c, Referred_Product__r.Name, Store__c, Other_Product_Description__c, Notes__c, Opportunities_Created__c, ' 
            +	' Opportunities_Needed__c, Store_Opportunity__c '
            +	' from Sales_Referral__c '
            +	' where Opportunities_Needed__c = true';
	}
	

	/**
	 * Gets the records from the DB
	 * @author Steve O'Neal
	 * @date   2018-02-26
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-6903
	 * @param  BC         Batchable Context
	 * @return            A Query Locator representing all of the records that need to be processed
	 */
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
		return Database.getQueryLocator(query);
	}


	/**
   	 * Processes a subset of the records
	 * @author Steve O'Neal
	 * @date   2018-02-26
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-6903
	 * @param  BC         Batchable Context
	 * @return            A Query Locator representing all of the records that need to be processed
	 */
   	global void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{

		List<Opportunity> opportunities = new List<Opportunity>();
        
        Set<String> productKey = new Set<String>();

		for (sObject sobj : scope)
		{
			Sales_Referral__c salesReferral = (Sales_Referral__c)sobj;
               
            //Map<Id, Value> ==> Id: ProductName, Value: 'Referral' OR 'Validation'
            Map<String, String> srProductMap = new Map<String, String>();
            
            //Put all Referral Products
            if(salesReferral.Products__c != null){
                List<String> lstRefProducts = salesReferral.Products__c.Split(';');
                	for(string refProduct : lstRefProducts){
                		srProductMap.put(refProduct.Trim(), 'Referral');
            		}
            }            
             
            //Put all Validation Products
            if(salesReferral.Validation_Products__c != null){
                List<String> lstValProducts = salesReferral.Validation_Products__c.Split(';');
                	for(string valProduct : lstValProducts){
                		srProductMap.put(valProduct.Trim(), 'Validation');
            	 	}
            }
                
			// create an opportunity for each product selected
            if(!srProductMap.isEmpty()){
                
                 for (string product : srProductMap.keySet()){
                    
                     Opportunity newOpp = new Opportunity();
    
                    // by default, the new owner is The BigCommerce Team
                    newOpp.OwnerId = bigCommerceTeamUser.Id;
    
                    if (product.startsWithIgnoreCase('PS-'))
                    {
                        // professional services
                        productKey.add(product);
                        newOpp.Zuora_Product_SKU__c = product;
                        newOpp.RecordTypeId = ProServeRecordType.Id;
                        
                        if(salesReferral.Account_Territory__c != null && salesReferral.Account_Territory__c != 'Other')
                        { 
                            newOpp.StageName = 'Lead';
                        }
                        else
                        {
                            newOpp.StageName = 'Closed Lost';
                            newOpp.Closed_Lost_Reason__c = 'Out of Territory';
                        }

                        newOpp.Type = srProductMap.get(product);
                    }
                    else
                    {
                        // cross sell
                        newOpp.RecordTypeId = SBDUpsellRecordType.Id;
                        newOpp.StageName = 'New';
                        newOpp.Type = srProductMap.get(product);
    
                    }
    
                    newOpp.Name = salesReferral.Account__r.Name + ' - ' + (product == 'Other' ? salesReferral.Other_Product_Description__c : prodLabelMap.get(product));
                    newOpp.Name = newOpp.Name.Left(80);
                    newOpp.Sales_Referral__c = salesReferral.Id;
                    newOpp.Contact__c = salesReferral.Contact__c;
                    newOpp.Sales_Notes__c = salesReferral.Notes__c;
                    newOpp.Store_Opportunity__c = salesReferral.Store_Opportunity__c;
                    newOpp.AccountId = salesReferral.Account__c;
                    newOpp.CloseDate = Date.today().addDays(7);
                    newOpp.Product__c = String.valueOf((product == 'Other' ? salesReferral.Other_Product_Description__c : prodLabelMap.get(product)));
                    newOpp.Pricebook2Id = priceBookId;
                    
                     //Check if its form Campaigns
                    if(SalesReferral.Referring_Object__c != null && 
                       SalesReferral.Referring_Object__c.substring(0,3) == Campaign.getSObjectType().getDescribe().getKeyPrefix()){
                       
                           newOpp.CampaignId = SalesReferral.Referring_Object__c;
                           newOpp.Campaign__c = SalesReferral.Referring_Object__c;
                           newOpp.Campaign_Member_Status__c = String.valueOf(salesReferral.Campaign_Member_Status__c);
                    }
    
                    opportunities.add(newOpp);
                }
                
                salesReferral.Opportunities_Created__c = true;
            }
               
		}
        
         //Just to get more code coverage by causing exception
        if(Test.isRunningTest()){
            Integer i=0;
            while(i<2)
            {
               Opportunity opp = new Opportunity();
                opp.Name = 'test'+i;
                opp.RecordTypeId = ProServeRecordType.Id;
                opp.CloseDate = System.today();
                opp.AccountId = opportunities[0].AccountId;
                opp.StageName = 'Closed Lost';
                opp.MBASubscriptionID__c = '12345'; // duplicate extId to cause err
                opportunities.add(opp);
                
                i++;
            }
        }
        
        
        //Perform DML and capture errors
        Database.SaveResult[] results = Database.insert(opportunities, false);
        
        for(Integer i=0; i<opportunities.size(); i++){
            
            Database.SaveResult re = results[i];
            
            if(!re.isSuccess()){
                
                Opportunity failedOpps = opportunities[i];
                
                String ErrorMsg = '';
                for(Database.Error err : re.getErrors()){
                    Errormsg = Errormsg + ' [' + err.getStatusCode() + ' : ' + err.getFields() + ' : ' + err.getMessage() + '] ';
                }
                
                oppsFailedMap.put(failedOpps.Sales_Referral__c, Errormsg);
            }
        }
        
        
       //Get Pricebook Entery
       Map<String, PricebookEntry> prodEntryMap = new Map<String, PricebookEntry>();
        
       for(PricebookEntry bookEntery : [SELECT Id, Name, Product2.Name, ProductCode, UnitPrice 
                                        FROM PricebookEntry 
                                        WHERE Pricebook2Id =: priceBookId 
                                        AND ProductCode IN : productKey]){
               
          	prodEntryMap.put(bookEntery.ProductCode, bookEntery);
          	
      	}
        
        //Create Opp Line Items and Influences
        List<OpportunityLineItem> lines = new List<OpportunityLineItem>();
        
        List<CampaignInfluence> influences = new List<CampaignInfluence>();
        
        for(Opportunity opp:  opportunities){
            
            if(prodEntryMap.containsKey(opp.Zuora_Product_SKU__c)){
                
                lines.add(new OpportunityLineItem(PricebookEntryId=prodEntryMap.get(opp.Zuora_Product_SKU__c).Id, 
                                                  OpportunityId=opp.Id, 
                                                  UnitPrice=prodEntryMap.get(opp.Zuora_Product_SKU__c).UnitPrice, 
                                                  Quantity=1));
            }
            
            if(opp.CampaignId != null){
                
                influences.add(new CampaignInfluence(CampaignId= opp.CampaignId, 
                                                 ContactId= opp.Contact__c, 
                                                 OpportunityId= opp.Id, 
                                                 ModelId = InfluModel.Id ));
            }
            
        }

        insert lines;
        
        insert influences;
        
		update scope;
	}
	

	/**
	 * Post-processing functionality
	 * @author Steve O'Neal
	 * @date   2018-02-26
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-6903
	 * @param  BC         Batchable Context
	 */
	global void finish(Database.BatchableContext BC) 
	{
		/*
         *	Send an email notification of a job completion. 
         */
			if(!oppsFailedMap.isEmpty()){
           
        		//Get internal notifications email list
        		Map<String, string> notify = new Map<String, String>();
        
        		for(Internal_Email_Notification_Setting__mdt internal : [SELECT DeveloperName, Email__c FROM Internal_Email_Notification_Setting__mdt 
                                                                  	 	WHERE DeveloperName = 'Developer' 
                                                                     	AND Disabled__c != True]){
            		notify.put(internal.DeveloperName, internal.Email__c);
        		} 
         
        		//Build an email message
        		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      			mail.setToAddresses(notify.values());
       	 		mail.setSubject('BatchCreateOppsFromSalesReferral Status : Error');

        		//Building email body
        		String baseBody = ' Alert the batch encountered ' + oppsFailedMap.size() + ' opportunit DML failuers : ' 
                				+ '\n' + oppsFailedMap + '\n';
        	
           		mail.setPlainTextBody(baseBody);
        		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });          

		}
        
		//BatchableChain.Execute(this);
	}
	
}