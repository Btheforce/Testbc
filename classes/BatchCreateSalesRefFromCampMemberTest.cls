/**
  * @description Test Class for BatchCreateSalesRefFromCampMember
  * @author Alakh Biniwale
  * @date   09/04/2018
  */
@isTest
public class BatchCreateSalesRefFromCampMemberTest {

     /**
	 * @dscription Setup test data
	 * @author Alakh Biniwale
	 * @date  09/04/2018
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

        // Create 2 contacts, 1 per account
        List<Contact> testContacts = TestDataFactory.CreateTestContacts(1, testAccounts);
		
		// Create 2 trial opps, 1 per account
        List<Opportunity> storeOpps = TestDataFactory.createTestOpportunities(1, testAccounts, 
                                                                              RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Trial'));
        
        // Create 2 store, 1 per account		
        List<Store__c> testStores = TestDataFactory.CreateTestStores(1, testAccounts);
        
        //Associate store opps with stores
        for(Opportunity opp : storeOpps){
            for(Store__c st : testStores){ 
                if(opp.AccountId == st.Account__c){
                    opp.MBASubscriptionID__c = st.Hosting_ID__c;
                }
            }   
        }
        
        update storeOpps;
        
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
        
		//Create Pricebook
        Pricebook2 bcPricebook = new Pricebook2(Name='Bigcommerce', isActive=true);
    	insert bcPricebook;

    	PricebookEntry entery = new PricebookEntry(Pricebook2Id = bcPricebook.Id, Product2Id = prod.Id, UnitPrice = 499, IsActive = true);
    	insert entery;
        
        // Create 1 campaign
        List<Campaign> testCamp = TestDataFactory.createTestCampaigns(1);
        
        testCamp[0].IsActive= true;
        testCamp[0].Product__c =  prod.Id;
        testCamp[0].Opportunity_Needed__c = true;
        
        update testCamp;
                
        // Create 2 campaignMember
        List<CampaignMember> testCampMemb  = TestDataFactory.createTestCampaignMembers(testCamp, false, testContacts);
      
    }
   
       
   /**
	 * @dscription Test Batch functionality
	 * @author Alakh Biniwale
	 * @date  09/04/2018
	 */
    @isTest static void BatchCreateSalesRefTest(){
        
        List<CampaignMember> campMembers = [SELECT Id, Name, CampaignId, Campaign.Product__c, Campaign.Product_Code__c, 
                                    		ContactId, Contact.AccountId, Status 
                                    		FROM CampaignMember];
        
        
        Test.startTest();
        BatchCreateSalesRefFromCampMember bc = new BatchCreateSalesRefFromCampMember();
		Database.executeBatch(bc);
		Test.stopTest();
        
        
        List<Sales_Referral__c> lstSalesRef = [Select Id, Name, Products__c, Referring_Object__c, Contact__c, Referred_Product__c
                                               	from Sales_Referral__c 
                                               	where Opportunities_Needed__c = true];
        
        //Batch should create salesRef equivalent
         
        System.assertEquals(campMembers.size(), lstSalesRef.size());
        

    }
}