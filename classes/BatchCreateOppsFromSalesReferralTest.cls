/**
  * @description Test Class for BatchCreateOppsFromSalesReferral
  * @author Alakh Biniwale
  * @date   04/30/2018
  */
@isTest
public class BatchCreateOppsFromSalesReferralTest {

    /**
	 * @dscription Setup test data
	 * @author Alakh Biniwale
	 * @date  04/30/2018 
	 */
    @testSetup static void init(){
      
        /**
         * Account, Contact and Store are required records in order to
         * create sales referral
         */
        //First create dependent records required for creation of sales referral record
        
        // Create 2 accounts
		List<Account> testAccounts = TestDataFactory.CreateTestAccounts(2, false, 
                                                                        RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
		
        // Create 1 contact 1 per account
        List<Contact> testContacts = TestDataFactory.CreateTestContacts(1, testAccounts);
		
        // Create 1 stores 1 per account		
        List<Store__c> testStores = TestDataFactory.CreateTestStores(1, testAccounts);
        
         //Create Product
		 Map<String, String> labelMap = PickListUtils.getPickListLabelMap(Sales_Referral__c.SObjectType, 'Products__c');
        
        Product2 prod = new Product2();
    	prod.RecordTypeId =  Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Product').getRecordTypeId();
        prod.ProductCode = Randomizer.getRandomString(new List<String>(labelMap.keySet()));
        prod.Name = labelMap.get(prod.ProductCode);
        prod.IsActive = true;
        prod.Family = 'Consulting Services';
    	
        insert prod;
        
        //Create Pricebook
        Id pricebookId = Test.getStandardPricebookId();

    	PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 0, IsActive = true);
        insert standardPrice;

    	Pricebook2 bcPricebook = new Pricebook2(Name='Bigcommerce', isActive=true);
    	insert bcPricebook;

    	PricebookEntry entery = new PricebookEntry(Pricebook2Id = bcPricebook.Id, Product2Id = prod.Id, UnitPrice = 499, IsActive = true);
    	insert entery;
        
       	 /**
         * create sales referral Records
         */
        //Create Map<StoreId, ContactId> one on one mapping between Store and Contact
        Map<Id, Id> StrContIdMap = new Map<Id, Id>();
        
        for(Integer i=0; i<testContacts.size(); i++){
            if(testContacts[i].AccountId == testStores[i].Account__c){
                StrContIdMap.put(testStores[i].Id, testContacts[i].Id);
            }
        }
        //Now Create Sales referral records
        List<Sales_Referral__c> testSalesRefs = new List<Sales_Referral__c>();
      
        for(Store__c store : testStores){
  			
            Sales_Referral__c salesRef = new Sales_Referral__c();
        	salesRef.Account__c = store.Account__c;
			salesRef.Store__c = store.Id;
			salesRef.Contact__c = StrContIdMap.get(store.Id);
            
			Set<String> refPrdSet = new Set<String>();
        	Set<String> valPrdSet = new Set<String>();
            
            //Randomly select 3 MultiPicklist values and add to the Sets
            //Make Sure refPrdSet and valPrdSet are mutully exclusive, so there should be no duplicates. 
      
            while(refPrdSet.size()<1){
                
               refPrdSet.add(PickListUtils.getRandomPickListValue(Sales_Referral__c.sObjectType, 'Products__c')); 
            }
            
            while(valPrdSet.size()<1){
                
                String valPrd = PickListUtils.getRandomPickListValue(Sales_Referral__c.sObjectType, 'Validation_Products__c');
                if(!refPrdSet.contains(valPrd)){
                   valPrdSet.add(valPrd); 
                }
            }

            
            salesRef.Products__c = String.join(new List<String>(refPrdSet), ';') + ';';
            salesRef.Validation_Products__c = String.join(new List<string>(valPrdSet), ';') + ';';
            
            
            if(salesRef.Products__c.containsIgnoreCase('Other') || 
               	salesRef.Validation_Products__c.containsIgnoreCase('Other')){
                    
                salesRef.Other_Product_Description__c = 'Test descp';
            }
            
           	salesRef.Notes__c = 'test';
			
            testSalesRefs.add(salesRef);
     
        }
        
        //Finally Insert SalesReferral
		insert testSalesRefs;

    }
   
   /**
	 * @dscription Test Batch functionality
	 * @author Alakh Biniwale
	 * @date  04/30/2018 
	 */
    @isTest static void BatchCreateOppsTest(){
        
        
        RecordType SBDUpsellRecordType = RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'SBD_Upsell');
		RecordType ProServeRecordType = RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'Professional_Services');
        
       
        List<Sales_Referral__c> lstSalesRef = [Select Id, Name,  Validation_Products__c, Products__c, Store_Opportunity__c 
                                               	from Sales_Referral__c 
                                               	where Opportunities_Needed__c = true];

        List<String> referralProducts = new List<String>();
        List<String> validationProducts = new List<String>();
        
        for(Sales_Referral__c sr : lstSalesRef){
                            
            if(sr.Products__c != null){
                referralProducts.addAll(sr.Products__c.Split(';'));
             }
            
            if(sr.Validation_Products__c != null){
                validationProducts.addAll(sr.Validation_Products__c.Split(';'));
            }

        }
        
		Test.startTest();
        BatchCreateOppsFromSalesReferral bc = new BatchCreateOppsFromSalesReferral();
		Database.executeBatch(bc);
		Test.stopTest();
        
        List<Opportunity> opportunities = [select Id, RecordTypeId, Sales_Referral__c, Store_Opportunity__c, Type,
                                           	Product__c
                                          	from Opportunity 
                                           	where Sales_Referral__c IN : lstSalesRef];
        
     	//Check Total opps created are equal to total of referral and validation products
       System.assertEquals(referralProducts.size() + validationProducts.size(), opportunities.size());
       
        Integer referralOpps = 0;
        Integer validationOpps = 0;
            
        for(Opportunity opp : opportunities){
            
            if(opp.Product__c.startsWithIgnoreCase('Services')){
                //check opps created for Service Products have Professional Services Record Type
                System.assertEquals(ProServeRecordType.Id, opp.RecordTypeId);
            }
            else{
				//check opps created for cross sell/other products have SBDupsell Record Type 
                System.assertEquals(SBDUpsellRecordType.Id, opp.RecordTypeId);
            }     
            
            if(opp.Type == 'Referral'){
                referralOpps++;
            }
            else if(opp.Type == 'Validation'){
                validationOpps++;
            }
        }
		//check Opps created by Type 'referral' for all referral Product
       System.assertEquals(referralOpps, referralProducts.size());
        //check Opps created by Type 'validation' for all validation Product
       System.assertEquals(validationOpps, validationProducts.size());
        
    }

}