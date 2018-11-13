/**
 * An apex page controller that supports self registration of users in communities that allow self registration
 */
@IsTest(SeeAllData=true) public with sharing class CommunitiesSelfRegControllerOrig_Test {
    //@IsTest(SeeAllData=true) 
    static testmethod void testCommunitiesSelfRegControllerOrig() {

       CommunitiesSelfRegControllerOrig controller = new CommunitiesSelfRegControllerOrig();

        controller.formurl = 'http://testingStore1bigcommerce.com'; 
        controller.supportpin = '12345';
 
        TestDataGenerator td = new TestDataGenerator();
        
        list<Account> lstAcct = td.getAccounts(true);
        lstAcct[0].SupportPin__c = '12345';
        update lstAcct; 
         
         Contact c = new Contact();
                        c.FirstName = 'First ' ;
                        c.LastName = 'Last ' ;
                        c.MailingCountry ='US';
                        c.Email = 'testmail@bigcommerce.com';
                        c.AccountId = lstAcct[0].Id;
                        c.Primary_MBA_Contact__c = true;
         insert c;
        
        Subscription__c sub = new Subscription__c( 

            RecordTypeId = Subscription__c.getSObjectType().getDescribe().getRecordTypeInfosByName().get('MBA Subscription').getRecordTypeId(),
            ProductType__c = 'Store',
            StoreURL__c = 'testingStore1bigcommerce.com',         
            Purchase_Team__c = 'Sales Operations',
            Source__c = 'Direct Trial',
            Upgrade_Stage__c = 'New',
            Account__c = lstAcct[0].Id,
            Sales_Stage__c = 'New',          
            Status__c = 'Active',
            IsTrial__c = true,
            Was_Trial__c = true,
            
            Product__c = 'Silver Plan');
          
         insert sub;
        
        Account testAccount = lstAcct[0];
        Subscription__C testSub = [SELECT Id, Account__c, Contact__c,StoreURL__c,Support_PIN__c FROM Subscription__c WHERE Id =: Sub.Id];
        
        System.assertEquals(testAccount.Id, testSub.Account__c);
        System.assertEquals(testAccount.SupportPin__c, testSub.Support_Pin__c);
        
        controller.formurl = 'http://www.testingStore1bigcommerce.com'; 
        controller.supportpin = '12345';
       
        controller.authenticateUser();
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd1234';
        controller.registerUser();
        
        PageReference pageRef = new pageReference('/apex/CommunitiesSelfRegOrig');
		Test.setCurrentPage(pageRef); 
        test.startTest();
         //controller.isPartnerUser();
        test.stopTest();

    }    
    
     static testmethod void testCommunitiesPartnerSelfRegControllerOrig() {
		
       CommunitiesSelfRegControllerOrig controller = new CommunitiesSelfRegControllerOrig();
  
        TestDataGenerator td = new TestDataGenerator();
        
        list<Account> lstAcct = td.getAccounts(true);
        lstAcct[0].SupportPin__c = '12345';
        update lstAcct; 
     
         Contact c = new Contact();
         c.FirstName = 'First ' ;
         c.LastName = 'Last ' ;
         c.MailingCountry ='US';
         c.Email = 'testmail@bigcommerce.com';
         c.AccountId = lstAcct[0].Id;
         c.Primary_MBA_Contact__c = true;
         c.RVMemberID__c = 11213141;
         insert c;
         
        rvpe__RVAccount__c testRVAccount = TestDataFactory.createTestRVAccounts(1)[0];
        rvpe__RVMember__c testRVMember = new rvpe__RVMember__c();
        testRVMember.rvpe__RVAccount__c = testRVAccount.id;
        testRVMember.rvpe__Email__c = 'testmail@bigcommerce.com';
        testRVMember.rvpe__ExtMemberId__c = 11213141;
        testRVMember.rvpe__FirstName__c = 'First ';
        testRVMember.rvpe__LastName__c = 'Last ';
        testRVMember.rvpe__UserName__c ='testmail@bigcommerce.com';    
         insert testRVMember;
         
         c.RV_Member__c = testRVMember.id;
         c.RV_Account__c = testRVAccount.id;
         update c;

         user guest =  [select id, name, firstname, lastname, email, username, profileid from user where name = 'BigCommerce Community Site Guest User' limit 1];    
        
        PageReference pageRef = new pageReference('/apex/CommunitiesSelfRegOrig?pid=11213141');
		Test.setCurrentPage(pageRef); 
        test.startTest();
         system.runAs(guest)
        {
         controller.isPartnerUser();
        }
        
        test.stopTest();
        rvpe__RVMember__c rvm = [select id,rvpe__UserName__c from rvpe__RVMember__c where rvpe__ExtMemberId__c = 11213141 limit 1];
         system.debug('>><<11213141 = '+rvm);
        system.assertEquals(rvm.rvpe__UserName__c, controller.email);
        
    }    

     static testmethod void testCommunitiesNewPartnerSelfRegControllerOrig() {
		
       CommunitiesSelfRegControllerOrig controller = new CommunitiesSelfRegControllerOrig();
  
        TestDataGenerator td = new TestDataGenerator();
        
        list<Account> lstAcct = td.getAccounts(true);
        lstAcct[0].SupportPin__c = '12345';
        update lstAcct; 
     
         Contact c = new Contact();
         c.FirstName = 'First ' ;
         c.LastName = 'Last ' ;
         c.MailingCountry ='US';
         c.Email = 'testmail@bigcommerce.com';
         c.AccountId = lstAcct[0].Id;
         c.Primary_MBA_Contact__c = true;
         c.RVMemberID__c = 12223242;
         insert c;
         
        rvpe__RVAccount__c testRVAccount = TestDataFactory.createTestRVAccounts(1)[0];
        rvpe__RVMember__c testRVMember = new rvpe__RVMember__c();
        testRVMember.rvpe__RVAccount__c = testRVAccount.id;
        testRVMember.rvpe__Email__c = 'testmail@bigcommerce.com';
        testRVMember.rvpe__ExtMemberId__c = 12223242;
        testRVMember.rvpe__FirstName__c = 'First ';
        testRVMember.rvpe__LastName__c = 'Last ';
        testRVMember.rvpe__UserName__c ='testmail@bigcommerce.com';    
         insert testRVMember;
         
         c.RV_Member__c = testRVMember.id;
         c.RV_Account__c = testRVAccount.id;
         update c;
         
         Id communityProfileId = [select id from profile where name = 'Community Client User' limit 1][0].id;
             
        User u = new User();
        u.Username = 'testmail@bigcommerce.com';
        u.Email =  c.email;
        u.FirstName = c.firstName;
        u.LastName = c.lastName;
        u.ContactId = c.Id;
        u.Alias = 'test123';
        u.UserPermissionsChatterAnswersUser = false;
        u.CommunityNickname = 'bcs'+u.lastName.substring(1,1) +123;
        u.ProfileId = communityProfileId;
        u.emailencodingkey = 'UTF-8'; 
        u.languagelocalekey = 'en_US'; 
        u.localesidkey = 'en_US';
        u.timezonesidkey = 'America/Los_Angeles';
        u.IsActive = true;
        insert u;

         user guest =  [select id, name, firstname, lastname, email, username, profileid from user where name = 'BigCommerce Community Site Guest User' limit 1];    
        
        PageReference pageRef = new pageReference('/apex/CommunitiesSelfRegOrig?pid=12223242');
		Test.setCurrentPage(pageRef); 
        test.startTest();
         system.runAs(guest)
        {
         controller.isPartnerUser();
        }
        
        test.stopTest();
        rvpe__RVMember__c rvm = [select id,rvpe__UserName__c from rvpe__RVMember__c where rvpe__ExtMemberId__c = 12223242 limit 1];
         system.debug('>><<12223242 = '+rvm);
        system.assertEquals(rvm.rvpe__UserName__c, controller.email);
        
    }    
    
     static testmethod void testCommunitiesNoPartnerSelfRegControllerOrig() {
		
       CommunitiesSelfRegControllerOrig controller = new CommunitiesSelfRegControllerOrig();


         user guest =  [select id, name, firstname, lastname, email, username, profileid from user where name = 'BigCommerce Community Site Guest User' limit 1];    
        
        PageReference pageRef = new pageReference('/apex/CommunitiesSelfRegOrig?pid=101010');
		Test.setCurrentPage(pageRef); 
        test.startTest();
         system.runAs(guest)
        {
         controller.isPartnerUser();
        }
        
        test.stopTest();
        system.assert(controller.PartnerError);
        
    }    
         static testmethod void testCommunitiesEmptyPartnerSelfRegControllerOrig() {
		
       CommunitiesSelfRegControllerOrig controller = new CommunitiesSelfRegControllerOrig();


         user guest =  [select id, name, firstname, lastname, email, username, profileid from user where name = 'BigCommerce Community Site Guest User' limit 1];    
        
        PageReference pageRef = new pageReference('/apex/CommunitiesSelfRegOrig?pid=');
		Test.setCurrentPage(pageRef); 
        test.startTest();
         system.runAs(guest)
        {
         controller.isPartnerUser();
        }
        
        test.stopTest();
        system.assert(controller.PartnerError);
        
    }    
}