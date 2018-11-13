/**
  * @description Test Class for StoreSalesRepRest
  * @author Alakh Biniwale
  * @date   05/18/2018
  * @ticket link	https://jira.bigcommerce.com/browse/BAP-7240
  */
@isTest(isParallel = true)
public class StoreSalesRepRestServiceTest {
   
    private static final Integer NUM_OF_RECORDS = 3;
    private static String HostingIds;
    
  /**
   * @dscription Setup test data
   * @author Alakh Biniwale
   * @date  05/18/2018 
   */
    private static void init(){
        
        // Create 3 accounts
        List<Account> testAccounts = TestDataFactory.CreateTestAccounts(NUM_OF_RECORDS, false, 
                                                                        RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        
        // Create 9 Opps 3 per account
        List<Opportunity> testOpps = TestDataFactory.CreateTestOpportunities(NUM_OF_RECORDS, testAccounts, 
                                                                            RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Trial'));
        List<string> lsthostId = new List<string>();
          
		for(Opportunity opp : testOpps){
            
            String hostId;

             do{

                hostId = String.valueof(MathUtility.RandomInteger(1000, 9999));

             }while(lsthostId.contains(hostId)); //MBASubscriptionID__c should be Text(255) (External ID) (Unique Case Insensitive)
             
            lsthostId.add(hostId);

            opp.MBASubscriptionID__c = hostId;
            
        }
        
        HostingIds = String.join(lsthostId,',');
        //System.debug('HostingIds>>' + HostingIds);
        
    	update testOpps;
    }
    
  /**
   * @dscription Success result test
   * @author Alakh Biniwale
   * @date  05/18/2018 
   */
    @isTest
    static void getSalesRepsByHostingIdTestOne(){
        
        init();
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        
        req.requestURI = '/services/apexrest/api/store_sales_reps';
        
        req.addParameter('hosting_id', HostingIds);
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        StoreSalesRepRestService.Payload retVal = StoreSalesRepRestService.getSalesRepsByHostingId();
        Test.stopTest();
        
        System.assertEquals(9, retVal.size);
        System.assertEquals(StoreSalesRepRestService.Status.SUCCESS, retVal.status);
        
    }
    
  /**
   * @dscription Empty hosting_id result test
   * @author Alakh Biniwale
   * @date  05/18/2018 
   */
    @isTest
    static void getSalesRepsByHostingIdTestTwo(){
        
        init();
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        
        req.requestURI = '/services/apexrest/api/store_sales_reps';
        
        req.addParameter('hosting_id', ''); // put empty string for hosting_id param
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        StoreSalesRepRestService.Payload retVal = StoreSalesRepRestService.getSalesRepsByHostingId();
        Test.stopTest();
        
        System.assertEquals(0, retVal.size);
        System.assertEquals('records not found', retVal.message);
        
    }
    
  /**
   * @dscription Bad request result test
   * @author Alakh Biniwale
   * @date  05/18/2018 
   */
    @isTest
    static void getSalesRepsByHostingIdTestThree(){
        
        init();
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        
        req.requestURI = '/services/apexrest/api/store_sales_reps';
        
        req.addParameter('hosting_Id', HostingIds); // put wrong-typeo "hosting_Id" param
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        StoreSalesRepRestService.Payload retVal = StoreSalesRepRestService.getSalesRepsByHostingId();
        Test.stopTest();
        
        System.assertEquals(0, retVal.size);
        System.assertEquals(StoreSalesRepRestService.Status.ERROR, retVal.status);
        System.assertEquals('BAD_REQUEST', retVal.message);
        
    }
}