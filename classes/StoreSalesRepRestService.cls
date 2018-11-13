/**
 * @description REST webservice to identify Which stores are actively worked by sales reps
 * @author Alakh Biniwale
 * @date 05/18/2018
 * @ticket link	https://jira.bigcommerce.com/browse/BAP-7240
 */
@RestResource(urlMapping= '/api/store_sales_reps/*')
global with sharing class StoreSalesRepRestService {
    
    @TestVisible private static final string QUERY_PARAM = 'hosting_id'; 
    @TestVisible private static final string BC_TEAM_USER_EMAIL = 'team@bigcommerce.com';
	
    
    /**
     * @description REST GET Method, query opportunities usting hostingId 
     * and resturn opp owner info as payload.
     * @author Alakh Biniwale
     * @date 05/18/2018
     * @return JSON payload
     */
    @HttpGet
    global static Payload getSalesRepsByHostingId(){
        
        List<SalesRepWrapper> data = new List<SalesRepWrapper>();
        List<String> hostingIds = new List<string>();
        
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
           
            
        if(request.params.containsKey(QUERY_PARAM)){
            hostingIds = request.params.get(QUERY_PARAM).split(',');
            if(hostingIds.contains('')){
                hostingIds.remove(hostingIds.indexOf(''));
            }
            
        }
        else{
            response.statusCode = Integer.valueOf(400); // 400 -->	BAD_REQUEST
            return new Payload(Status.ERROR, 'BAD_REQUEST', data);
        }
        

        if(!hostingIds.isEmpty()){
            
             List<Opportunity> lstOpps = [SELECT Id, Name, MBASubscriptionID__c, 
                                    		Owner.Name, Owner.Email, Owner.Phone, Owner.isActive                     		
                                		    	FROM Opportunity WHERE MBASubscriptionID__c IN :hostingIds ];
        	if(!lstOpps.isEmpty()){
            
        		for(Opportunity opp : lstOpps){
           			
                    SalesRepWrapper retVal = new SalesRepWrapper(); 
            		retVal.store_hosting_id = opp.MBASubscriptionID__c;
            		retVal.sales_rep_name = opp.Owner.Name;
            		retVal.sales_rep_email = opp.Owner.Email;
            		retVal.sales_rep_phone = opp.Owner.Phone;
            	
                	if(opp.Owner.isActive && opp.Owner.Email != BC_TEAM_USER_EMAIL){  
              			retVal.store_worked_by_sales_rep = true;
            		}
            
                	data.add(retVal);
        		} 
        	}
            
        }
        
        return new Payload(Status.SUCCESS, data);
    }
    
    
    
    //Enum for JSON response status
    global enum Status {SUCCESS, ERROR}
    
    /**
     * @description JSON payload for the REST Service 
     * @author Alakh Biniwale
     * @date 05/18/2018
     */
    global class Payload{
        public Status status;
        public String message;
        public List<SalesRepWrapper> data;
        public Integer size;
        
        Payload(Status state, string msg, List<SalesRepWrapper> salesReps){
            this.status = state;
            this.message = msg;
            this.data = salesReps;
            this.size = salesReps.size();
        }
        Payload(Status state, List<SalesRepWrapper> salesReps){
            this.status = state;
            this.message = (salesReps.size() == 0 ? 'records not found' : 'records found');
            this.data = salesReps;
            this.size = salesReps.size();
        }
    }
    
    /**
     * @description A wrapper class to build JSON response
     * @author Alakh Biniwale
     * @date 05/18/2018
     */
    global class SalesRepWrapper{
        
        public String store_hosting_id;
        public String sales_rep_name;
        public String sales_rep_email;
        public String sales_rep_phone;
        public Boolean store_worked_by_sales_rep;
        
        SalesRepWrapper(){
           this.store_worked_by_sales_rep = false;
        }
        
    }
}