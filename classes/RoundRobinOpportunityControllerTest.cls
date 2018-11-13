/**
 * Test class for RoundRobinOpportunity
 * @author Alakh Biniwale
 * @date   09/19/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-8113
 */
@isTest
public class RoundRobinOpportunityControllerTest {

        
    @testSetup static void init(){
        
        //create 1 account
        List<Account> testAccounts = TestDataFactory.createTestAccounts(1, false, 
                                             RecordTypeTools.GetRecordTypeByDeveloperName(Account.SobjectType, 'Client_Record_Type'));
        //assign random territory
        for(Account acct : testAccounts){
            
            acct.Territory__c = PickListUtils.getRandomPickListValue(Account.SobjectType, 'Territory__c');
        }
       
        update testAccounts;
        
        //create 1 opportunity
        List<Opportunity> testOpps = TestDataFactory.createTestOpportunities(1, testAccounts, 
                                                        RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.SobjectType, 'Trial'));
        
        //assign picklist values - Note due to recordtype restriction values are hard coded 
        for(Opportunity opp : testOpps){
            
            opp.Actual_Annual_Online_Revenue__c = 'Building a business: $50k–250k revenue';
            opp.Actual_Annual_Offline_Revenue__c = 'Building a business: $50k–250k revenue';
        }   
        
        update testOpps;
          
    }
    
    @isTest static void roundRobinTestOne(){
         

        //set current page context 
        Test.setCurrentPageReference(Page.RoundRobinOpportunity);
        
       //get opportuninty -- case 1 opp ownerId == account.ownerId
        Opportunity opp = [select id, name, ownerId, account.ownerId, account.sales_team_calculated__c, account.territory__c 
                           from opportunity limit 1];
        
        //set current page id parameter        
        ApexPages.currentPage().getParameters().put('id',String.valueOf(opp.Id));
        
        //initialize current page controller with opp
        RoundRobinOpportunityController ctr = new RoundRobinOpportunityController(new ApexPages.StandardController(opp));

    ctr.saveOpportunityAutomatic();
        
        
        //get BC team user
        User bigCommerceTeamUser = [select Id from User where username like 'team@bigcommerce.com%' and isActive = true limit 1];
        
        //get account and update with BC team user
        Account acc = [select ownerId from account limit 1];
        
        acc.ownerId = bigCommerceTeamUser.id;
        
        update acc;
        
        //get opportuninty -- case 2 account.ownerId == bigCommerceTeamUser.Id
        Opportunity opp1 = [select id, name, ownerId, account.ownerId, account.sales_team_calculated__c, account.territory__c 
                           from opportunity limit 1];
        
        //initialize current page controller with opp1
        RoundRobinOpportunityController ctr1 = new RoundRobinOpportunityController(new ApexPages.StandardController(opp1));

        ctr1.saveOpportunityAutomatic();
        

         //get an inactive user
        User inActiveUser = [select Id from User where isActive = false limit 1];
        
        //update with BC team owner
        Account acct = [select ownerId from account limit 1];
        
        acct.ownerId = inActiveUser.id;
        
        update acct;
        
        //get opportuninty -- case 3 account.ownerId.active == false
        Opportunity opp2 = [select id, name, ownerId, account.owner.isactive, account.sales_team_calculated__c, account.territory__c 
                           from opportunity limit 1];
        
        //initialize current page controller with opp1
        RoundRobinOpportunityController ctr2 = new RoundRobinOpportunityController(new ApexPages.StandardController(opp2));

        ctr2.saveOpportunityAutomatic();
        
        PageReference retPageRef = ctr2.saveOpportunityAutomatic();
            
        if(retPageRef != null){
            //redirect should be set to true
            system.assertEquals(true, retPageRef.getRedirect());
            
            //current apex page id parameter should be equivalent to return page id parameter
            system.assertEquals(ApexPages.currentPage().getParameters().get('id'), (Id)retPageRef.getParameters().get('id')); //Connverting 15-char to 18-char ID
            
            String retURL = retPageRef.getUrl();
            
            //return url should be url of a vf roundrobinopportunityfinal
            system.assertEquals(Page.RoundRobinOpportunityFinal.getUrl(), retURL.substringBefore('?'));
          
        }
        
        //change page context to a return page
        //Test.setCurrentPageReference(retPageRef);
        // the following line added to make saveOpportunityFinal work (it expects an assignAccountOwnerToOpportunityOwner value)
        ApexPages.currentPage().getParameters().put('assignAccountOwnerToOpportunityOwner', String.valueOf(True)); 
        ctr2.saveOpportunityFinal();

    }
    
    @isTest static void roundRobinTestTwo(){
        
        //set current page context 
        Test.setCurrentPageReference(Page.RoundRobinOpportunity);
        
        //get anny active user
        User anyUser = [select Id from User where isActive = true limit 1];
        
        //update owner
        Account acct = [select ownerId from account limit 1];
        acct.ownerId = anyUser.id;
        update acct;
        
       //get opportuninty -- case 1 opp.account.trritory is empty and opp.owner != opp.account.owner
        Opportunity opp = [select id, name, ownerId, account.owner.isactive, account.sales_team_calculated__c, account.territory__c 
                           from opportunity limit 1];
        
        //set current page id parameter        
        ApexPages.currentPage().getParameters().put('id',String.valueOf(opp.Id));
        
        //initialize current page controller with opp
        RoundRobinOpportunityController ctr = new RoundRobinOpportunityController(new ApexPages.StandardController(opp));

        ctr.saveOpportunityManual();
        
    }        
    
}