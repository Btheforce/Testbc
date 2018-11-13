public with sharing class CreateSalesReferralController 
{
        //Attributes
    	public String retUrlString;
    
    	public String vfParam{get; set;}
        
        public Boolean refParam{get; set;}
        
        public Boolean valParam{get; set;}
    
    	private final Sales_Referral__c salesRef;
    
    	public Sales_Referral__c SalesReferral{get{return salesRef;}}
        
     	private Map<String, ProductWrapper> mpProducts; 
   
    	public List<ProductWrapper> wProducts{get{return mpProducts.values();} set;}
    
    	private ApexPages.StandardController stdController = null;
        

        //Constructor
        public CreateSalesReferralController(ApexPages.StandardController controller){
                stdController = controller;
                salesRef = (Sales_Referral__c)stdController.getRecord();
                mpProducts = getProductWrap();
            
                try{
                    init();
                }catch(Exception excInit){
                        System.debug(excInit);
                }
            
        }

        //Methods
        private void init(){

                // determine what object referred this page and what the return URL will be
                retUrlString = ApexPages.currentPage().getParameters().get('retUrl');

                // just in case they didn't pass a value in the URL
                if (String.isEmpty(retUrlString))
                {
                        retUrlString = '';
                        return;
                }

                // store the referring record, just in case we need it later
                if (retUrlString.substring(0,0) != '/')
                {
                        SalesReferral.Referring_Object__c = retUrlString;
                }

                // fill the data based on the referenced opportunity
                if (retUrlString.substring(0,3) == Opportunity.getSObjectType().getDescribe().getKeyPrefix())
                {
                        Opportunity opp = [Select Id, Name, AccountId, Account.Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, MBASubscriptionId__c from Opportunity where Id = :retUrlString limit 1];
                        
                        SalesReferral.Account__c = opp.AccountId;

                        if (String.isNotEmpty(opp.Contact__c))
                        {
                                SalesReferral.Contact__c = opp.Contact__c;
                        }

                        if (String.isNotEmpty(opp.MBASubscriptionId__c))
                        {
                                try
                                {
                                        Store__c store = [Select Id from Store__c where Hosting_ID__c = :opp.MBASubscriptionId__c];
                                        SalesReferral.Store__c = store.Id;
                                }
                                catch (Exception excStore)
                                {

                                }
                        }
                }
                // fill in the data based on the referenced Account
                else if (retUrlString.substring(0,3) == Account.getSObjectType().getDescribe().getKeyPrefix())
                {
                        SalesReferral.Account__c = retUrlString;
                }
                // fill in the data based on the referenced Contact
                else if (retUrlString.substring(0,3) == Contact.getSObjectType().getDescribe().getKeyPrefix())
                {
                        Contact cont = [Select Id, Name, AccountId from Contact where Id = :retUrlString limit 1];
                        SalesReferral.Account__c = cont.AccountId;
                        SalesReferral.Contact__c = cont.Id;

                }
                // fill in the data based on the referenced Store
                else if (retUrlString.substring(0,3) == Store__c.getSObjectType().getDescribe().getKeyPrefix())
                {
                        Store__c store = [Select Id, Account__c from Store__c where Id = :retUrlString];
                        SalesReferral.Store__c = store.Id;
                        SalesReferral.Account__c = store.Account__c;
                }
                // fill in the data based on the referenced Case
                else if (retUrlString.substring(0,3) == Case.getSObjectType().getDescribe().getKeyPrefix())
                {
                        Case lCase = [Select Id, AccountId, ContactId, MBA_Subscription_ID__c from Case where Id = :retUrlString];

                        SalesReferral.Account__c = lCase.AccountId;
                        SalesReferral.Contact__C = lCase.ContactId;

                        if (String.isNotEmpty(lCase.MBA_Subscription_ID__c))
                        {
                                try
                                {
                                        Store__c store = [Select Id from Store__c where Hosting_ID__c = :lCase.MBA_Subscription_ID__c];
                                        SalesReferral.Store__c = store.Id;
                                }
                                catch (Exception excStore)
                                {

                                }
                        }

                }

                // if there's a contact associated with the referral, see if they are the primary contact on one store
                if (SalesReferral.Store__c == null && SalesReferral.Contact__c != null){
                        List<Store_Contact_Roles__c> storeContactRoles = [Select Id, Contact__c, Store__c, Contact_Role__c from Store_Contact_Roles__c where Contact__c = :SalesReferral.Contact__c and Contact_Role__c like '%primary%'];

                        if (storeContactRoles.size() == 1){
                                SalesReferral.Store__c = storeContactRoles[0].Store__c;
                        }
                }

                // if there's only one store associated with the account, assume it is the correct store
                if (SalesReferral.Store__c == null && SalesReferral.Account__c != null){
                        List<Store__c> stores = [Select Id, Account__c from Store__c where Account__c = :SalesReferral.Account__c];

                        if (stores.size() == 1){
                                SalesReferral.Store__c = stores[0].Id;
                        }
                }

                // see if there are any contact roles associated with the store
                if (SalesReferral.Contact__c == null && SalesReferral.Store__c != null){
                        List<Store_Contact_Roles__c> storeContactRoles = [Select Id, Contact__c, Store__c, Contact_Role__c from Store_Contact_Roles__c where Store__c = :SalesReferral.Store__c];

                        for (Store_Contact_Roles__c storeContactRole : storeContactRoles)
                        {
                                if (SalesReferral.Contact__c == null || storeContactRole.Contact_Role__c.containsIgnoreCase('primary'))
                                {
                                        SalesReferral.Contact__c = storeContactRole.Contact__c;
                                }
                        }
                }
        } 
    
        private List<SelectOption> getSelectOption(){
  
                List<SelectOption> options = new List<SelectOption>();
        
                Schema.DescribeFieldResult fieldResult = Sales_Referral__c.Products__c.getDescribe();
   
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
                for( Schema.PicklistEntry f : ple){
                options.add(new SelectOption(f.getValue(), f.getLabel()));
                }       
               
            return options;
        }
    
        private Map<String, ProductWrapper> getProductWrap(){
            
            Map<String, ProductWrapper> mpProds = new Map<String, ProductWrapper>();
            
            for(SelectOption opt : getSelectOption()){
                
                ProductWrapper wProd = new ProductWrapper();
                wProd.product = opt.getLabel();
                wProd.productCode = opt.getValue();
                mpProds.put(opt.getValue(), wProd);
            }
            
            return mpProds;
        }
    
        public PageReference doActionFunction(){
            
            ProductWrapper pw = mpProducts.get(vfParam);
            pw.referral = refParam;
            pw.validation = valParam;
            
            return null;
        }
    
        public PageReference Save(){
		
                String refStr = '';
                String valStr = '';
            
            for(ProductWrapper wProd : wProducts){
                if(wProd.referral){
                    refStr = refStr + wProd.productCode;
                    refStr = refStr + ';';
                }
               
                if(wProd.validation){
                    valStr = valStr + wProd.productCode;
                    valStr = valStr + ';';
                }
            }
            
           	
            if(String.isBlank(refStr) && String.isBlank(valStr)){
                SalesReferral.Products__c.addError('You must check a Product');
                return null;
            }
            
           if((refStr.contains('Other') || valStr.contains('Other')) 
                                && SalesReferral.Other_Product_Description__c == null){
               	SalesReferral.Other_Product_Description__c.addError('You must enter a value');
                return null;
           }
       	else{
                 SalesReferral.Products__c = refStr;
                 SalesReferral.Validation_Products__c = valStr;            
            }
           
           if (stdController.save() == null){
                
                return null;
            }

           return Cancel();
        }

        public PageReference Cancel(){
                
            return new Pagereference('/' + retUrlString);
        }
    
        //Wrapper Class
        public class ProductWrapper {
            
            public String product{get; set;}
            public String productCode{get; set;}
            public Boolean referral{get; set;}
            public Boolean validation{get; set;}
            
            ProductWrapper(){
                this.referral = false;
                this.validation = false;
            }
        }

}