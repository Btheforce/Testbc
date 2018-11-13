@isTest
public class ContactBatchUpdate_MktoSgmtTest {
    static testmethod void test(){
        //Consolidated all individual DMLs & SOQLs to prevent a deployment error on 02/28/17 - Bala Rajagopal
        String strToday = DateTime.now().format('yyyy-MM-dd');
        // Create dummy data: 1 RV Account, 1 RV Member, 4 Accounts, 7 Contacts, 3 Optys.
        // The numbering should produce Contacts with the following "MARKETO: Segment" field values:
        // 1: Partner
        // 2: Partner-Registered Lead
        // 3: Former Customer
        // 4: Current Customer
        // 5: Current Trialer
        // 6: Former Trialer
        // 7: Prospect (Never Trialed)
		// 8: New Customer
        /**
         * Moved the creation of RV Account and RV Member to the TestDataFactory
         * @author Steve O'Neal
         * @date   2018-04-30
         * @ticket link          https://jira.bigcommerce.com/browse/BAP-7204
         */
        List<rvpe__RVAccount__c> rvAccounts = TestDataFactory.CreateTestRVAccounts(1);
        List<rvpe__RVMember__c> rvMembers = TestDataFactory.CreateTestRVMembers(1, rvAccounts);

        rvpe__RVAccount__c rvacct2 = rvAccounts[0];
        rvpe__RVMember__c rvmem2 = rvMembers[0];

        rvacct2.rvpe__RVPrimaryMember__c = rvmem2.Id;
        update rvacct2;

        rvmem2.rvpe__DateAgreedToTerms__c = Date.today();
        update rvmem2;
        
        List<Account> insertAccountList = new List<Account>();
        Account acct1 = new Account(Name = 'Bigcommerce Partner');
        insertAccountList.add(acct1);
        // ACCOUNT FOR CONTACT "PARTNER CONTACT"
        Account acct2 = new Account(Name = 'Test Partner Account');
        insertAccountList.add(acct2);
        // ACCOUNT FOR CONTACT "PARTNER-REGISTERED LEAD"
        Account acct3 = new Account(Name = 'Former Client', Type = 'Former Client');
        insertAccountList.add(acct3);
        // ACCOUNT FOR CONTACT "FORMER CUSTOMER"
        Account acct4 = new Account(Name = 'Test Account');
        insertAccountList.add(acct4);
        // ACCOUNT FOR CONTACT "FORMER CUSTOMER"
        Account acct8 = new Account(Name = 'New Customer Account');
        insertAccountList.add(acct8);
        // ACCOUNT FOR CONTACTS "CUSTOMER", "CURRENT TRIALER", "FORMER TRIALER", "PROSPECT (NEVER TRIALED)"
        insert insertAccountList;
        Contact con1 = new Contact(AccountId = acct1.Id, Email = 'acumen+test1@gmail.com', LastName = 'Test1'); // PARTNER
        Contact con2 = new Contact(AccountId = acct2.Id, Email = 'acumen+test2@gmail.com', LastName = 'Test2', 
                                   RV_Account__c = rvacct2.Id, RV_Member__c = rvmem2.Id); // PARTNER-REGISTERED LEAD
        Contact con3 = new Contact(AccountId = acct3.Id, Email = 'acumen+test3@gmail.com', LastName = 'Test3'); // FORMER CUSTOMER
        Contact con4 = new Contact(AccountId = acct4.Id, Email = 'acumen+test4@gmail.com', LastName = 'Test4'); // CUSTOMER
        Contact con5 = new Contact(AccountId = acct4.Id, Email = 'acumen+test5@gmail.com', LastName = 'Test5'); // CURRENT TRIALER
        Contact con6 = new Contact(AccountId = acct4.Id, Email = 'acumen+test6@gmail.com', LastName = 'Test6'); // FORMER TRIALER
        Contact con7 = new Contact(AccountId = acct4.Id, Email = 'acumen+test7@gmail.com', LastName = 'Test7'); // PROSPECT (NEVER TRIALED)
        Contact con8 = new Contact(AccountId = acct8.Id, Email = 'acumen+test8@gmail.com', LastName = 'Test8'); // NEW CUSTOMER
        List<Contact> lstCons = new List<Contact> {con1, con2, con3, con4, con5, con6, con7, con8};
        insert lstCons;
		
        List<Opportunity> insertOpptyList = new List<Opportunity>();
        Opportunity opty4 = new Opportunity(AccountId = acct4.Id, CloseDate = Date.valueOf('2017-01-01 00:00:00'), Contact__c = con4.Id,
                                            Name = 'Active Store Opty', RecordTypeId = Label.Opportunity_RecordTypeId_StorePurchase, 
                                            Status__c = Label.Opportunity_Status_Active,
                                            StageName = Label.Opportunity_Stage_Purchased,
                                            StartDate__c = System.today());
        insertOpptyList.add(opty4);

        Opportunity opty5 = new Opportunity(AccountId = acct4.Id, CloseDate = System.today(), Contact__c = con5.Id,
                                            ExpirationDate__c = System.today(), MBASubscriptionID__c = 'whatever',
                                            Name = 'Unexpired Active Trial Opty', RecordTypeId = Label.Opportunity_RecordTypeId_Trial, 
                                            Status__c = Label.Opportunity_Status_Active, StageName = Label.Opportunity_Stage_Pending,
                                            StartDate__c = System.today());
        insertOpptyList.add(opty5);
        Opportunity opty6 = new Opportunity(AccountId = acct4.Id, CloseDate = System.today(), Contact__c = con6.Id,
                                            Name = 'Inactive Trial Opty', RecordTypeId = Label.Opportunity_RecordTypeId_Trial, 
                                            Status__c = Label.Opportunity_Status_Expired,
                                            StageName = Label.Opportunity_Stage_Pending,
                                            StartDate__c = System.today());
        insertOpptyList.add(opty6);
        Opportunity opty8 = new Opportunity(AccountId = acct8.Id, CloseDate = System.today(), Contact__c = con8.Id,
                                            Name = 'New Opty', RecordTypeId = Label.Opportunity_RecordTypeId_StorePurchase, 
                                            Status__c = Label.Opportunity_Status_Active,
                                            StageName = Label.Opportunity_Stage_Purchased,
                                            StartDate__c = System.today());
        insertOpptyList.add(opty8);
        insert insertOpptyList;

        // Run Batch Update
        Test.startTest();
        ContactBatchUpdate_MktoSgmt cbums = new ContactBatchUpdate_MktoSgmt();
        Database.executeBatch(cbums);
        System.debug('*** control returns to test class');
        
        // Test that the Contacts got updated
        Test.stopTest();
        
        List<Contact> conList = new List<Contact>([SELECT Id, LastName, MARKETO_Segment__c, RV_Has_RV_Account__c, RV_Date_Agreed_to_Terms__c,Account.Type FROM Contact WHERE Id IN :lstCons]);
        Map<String,Contact> mapLastNametoContact = new Map<String,Contact>();
        for(Contact con:conList){
            mapLastNametoContact.put(con.LastName, con);
        }
        

        System.assertEquals(mapLastNametoContact.get('Test1').MARKETO_Segment__c, 'Partner');
        System.assertEquals(mapLastNametoContact.get('Test2').MARKETO_Segment__c, 'Partner-Registered Lead');
        System.assertEquals(mapLastNametoContact.get('Test3').MARKETO_Segment__c, 'Former Customer');
        System.assertEquals(mapLastNametoContact.get('Test4').MARKETO_Segment__c, 'Current Customer');
        System.assertEquals(mapLastNametoContact.get('Test5').MARKETO_Segment__c, 'Current Trialer');
        System.assertEquals(mapLastNametoContact.get('Test6').MARKETO_Segment__c, 'Former Trialer');
        System.assertEquals(mapLastNametoContact.get('Test7').MARKETO_Segment__c, 'Prospect (Never Trialed)');
        System.assertEquals(mapLastNametoContact.get('Test8').MARKETO_Segment__c, 'New Customer');
    }   
}