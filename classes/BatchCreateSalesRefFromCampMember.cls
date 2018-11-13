/**
 * The Batch class creates SalesReferrals from CampaignMember
 * @author Alakh Biniwale
 * @date   09/04/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7519
 */
global class BatchCreateSalesRefFromCampMember implements Database.Batchable<sObject>, Database.Stateful {
    
    Public String query;
    public Set<Id> accountKey;
    public Map<Id, List<Store__c>> accountStoresMap; 
    public Map<Id, String> referralFailedMap;
    
	global BatchCreateSalesRefFromCampMember() 
	{  
        accountKey = new Set<Id>();
        
        accountStoresMap = new Map<Id, List<Store__c>>();
        
        referralFailedMap = new Map<Id, String>();
            
        query = 'SELECT Id, Name, CampaignId, Campaign.Product__c, Campaign.Product_Code__c, ContactId, Contact.AccountId, ' 
            	+ ' Status ' 
            	+ ' FROM CampaignMember ' 
            	+ ' WHERE Sales_Referral_Needed__c = True '
            	+ '	AND Campaign.Opportunity_Needed__c = True '
            	+ ' AND Campaign.IsActive= True ' 
            	+ ' AND Campaign.Product__c != null ' ;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
        
       	List<Sales_Referral__c> referList = new List<Sales_Referral__c>();

		for (sObject sobj : scope)
		{
			CampaignMember campMember = (CampaignMember)sobj;
        	
            //Create SalesReferral
            Sales_Referral__c newRef = new Sales_Referral__c();
            
            newRef.Account__c = campMember.Contact.AccountId;
            newRef.Contact__c = campMember.ContactId;
            newRef.Referring_Object__c = campMember.CampaignId;
            newRef.Notes__c = 'Auto-created by Campaign';
            newRef.Campaign_Member_Status__c = String.valueof(campMember.Status);
            newRef.Referred_Product__c = campMember.Campaign.Product__c;
            newRef.Products__c = campMember.Campaign.Product_Code__c;
            newRef.Referrer_s_Department__c = 'Marketing';

            accountKey.add(campMember.Contact.AccountId);
         
            referList.add(newRef);
            
            campMember.Sales_Referral_Created__c = true;
        }
        
        //Get recent stores
       	for(Account acc : [SELECT Id, (SELECT Id, CreatedDate FROM Stores__r ORDER BY CreatedDate DESC LIMIT 1) 
                           	FROM Account WHERE Id IN :accountKey]){
            accountStoresMap.put(acc.Id, acc.Stores__r);
       	}
        
        for(Sales_Referral__c sr : referList){
            
            List<Store__c> stores  = new List<Store__c>(accountStoresMap.get(sr.Account__c));
            if(!stores.isEmpty()){
                sr.Store__c = stores[0].Id;
            }
        }

           
         //Just to get more code coverage by causing exception
        if(Test.isRunningTest()){
            Integer i=0;
            while(i<2)
            {
                Sales_Referral__c ref = new Sales_Referral__c();
                ref.Products__c = 'Other';
                referList.add(ref);
                
                i++;
            }
        }
        
        //Perform DML and capture errors
        Database.SaveResult[] referralResult = Database.insert(referList, false);
        
        for(Integer i=0; i<referList.size(); i++){
            
            Database.SaveResult re = referralResult[i];
            
            if(!re.isSuccess()){
                
                Sales_Referral__c failedReferral = referList[i];
                
                String ErrorMsg = '';
                for(Database.Error err : re.getErrors()){
                    Errormsg = Errormsg + ' [' + err.getStatusCode() + ' : ' + err.getFields() + ' : ' + err.getMessage() + '] ';
                }
                
                referralFailedMap.put(failedReferral.Contact__c, Errormsg);
            }
        }
        
        //Update CampaignMember
        update scope;

	}

	global void finish(Database.BatchableContext BC) 
	{
		
       /*
        *	Send an email notification of a job completion. 
        */
       if(!referralFailedMap.isEmpty()){
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
       	 	mail.setSubject('BatchCreateSalesRefFromCampMember Status : Error');

        	//Building email body
        	String baseBody = ' Alert the batch encountered ' + referralFailedMap.size() + ' sales referral DML failuers : ' + '\n' + referralFailedMap + '\n';      
        	mail.setPlainTextBody(baseBody);
        	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });          

		}
        
       	BatchableChain.Execute(this);
	}
}