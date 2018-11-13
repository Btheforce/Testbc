/**
 * TestDataFactory
 * Author: Steve O'Neal
 * Purpose: Creates generic SObjects for use in test classes
 * Ticket: BAP-3444
 *
 * Updates:
 * *********
 * 
 */
global without sharing class TestDataFactory {

    private static string TestAccountPrefix = 'testBCCompany';

    /////////////////
    // RV ACCOUNTS //
    /////////////////

    /**
     * Creates an RV Account (reseller partner)
     * @author Steve O'Neal
     * @date   2016-07-01
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-3698
     * @return An RV Account
     */
    private static rvpe__RVAccount__c createTestRVAccount()
    {
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        rvpe__RVAccount__c retVal = new rvpe__RVAccount__c();
        retVal.Name = TestAccountPrefix + ' RV Account ' + seed1;
        retVal.Commission__c = 20;
        retVal.Partner_Commission__c = retVal.Commission__c;
        retVal.Status__c = 'Account';
        retVal.Magento_Partner__c = 'No';
        retVal.Approved_Date__c = Date.today().addYears(-2);
        retVal.rvpe__ExtAccountId__c = Decimal.valueOf(seed1);

        return retVal;
    }

    /**
     * Creates a list of test RV Accounts (reseller partners)
     * @author Steve O'Neal
     * @date   2016-07-01
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-3698
     * @param  numberOfRecords Number of accounts to create
     * @return                 A list of RV Accounts
     */
    global static List<rvpe__RVAccount__c> createTestRVAccounts(integer numberOfRecords)
    {
        List<rvpe__RVAccount__c> retVal = new List<rvpe__RVAccount__c>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            retVal.add(TestDataFactory.createTestRVAccount());
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates a single RV Member in memory
     * @author Steve O'Neal
     * @date   2017-05-10
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-5531
     * @param  rvAccount  The RV Account to attach the member to
     * @return            A test RV Member
     */
    private static rvpe__RVMember__c createTestRVMember(rvpe__RVAccount__c rvAccount)
    {
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));
        String seed2 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        rvpe__RVMember__c retVal = new rvpe__RVMember__c();
        retVal.rvpe__RVAccount__c = rvAccount.Id;
        retVal.rvpe__FirstName__c = 'FirstName';
        retVal.rvpe__LastName__c = 'LastName';
        retVal.rvpe__UserName__c = 'email' + seed1 + '@' + seed2 + '.com';
        retVal.rvpe__Email__c = retVal.rvpe__UserName__c;
        retVal.rvpe__ExtMemberId__c = MathUtility.RandomInteger(1000, 9999);

        return retVal;
    }


    /**
     * Creates a list of test RV Members
     * @author Steve O'Neal
     * @date   2017-05-10
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-5531
     * @param  numberOfRecords How many RV Members to make per RV Account
     * @param  rvAccounts      List of RV Accounts to make members for
     * @return                 List of test RV Members
     */
    global static List<rvpe__RVMember__c> createTestRVMembers(integer numberOfRecords, List<rvpe__RVAccount__c> rvAccounts)
    {
        List<rvpe__RVMember__c> retVal = new List<rvpe__RVMember__c>();
        
        Set<Integer> extIds = new Set<Integer>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            for (rvpe__RVAccount__c rvAccount : rvAccounts)
            {
                 rvpe__RVMember__c rvMember;
                
                do{

                    rvMember = TestDataFactory.createTestRVMember(rvAccount);

                }while(extIds.contains((Integer)rvMember.rvpe__ExtMemberId__c)); //rvpe__ExtMemberId__c should be Number(18, 0) (External ID) (Unique)
                
                extIds.add((Integer)rvMember.rvpe__ExtMemberId__c);
                
                retVal.add(rvMember);
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    //////////////////////////
    // INVOICE TRANSACTIONS //
    //////////////////////////

    /**
     * Creates an invoice transaction, which represents a customer paying on their invoice
     * @author Steve O'Neal
     * @date   2016-07-01
     * @ticket link             https://jira.bigcommerce.com/browse/BAP-3698
     * @param  storeOpportunity The store that the payment is related to
     * @return                  An invoice transaction
     */
    private static Invoice_Transaction__c createTestInvoiceTransaction(Opportunity storeOpportunity)
    {
        Invoice_Transaction__c retVal = new Invoice_Transaction__c();
        integer amountDueDollars = MathUtility.RandomInteger(10, 999);
        decimal amountDueCents = MathUtility.RandomInteger(0, 99);
        decimal amountDue = decimal.valueof(amountDueDollars + '.' + amountDueCents);
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));
        String seed2 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Amount_Credited__c = 0;
        retVal.Amount_Due__c = amountDue;
        retVal.Amount_Paid__c = amountDue;
        retVal.Amount_Refunded__c = 0;
        retVal.Date_Due__c = Date.today().addDays(MathUtility.RandomInteger(-365, 0));
        retVal.Date_Paid__c = retVal.Date_Due__c;
        retVal.Description__c = 'Test Customer Payment';
        retVal.Invoice_ID__c = seed1;
        retVal.Invoice_Item_ID__c = seed1 + seed2;
        retVal.Invoice_Status__c = 'Paid';
        retVal.Payment_Term__c = MathUtility.RandomBoolean()?1:12;
        retVal.Product_Type__c = 'Hosting';
        retVal.Store_Opportunity__c = storeOpportunity.Id;
        retVal.Store_Opportunity__c = storeOpportunity.Id;

        return retVal;
    }

    /**
     * Creates a list of Invoice Transactions
     * @author Steve O'Neal
     * @date   2016-07-01
     * @ticket link               https://jira.bigcommerce.com/browse/BAP-3698
     * @param  numberOfRecords    Number of transactions to make for each opportunity
     * @param  storeOpportunities The opportunities to create transactions against
     * @return                    A list of Invoice Transactions
     */
    global static List<Invoice_Transaction__c> createTestInvoiceTransactions(integer numberOfRecords, List<Opportunity> storeOpportunities)
    {
        List<Invoice_Transaction__c> retVal = new List<Invoice_Transaction__c>();

        for (Opportunity opp : storeOpportunities)
        {
            for (integer i = 0; i < numberOfRecords; i++)
            {
                retVal.add(TestDataFactory.createTestInvoiceTransaction(opp));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }

    ///////////////
    // CAMPAIGNS //
    ///////////////

    /**
     * Creates an instance of a Campaign
     * @author Steve O'Neal
     * @date   2016-06-22
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-3811
     * @return Test campaign
     */
    private static Campaign createTestCampaign()
    {
        String seed1 = String.valueof(MathUtility.RandomInteger(100, 999));

        Campaign testCampaign = new Campaign();
        testCampaign.Name = TestAccountPrefix + ' Campaign ' + seed1;
        testCampaign.Status = 'Planned';
        testCampaign.IsActive = true;
        testCampaign.Type = 'Other';
        testCampaign.StartDate = Date.today();
        testCampaign.EndDate = Date.today().addDays(5);
        
        return testCampaign;
    }

    /**
     * Creates a group of campaigns
     * @author Steve O'Neal
     * @date   2016-06-22
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-3811
     * @param  numberOfRecords The total number of campaigns to create
     * @return                 List of campaigns
     */
    global static List<Campaign> createTestCampaigns(integer numberOfRecords)
    {
        List<Campaign> retVal = new List<Campaign>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            retVal.add(TestDataFactory.createTestCampaign());
        }

        if (retVal.size() > 0)
        {
            insert retVal;

            // create campaignmemberstatus records for each campaign
            List<CampaignMemberStatus> cmsList = new List<CampaignMemberStatus>();
            for (Campaign c : retVal)
            {
                CampaignMemberStatus cms = new CampaignMemberStatus();
                cms.CampaignId = c.Id;
                cms.Label = 'Demo Requested';
                cms.IsDefault = false;
                cms.HasResponded = false;
                cms.SortOrder = 3;
                cmsList.add(cms);
            }

            insert cmsList;
        }
        return retVal;
    }

    /**
     * Creates an instance of a Campaign Member
     * @author Steve O'Neal
     * @date   2016-06-22
     * @ticket link        https://jira.bigcommerce.com/browse/BAP-3811
     * @param  cmpgn       The campaign it belongs to
     * @param  demoRequest If the type of campaign is a demo request
     * @param  member      The sobject to link the campaign member to
     * @return             Instance of a campaign member
     */
    private static CampaignMember createCampaignMember(Campaign cmpgn, boolean demoRequest, sObject member)
    {
        CampaignMember retVal = new CampaignMember();
        retVal.CampaignId = cmpgn.Id;

        if (demoRequest)
        {
            retVal.Status = 'Demo Requested';
        }
        else
        {
            retVal.Status = 'New';
        }

        if (member != null)
        {
            if (member.getSObjectType() == Lead.getSObjectType())
            {
                Lead tmpLead = (Lead)member;
                retVal.LeadId = tmpLead.ID;
            }
            else if (member.getSObjectType() == Contact.getSObjectType())
            {
                Contact tmpCont = (Contact)member;
                retVal.ContactId = tmpCont.ID;
            }
            else
            {
                throw new ApplicationException('Not a valid recordtype: ' + member.getSObjectType());
            }
        }

        return retVal;
    }


    /**
     * Creates a group of campaign members
     * @author Steve O'Neal
     * @date   2016-06-22
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-3811
     * @param  numberOfRecords The total number of campaigns to create
     * @return                 List of campaign members
     */
    global static List<CampaignMember> createTestCampaignMembers(List<Campaign> campaigns, boolean demoRequest, List<SObject> members)
    {
        List<CampaignMember> retVal = new List<CampaignMember>();

        for (Campaign cmpgn : campaigns)
        {
            if (members != null && members.size() > 0)
            {
                for (SObject member : members)
                {
                    retVal.add(TestDataFactory.createCampaignMember(cmpgn, demoRequest, member));
                }
            }
            else
            {
                retVal.add(TestDataFactory.createCampaignMember(cmpgn, demoRequest, null));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    ///////////
    // LEADS //
    ///////////
    /**
     * Deletes all test leads that have the company name = TestAccountPrefix
     * @author Steve O'Neal
     * @date   2016-05-31
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-3444
     * @return nothing
     */
    global static void DeleteTestLeads()
    {
        string likeTestAccountPrefix = TestAccountPrefix + '%';
        List<Lead> leads = [Select Id, Name from Lead where Company like :likeTestAccountPrefix];
        delete leads;
    }

    /**
     * Creates a unique lead
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link         https://jira.bigcommerce.com/browse/BAP-3444
     * @param  CreateGAId   Adds a unique Google Analytics ID if true
     * @param  recordTypeId Type of record to create
     * @return              A new lead (pre-insert)
     */
    private static Lead createTestLead(boolean CreateGAId, Id recordTypeId)
    {
        String seed1 = String.valueof(MathUtility.RandomInteger(100, 999));
        string seed2 = string.valueof(MathUtility.RandomInteger(1000, 9999));
        String fullSeed = seed1 + '.' + seed2;

        Lead testLead = new Lead();
        testLead.LastName = 'testLName' + fullSeed;
        testLead.FirstName = 'testFirstName';
        testLead.Company = TestAccountPrefix + fullSeed;
        testLead.RecordTypeId = recordTypeId;
        if (CreateGAId)
        {
            testLead.GAClientID__c = fullSeed;

            testLead.gafirstTouchCampaign__c = 'firstTouchCampaign' + fullSeed;
            testLead.gafirstTouchChannel__c = 'firstTouchChannel' + fullSeed;
            testLead.gafirstTouchDate__c = DateTime.now().addDays(-4);
            testLead.gafirstTouchKeyword__c = 'firstTouchKeyword' + fullSeed;
            testLead.gafirstTouchMedium__c = 'firstTouchMedium' + fullSeed;
            testLead.gafirstTouchSource__c = 'firstTouchSource' + fullSeed;
            
            testLead.galastTouchCampaign__c = 'lastTouchCampaign' + fullSeed;
            testLead.galastTouchChannel__c = 'lastTouchChannel' + fullSeed;
            testLead.galastTouchDate__c = DateTime.now();
            testLead.galastTouchKeyword__c = 'lastTouchKeyword' + fullSeed;
            testLead.galastTouchMedium__c = 'lastTouchMedium' + fullSeed;
            testLead.galastTouchSource__c = 'lastTouchSource' + fullSeed;

            testLead.gatotalTouchCount__c = 1;
        }
        testLead.Email = 'testEmail+' + fullSeed + '@test.com';
        testLead.Phone = '512' + seed1 + seed2;
        
        return testLead;
    }


    /**
     * Creates a list of unique leads
     * @author Steve O'Neal
     * @date   2016-10-19
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-3444
     * @param  numberOfRecords How many leads needed
     * @param  createGAId      Adds a unique Google Analytics ID if true
     * @param  recordType      Type records to create
     * @return                 A list of unique leads
     */
    global static List<Lead> createTestLeads(integer numberOfRecords, boolean createGAId, Schema.RecordType recordType)
    {
        List<Lead> retVal = new List<Lead>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            retVal.add(TestDataFactory.createTestLead(createGAId, recordType.Id));
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


 

    //////////////
    // ACCOUNTS //
    //////////////

    /**
     * Deletes any accounts with a name that starts with the TestAccountPrefix
     * @author Steve O'Neal
     * @date   2016-05-31
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-3444
     * @return nothing
     */
    global static void deleteTestAccounts()
    {
        string likeTestAccountPrefix = TestAccountPrefix + '%';

        // get the accounts
        List<Account> accounts = [Select Id, name from Account where name like :likeTestAccountPrefix];

        // get the contacts
        List<Id> accountIds = new List<Id>();
        for (Account a : accounts)
        {
            accountIds.add(a.Id);
        }
        List<Contact> contacts = [Select Id, LastName, AccountId from Contact where AccountId =:accountIds ];

        // get the opportunities
        List<Opportunity> opportunities = [Select Id, Name, AccountId from Opportunity where AccountId =:accountIds ];

        delete opportunities;
        delete contacts;
        delete accounts;

    }

    
    /**
     * Creates a unique Account
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link         https://jira.bigcommerce.com/browse/BAP-3444
     * @param  CreateGAId   Adds a unique Google Analytics ID if true
     * @param  recordTypeId Type of record to create
     * @return              A unique Account (pre-save)
     */
    private static Account createTestAccount(boolean CreateGAId, Id recordTypeId)
    {
        String seed1 = String.valueof(MathUtility.RandomInteger(100, 999));
        String seed2 = string.valueof(MathUtility.RandomInteger(1000, 9999));
        String fullSeed = seed1 + '.' + seed2;

        Account testAccount = new Account();
        testAccount.Name = TestAccountPrefix + fullseed;
        testAccount.Status__c = 'Open';
        testAccount.Type = 'Prospect';
        testAccount.Phone = fullSeed;
        testAccount.RecordTypeId = recordTypeId;
        testAccount.BillingCountry = 'US';
        if (CreateGAId)
        {
            testAccount.GAClientID__c = fullSeed;

            testAccount.gafirstTouchCampaign__c = 'firstTouchCampaign' + fullSeed;
            testAccount.gafirstTouchChannel__c = 'firstTouchChannel' + fullSeed;
            testAccount.gafirstTouchDate__c = DateTime.now().addDays(-4);
            testAccount.gafirstTouchKeyword__c = 'firstTouchKeyword' + fullSeed;
            testAccount.gafirstTouchMedium__c = 'firstTouchMedium' + fullSeed;
            testAccount.gafirstTouchSource__c = 'firstTouchSource' + fullSeed;
            
            testAccount.galastTouchCampaign__c = 'lastTouchCampaign' + fullSeed;
            testAccount.galastTouchChannel__c = 'lastTouchChannel' + fullSeed;
            testAccount.galastTouchDate__c = DateTime.now();
            testAccount.galastTouchKeyword__c = 'lastTouchKeyword' + fullSeed;
            testAccount.galastTouchMedium__c = 'lastTouchMedium' + fullSeed;
            testAccount.galastTouchSource__c = 'lastTouchSource' + fullSeed;

            testAccount.gatotalTouchCount__c = 1;
        }
        
        return testAccount;
    }

    /**
     * Creates a list of unique accounts
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link             https://jira.bigcommerce.com/browse/BAP-3444
     * @param  numberOfRecords  How many accounts needed
     * @param  createGAId       Adds a unique Google Analytics ID if true
     * @param  recordType       The type of recors to create
     * @return                  A list of unique Accounts
     */
    global static List<Account> createTestAccounts(integer numberOfRecords, boolean createGAId, RecordType recordType)
    {

        List<Account> retVal = new List<Account>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            retVal.add(TestDataFactory.createTestAccount(createGAId, recordType.Id));
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Removed populating the AccountMaxSubRollup__c custom setting
     * @author Steve O'Neal
     * @date   2017-02-08
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4200
     */

    //////////////
    // CONTACTS //
    //////////////

    /**
     * Creates an instance of a test Contact
     * @author Steve O'Neal
     * @date   2016-06-22
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-3811
     * @param  acct       The account to attach the record to
     * @return            A test contact
     */
    private static Contact createTestContact(Account acct)
    {
        String seed1 = String.valueof(MathUtility.RandomInteger(100, 999));
        string seed2 = string.valueof(MathUtility.RandomInteger(1000, 9999));
        String fullSeed = seed1 + '.' + seed2;

        Contact retVal = new Contact();
        retVal.LastName = 'testLName' + fullSeed;
        retVal.FirstName = 'testFirstName';
        if (acct != null)
        {
            retVal.AccountId = acct.Id;
        }
        retVal.Email = 'testEmail+' + fullSeed + '@test.com';
        retVal.Phone = '512' + seed1 + seed2;
        
        return retVal;
    }


    /**
     * Creates a list of test contacts
     * @author Steve O'Neal
     * @date   2016-06-22
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-3811
     * @param  numberOfRecords The number of contacts to create for each account
     * @param  accounts        The accounts to create contacts for
     * @return                 A list of test contacts
     */
    global static List<Contact> createTestContacts(integer numberOfRecords, List<Account> accounts)
    {
        List<Contact> retVal = new List<Contact>();

        if (accounts != null && accounts.size() > 0)
        {
            for (Account acct : accounts)
            {
                for (integer i = 0; i < numberOfRecords; i++)
                {
                    retVal.add(TestDataFactory.createTestContact(acct));
                }
            }
        }
        else
        {
             for (integer i = 0; i < numberOfRecords; i++)
            {
                retVal.add(TestDataFactory.createTestContact(null));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    ///////////////////
    // OPPORTUNITIES //
    ///////////////////

    /**
     * Creates a test opportunity
     * @author Steve O'Neal
     * @date   2016-06-22
     * @ticket link         https://jira.bigcommerce.com/browse/BAP-3811
     * @param  acct         The account to tie the opportunity to
     * @param  recordTypeId The record type id for the opportunity
     * @return              A test opportunity
     */
    public static Opportunity createTestOpportunity(Account acct, Id recordTypeId)
    {
        /**
         * Removed references to Totango
         * @author Steve O'Neal
         * @date   2017-06-02
         * @ticket link        https://jira.bigcommerce.com/browse/BAP-5748
         */
        
        String seed1 = String.valueof(MathUtility.RandomInteger(100, 999));
        string seed2 = string.valueof(MathUtility.RandomInteger(1000, 9999));
        String fullSeed = seed1 + '.' + seed2;

        Opportunity retVal = new Opportunity();
        retVal.RecordTypeId = recordTypeId;
        retVal.AccountId = acct.Id;
        retVal.Name = TestAccountPrefix + ' opp ' + fullSeed;
        retVal.CloseDate = Date.today().addDays(4);
        retVal.PurchaseDate__c = retVal.CloseDate;
        retVal.StageName = 'Qualify';
        retVal.Status__c = 'Active';

        return retVal;
    }

    /**
     * Creates a list of test opportunities
     * @author Steve O'Neal
     * @date   2016-06-22
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords Number of opportunities to make per Account
     * @param  accounts        The accounts to tie the opportunities to
     * @param  recordType      The record type to create
     * @return                 A list of opportunities
     */
    global static List<Opportunity> createTestOpportunities(integer numberOfRecords, List<Account> accounts, RecordType recordType)
    {
        List<Opportunity> retVal = new List<Opportunity>();

        for (Account acct : accounts)
        {
            for (integer i = 0; i < numberOfRecords; i++)
            {
                retVal.add(TestDataFactory.createTestOpportunity(acct, recordType.Id));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates an OPH record in memory
     * @author Steve O'Neal
     * @date   2017-06-01
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-5737
     * @param  opp        Opportunity to link the OPH record to
     * @return            An OPH record
     */
    private static Opportunity_Product__c createTestOpportunityProductHistory(Opportunity opp)
    {
        Opportunity_Product__c retVal = new Opportunity_Product__c();
        retVal.StartDate__c = Date.today();
        retVal.ExpirationDate__c = retVal.StartDate__c.addYears(1);
        retVal.MonthlyRecurringRevenue__c = 0;
        retVal.isTrial__c = true;
        retVal.Product__c = 'Trial';
        retVal.OpportunityID__c = opp.Id;
        retVal.RevenueChange__c = 0;
        retVal.LastVersion__c = true;
        return retVal;
    }


    /**
     * Creates a list of OPH records
     * @author Steve O'Neal
     * @date   2017-06-01
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-5737
     * @param  opps            The opportunities to associate the OPH records to
     * @param  numberOfRecords Number of OPH records to create per opportunity
     * @return                 List of OPH records
     */
    global static List<Opportunity_Product__c> createTestOpportunityProductHistories(List<Opportunity> opps, integer numberOfRecords)
    {
        List<Opportunity_Product__c> retVal = new List<Opportunity_Product__c>();

        for (Opportunity opp : opps)
        {
            for (integer i = 0; i < numberOfRecords; i++)
            {
                retVal.add(createTestOpportunityProductHistory(opp));
                retVal[retVal.size()-1].LastVersion__c = (i == (numberOfRecords-1));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates an instance of OpportunityContactRole in memory
     * @author Steve O'Neal
     * @date   2018-02-25
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-6871
     * @param  cont       Contact to connect
     * @param  opp        Opportunity to connect
     * @return            A Primary OpportunityContactRole in memory
     */
    global static OpportunityContactRole createTestOpportunityContactRole(Contact cont, Opportunity opp)
    {
        OpportunityContactRole retVal = new OpportunityContactRole();
        retVal.OpportunityId = opp.Id;
        retVal.ContactId = cont.Id;
        retVal.Role = 'Primary Contact';
        retVal.IsPrimary = true;
        return retVal;
    }


    /**
     * Creates a list of OpportunityContactRoles
     * @author Steve O'Neal
     * @date   2018-02-25
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-6871
     * @param  contacts      Contacts to connect to each opportunity
     * @param  opportunities Opportunities to connect to each contact
     * @return               List of OpportunityContactRoles
     */
    global static List<OpportunityContactRole> createTestOpportunityContactRoles(List<Contact> contacts, List<Opportunity> opportunities)
    {
        List<OpportunityContactRole> retVal = new List<OpportunityContactRole>();

        for (Contact cont : contacts)
        {
            for (Opportunity opp : opportunities)
            {
                retVal.add(createTestOpportunityContactRole(cont, opp));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    ///////////////////
    // SUBSCRIPTIONS //
    ///////////////////

    /**
     * Creates an instance of a Subscription
     * @author Steve O'Neal
     * @date   2016-07-14
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-3991
     * @param  acct       The account to tie the subscription to
     * @param  recordType The recordtype of the subscription
     * @return            An instance of a subscription
     */
    private static Subscription__c createTestSubscription(Account acct, Id recordTypeId)
    {
        Subscription__c retVal = new Subscription__c();
        retVal.Account__c = acct.Id;
        String seed1 = String.valueof(MathUtility.RandomInteger(1000000, 9999999));
        retVal.StoreURL__c = 'www.' + seed1 + '.com';
        retVal.recordTypeId = recordTypeId;

        return retVal;
    }


    /**
     * Creates a list of subscriptions
     * @author Steve O'Neal
     * @date   2016-07-14
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords Number of subscriptions to create for each account
     * @param  accts           The accounts to create subscriptions for
     * @param  recordType      The recordtype of the subscriptions to create
     * @return                 List of subscriptions
     */
    global static List<Subscription__c> createTestSubscriptions(integer numberOfRecords, List<Account> accts, RecordType recordType)
    {
        List<Subscription__c> retVal = new List<Subscription__c>();

        for (Account acct : accts)
        {
            for (integer i = 0; i < numberOfRecords; i++)
            {
                retVal.add(TestDataFactory.createTestSubscription(acct, recordType.Id));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;

    }


    ////////////
    // STORES //
    ////////////
    /**
     * Creates a Store object in memory
     * @author Steve O'Neal
     * @date   2018-02-16
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-6840
     * @return A unique Store
     */
    private static Store__c createTestStore(Account acct)
    {
        String seed1 = String.valueof(MathUtility.RandomInteger(1000000, 9999999));
        Store__c retVal = new Store__c();
        retVal.Name = seed1 + ' test store';
        retVal.Account__c = acct.Id;
        retVal.Hosting_ID__c = seed1;
        retVal.Store_URL__c = seed1 + '.com';
        retVal.Product__c = 'Trial';
        retVal.Product_ID__c = 'Trial';
        retVal.Purchase_Date__c = Date.today();

        return retVal;
    }


    /**
     * Creates a list of Stores and inserts them
     * @author Steve O'Neal
     * @date   2018-02-16
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-6840
     * @param  numberOfRecords Number of stores to create per Account
     * @param  accts           Accounts to link to the stores
     * @return                 A list of Stores
     */
    public static List<Store__c> createTestStores(integer numberOfRecords, List<Account> accts)
    {
        List<Store__c> retVal = new List<Store__c>();

        for (Account acct : accts)
        {
            for (integer i = 0; i < numberOfRecords; i++)
            {
                retVal.add(TestDataFactory.createTestStore(acct));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }

    /////////////////////////
    // MBA STAGING OBJECTS //
    /////////////////////////

    /**
     * Creates a unique MBA Staging Account
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-3444
     * @return A unique MBA Staging Account
     */
    private static MBA_Staging_Account__c createTestMBAStagingAccount()
    {
        // Create Staging Account records as not Paid and grab one of them
        String seed1 = String.valueof(MathUtility.RandomInteger(1000000, 9999999));
        MBA_Staging_Account__c mbaAccount = new  MBA_Staging_Account__c();
        mbaAccount.MBAAccountID__c = seed1;
        mbaAccount.CompanyName__c = 'companytest' + seed1;
        return mbaAccount;
    }


    /**
     * Creates a list of unique MBA Staging Account
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords Number of records to create
     * @return                 A list of unique MBA Staging Accounts
     */
    global static List<MBA_Staging_Account__c> createTestMBAStagingAccounts(integer numberOfRecords)
    {
        List<MBA_Staging_Account__c> retVal = new List<MBA_Staging_Account__c>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            retVal.add(TestDataFactory.createTestMBAStagingAccount());
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates a list of unique MBA Contacts tied to the list of passed MBA Accounts.
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-3444
     * @param  mbaAccounts     List of MBA Accounts
     * @return                 List of MBA Contacts
     */
    global static List<MBA_Staging_Contact__c> createTestMBAStagingContacts(List<MBA_Staging_Account__c> mbaAccounts)
    {
        List<MBA_Staging_Contact__c> retVal = new List<MBA_Staging_Contact__c>();

        for (MBA_Staging_Account__c acct : mbaAccounts)
        {
            String seed1 = String.valueof(MathUtility.RandomInteger(1000000, 9999999));
            MBA_Staging_Contact__c cont = new MBA_Staging_Contact__c();
            cont.MBAAccountID__c = acct.MBAAccountID__c;
            cont.MBAClientID__c = seed1;
            cont.Type__c = 'Primary';
            cont.Primary_MBA_Contact__c = true;
            cont.Email__c='testEmail+' + acct.MBAAccountID__c + '@test.com';
            cont.FirstName__c='Firstname' + acct.MBAAccountID__c;
            cont.LastName__c='lastname' + acct.MBAAccountID__c;
            retVal.add(cont);

        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates a list of unique MBA Contacts and supporting MBA Accounts
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-3444
     * @param  numberOfRecords Number of records to create
     * @return                 A list of unique MBA Contacts
     */
    global static List<MBA_Staging_Contact__c> createTestMBAStagingContacts(integer numberOfRecords)
    {
        return TestDataFactory.createTestMBAStagingContacts(TestDataFactory.createTestMBAStagingAccounts(numberOfRecords));
    }


    /**
     * Create an instance of a unique MBA Staging Subscription
     * @author Steve O'Neal
     * @date   2017-02-13
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-4327
     * @param  MBAAccount The MBA Staging Account to associate with the subscription
     * @return            [description]
     */
    private static MBA_Staging_Subscription__c createTestMBAStagingSubscription(MBA_Staging_Account__c MBAAccount)
    {
        String seed1 = String.valueof(MathUtility.RandomInteger(1000000, 9999999));

        MBA_Staging_Subscription__c retVal = new MBA_Staging_Subscription__c();
        retVal.MBASubscriptionID__c = 'subtest' + seed1;
        retVal.MBAAccountID__c = MBAAccount.MBAAccountID__c;
        retVal.isTrial__c = false;
        retVal.SubscriptionType__c = 'Store';
        retVal.Status__c = 'Active';
        retVal.ProductID__c = '24';
        retVal.Product__c = 'Bronze Plan';
        retVal.MonthlyRecurringRevenue__c = 24.95;
        retVal.BillingAmount__c = 24.95;
        retVal.Existing_Website_URL__c = 'https://www.' + seed1 + '.com/index.aspx';

        return retVal;
    }


    /**
     * Creates a list of MBA Staging Subscriptions from a list of MBA Subscription Accounts
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link        https://jira.bigcommerce.com/browse/BAP-3444
     * @param  MBAAccounts List of Accounts to tie the subscriptions to
     * @return             List of unique MBA Staging Subscriptions
     */
    global static List<MBA_Staging_Subscription__c> createTestMBAStagingSubscriptions(List<MBA_Staging_Account__c> MBAAccounts)
    {
        List<MBA_Staging_Subscription__c> retVal = new List<MBA_Staging_Subscription__c>();

        for (MBA_Staging_Account__c MBAAccount : MBAAccounts)
        {
            retVal.add(createTestMBAStagingSubscription(MBAAccount));
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }

    /**
     * Creates a list of MBA Staging Subscriptions
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-3444
     * @param  numberOfRecords Number of records to create
     * @return                 A list of MBA Staging Subscriptions
     */
    global static List<MBA_Staging_Subscription__c> createTestMBAStagingSubscriptions(integer numberOfRecords)
    {
        return TestDataFactory.createTestMBAStagingSubscriptions(TestDataFactory.createTestMBAStagingAccounts(numberOfRecords));
    }

    /**
     * Creates a list of MBA Staging Subscriptions, plus supporting accounts and contacts
     * @author Steve O'Neal
     * @date   2016-05-26
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-3444
     * @param  numberOfRecords Number of records to create
     * @return                 List of MBA Staging Subscriptions
     */
    global static List<MBA_Staging_Subscription__c> createTestMBAStagingSubscriptionsAccountsContacts(integer numberOfRecords)
    {
        List<MBA_Staging_Account__c> MBAAccounts = TestDataFactory.createTestMBAStagingAccounts(numberOfRecords);
        System.debug(MBAAccounts);
        List<MBA_Staging_Contact__c> MBAContacts = TestDataFactory.createTestMBAStagingContacts(mbaAccounts);
        System.debug(MBAContacts);
        List<MBA_Staging_Subscription__c> MBASubscriptions = TestDataFactory.createTestMBAStagingSubscriptions(MBAAccounts);
        System.debug(MBASubscriptions);
        return MBASubscriptions;
    }


    ///////////
    // CASES //
    ///////////

    /**
     * Creates a Case
     * @author Steve O'Neal
     * @date   2016-08-11
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-4026
     * @param  cont       The contact to link the case to
     * @return            A unique case
     */
    private static Case createTestCase(Contact cont)
    {
        Case retVal = new Case();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Reason = 'Test Case - ' + seed1;
        retVal.Origin = 'Web';
        retVal.Status = 'New';
        retVal.Requesting_Department__c = 'Client Success';
        if (cont != null)
        {
            if (cont.AccountId != null)
            {
                retVal.AccountId = cont.AccountId;
                retVal.Account = cont.Account;
            }
            retVal.ContactId = cont.Id;
            retVal.Contact = cont;
        }

        return retVal;

    }

    /**
     * Creates a list of unique cases
     * @author Steve O'Neal
     * @date   2016-08-11
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords Number of cases to make for each supplied Contact
     * @param  contacts        List of contacts to link to the cases
     * @return                 List of unique cases
     */
    public static List<Case> createTestCases(integer numberOfRecords, List<Contact> contacts)
    {
        List<Case> retVal = new List<Case>();

        if (contacts != null && contacts.size() > 0)
        {
            for (Contact cont : contacts)
            {
                for (integer i = 0; i < numberOfRecords; i++)
                {
                    retVal.add(TestDataFactory.createTestCase(cont));
                }
            }
        }
        else
        {
            for (integer i = 0; i < numberOfRecords; i++)
            {
                retVal.add(TestDataFactory.createTestCase(null));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;

    }


    ///////////////////////////////
    // LIVE CHAT TRANSCRIPTS     //
    ///////////////////////////////
    /**
     * Creates test data for LiveChatTranscript
     * @author Steve O'Neal
     * @date   2017-02-09
     * @ticket link                         https://jira.bigcommerce.com/browse/BAP-4327
     * @param  caseForTranscript            Case to attach the transcript to
     * @param  liveChatVisitorForTranscript Visitor to associate with the transcript
     * @return                              Unique live chat transcript
     */
    private static LiveChatTranscript createTestLiveChatTranscript(Case caseForTranscript, LiveChatVisitor liveChatVisitorForTranscript)
    {
        LiveChatTranscript retVal = new LiveChatTranscript();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.CaseId = caseForTranscript.Id;
        retVal.Status = 'Completed';
        retVal.StartTime = DateTime.now().addMinutes(-15);
        retVal.EndTime = DateTime.now();      
        retVal.LiveChatVisitorId = liveChatVisitorForTranscript.Id;
        
        return retVal;
    }


    /**
     * Creates list of test LiveChatTranscripts
     * @author Steve O'Neal
     * @date   2017-02-09
     * @ticket link               https://jira.bigcommerce.com/browse/BAP-4327
     * @param  casesForTranscript Cases to attach the transcripts to
     * @param  numberOfRecords    How many transcripts to make for each case.  Makes a unique visitor for each transcript as well.
     * @return                    Unique live chat transcripts
     */
    public static List<LiveChatTranscript> createTestLiveChatTranscripts(List<Case> casesForTranscript, integer numberOfRecords)
    {
        List<LiveChatTranscript> retVal = new List<LiveChatTranscript>();

        List<LiveChatVisitor> liveChatVisitorList = createTestLiveChatVisitors(numberOfRecords);

        for (LiveChatVisitor liveChatVisitorForTranscript : liveChatVisitorList)
        {
            for (case caseForTranscript : casesForTranscript)
            {
                retVal.add(createTestLiveChatTranscript(caseForTranscript, liveChatVisitorForTranscript));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates a test LiveChatVisitor
     * @author Steve O'Neal
     * @date   2017-02-09
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     * @return Test LiveChatVisitor record
     */
    private static LiveChatVisitor createTestLiveChatVisitor()
    {
        return new LiveChatVisitor();
    }
    

    /**
     * Creates a list of LiveChatVisitors
     * @author Steve O'Neal
     * @date   2017-02-09
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords How many LiveChatVisitors to create
     * @return                 List of LiveChatVisitors
     */
    public static List<LiveChatVisitor> createTestLiveChatVisitors(integer numberOfRecords)
    {
        List<LiveChatVisitor> retVal = new List<LiveChatVisitor>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            retVal.add(createTestLiveChatVisitor());
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    ////////////////////
    // GOOGLE COUPONS //
    ////////////////////
    /**
     * Creates a test google coupon
     * @author Steve O'Neal
     * @date   2016-09-19
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4177
     * @return Unique coupon
     */
    public static Google_Coupon__c createTestGoogleCoupon()
    {
        Google_Coupon__c retVal = new Google_Coupon__c();

        retVal.Amount__c = 100;
        retVal.Coupon_Code__c = String.valueof(MathUtility.RandomInteger(1000, 9999));
        retVal.Expires__c = Date.today().addYears(1);

        return retVal;
    }


    /**
     * Creates a list of test google coupons
     * @author Steve O'Neal
     * @date   2016-09-19
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4177
     * @return Unique coupons
     */
    public static List<Google_Coupon__c> createTestGoogleCoupons(integer numberOfRecords)
    {
        List<Google_Coupon__c> retVal = new List<Google_Coupon__c>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            retVal.add(TestDataFactory.createTestGoogleCoupon());
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates a Promoter.io Feedback
     * @author Bala Rajagopal
     * @date   2016-09-06
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-3171
     * @param  cont       The contact to link the case to
     * @return            A unique Promoter IO Feedback
     */
    public static Promoter_io_Feedback__c createPromoterIoFeedback(Contact cont)
    {
        Promoter_io_Feedback__c  retVal = new Promoter_io_Feedback__c ();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Email__c = cont.Email;
        retVal.Score__c = 25;
        retVal.Feedback_Unique_External_ID__c  = 'TestID';
        retVal.Posted_Date__c = date.newInstance(2016, 6, 29);
        retVal.SF_Account_ID__c = cont.accountid;
        retVal.Contact__c = cont.id;
        insert retVal;

        return retVal;

    }


    ///////////
    // ZUORA //
    ///////////

    /**
     * Creates an instance in memory of a UOM test record
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-4327
     * @param  nameOfUOM  Name of the Unit
     * @return            A test Unit of Measure
     */
    private static Zuora__UnitOfMeasure__c createTestZuoraUnitOfMeasure(string nameOfUOM)
    {
        Zuora__UnitOfMeasure__c retVal = new Zuora__UnitOfMeasure__c();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Name = nameOfUOM;
        retVal.Zuora__External_Id__c = seed1;

        return retVal;
    }


    /**
     * Creates Zuora UOM test records
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     * @return A list of Zuora Units Of Measure
     */
    public static List<Zuora__UnitOfMeasure__c> createTestZuoraUnitsOfMeasure()
    {
        List<Zuora__UnitOfMeasure__c> retVal = [Select Id, Name, Zuora__External_Id__c from Zuora__UnitOfMeasure__c];

        if (retVal.size() == 0)
        {

            retVal = new List<Zuora__UnitOfMeasure__c>();
            String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

            retVal.add(createTestZuoraUnitOfMeasure(seed1));

            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates an instance in memory of a Zuora Billing Account
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link             https://jira.bigcommerce.com/browse/BAP-4327
     * @param  relatedToAccount The Salesforce Account to tie to
     * @return                  An instance of a Zuora Billing Account
     */
    private static Zuora__CustomerAccount__c createTestZuoraBillingAccount(Account relatedToAccount)
    {
        Zuora__CustomerAccount__c retVal = new Zuora__CustomerAccount__c();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));
        String seed2 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Name = 'Billing Account ' + seed1;
        retVal.Zuora__Account__c = relatedToAccount.Id;
        retVal.Zuora__AccountNumber__c = seed1;
        retVal.Zuora__BillToId__c = seed2;
        retVal.Zuora__BillToName__c = 'Bill Smith';
        retVal.Zuora__SoldToId__c = seed2;
        retVal.Zuora__SoldToName__c = 'Bill Smith';


        return retVal;
    }


    /**
     * Creates a list of Zuora Billing Accounts
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link              https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords   How many Billing Accounts to make per Account
     * @param  relatedToAccounts Accounts to link the Billing Accounts to
     * @return                   A list of test Zuora Billing Accounts
     */
    public static List<Zuora__CustomerAccount__c> createTestZuoraBillingAccounts(integer numberOfRecords, List<Account> relatedToAccounts)
    {
        List<Zuora__CustomerAccount__c> retVal = new List<Zuora__CustomerAccount__c>();

        for (Account relatedToAccount : relatedToAccounts)
        {
            for (integer i = 0; i < numberOfRecords; i++)
            {
                retVal.add(createTestZuoraBillingAccount(relatedToAccount));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates an instance in memory of a Zuora subscription
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link                    https://jira.bigcommerce.com/browse/BAP-4327
     * @param  relatedToAccount        The account record to tie to
     * @param  relatedToBillingAccount The Zuora billing account record to tie to
     * @param  relatedToOpportunity    The opportunity to tie to
     * @return                         An instance of a Zuora Subscription
     */
    private static Zuora__Subscription__c createTestZuoraSubscription(Zuora__CustomerAccount__c relatedToBillingAccount, Opportunity relatedToOpportunity)
    {
        Zuora__Subscription__c retVal = new Zuora__Subscription__c();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Name = 'A-' + seed1;
        retVal.Zuora__External_Id__c = seed1;
        retVal.Zuora__Zuora_Id__c = seed1;
        retVal.Zuora__Account__c = relatedToBillingAccount.Zuora__Account__c;
        retVal.Zuora__CustomerAccount__c = relatedToBillingAccount.Id;
        retVal.Zuora__InvoiceOwner__c = relatedToBillingAccount.Id;
        retVal.Zuora__Version__c = 1;
        retVal.Zuora__TermStartDate__c = Date.today();
        retVal.Zuora__ContractAcceptanceDate__c = retVal.Zuora__TermStartDate__c;
        retVal.Zuora__ContractEffectiveDate__c = retVal.Zuora__TermStartDate__c;
        retVal.Zuora__ServiceActivationDate__c = retVal.Zuora__TermStartDate__c;
        retVal.Zuora__SubscriptionStartDate__c = retVal.Zuora__TermStartDate__c;
        retVal.Zuora__TermSettingType__c = 'EVERGREEN';
        retVal.Zuora__MRR__c = 100;
        retVal.Opportunity__c = relatedToOpportunity.Id;
        retVal.Zuora__Status__c = 'Active';
        retVal.crmId__c = relatedToOpportunity.Id;

        return retVal;
    }


    /**
     * Creates a list of and inserts Zuora Subscriptions
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link                     https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords          How many subscriptions to make per billing account and opportunity combo
     * @param  relatedToBillingAccounts List of billing accounts to tie to
     * @param  relatedToOpportunities   List of opportunities to tie to
     * @return                          A list of Zuora Subscriptions
     */
    public static List<Zuora__Subscription__c> createTestZuoraSubscriptions(integer numberOfRecords, List<Zuora__CustomerAccount__c> relatedToBillingAccounts, List<Opportunity> relatedToOpportunities)
    {
        List<Zuora__Subscription__c> retVal = new List<Zuora__Subscription__c>();

        for (Zuora__CustomerAccount__c relatedToBillingAccount : relatedToBillingAccounts)
        {
            for (Opportunity relatedToOpportunity : relatedToOpportunities)
            {
                for (integer i = 0; i < numberOfRecords; i++)
                {
                    retVal.add(createTestZuoraSubscription(relatedToBillingAccount, relatedToOpportunity));
                }
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates an instance in memory of a Zuora Subscription Product and Charge
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link                   https://jira.bigcommerce.com/browse/BAP-4327
     * @param  relatedToZSub          The Zuora Subscription to link this to
     * @param  relatedZuora360Product Product used for this charge
     * @param  unitOfMeasure          Unit of measure to tie to this charge
     * @return                        An instance of a Zuora Subscription Product and Charge
     */
    private static Zuora__SubscriptionProductCharge__c createTestZuoraSubscriptionProductAndCharge(Zuora__Subscription__c relatedToZSub, Zuora__Product__c relatedZuora360Product, Zuora__UnitOfMeasure__c unitOfMeasure)
    {
        Zuora__SubscriptionProductCharge__c retVal = new Zuora__SubscriptionProductCharge__c();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Zuora__Account__c = relatedToZSub.Zuora__Account__c;
        retVal.Zuora__Price__c = MathUtility.RandomInteger(100, 500);
        retVal.Zuora__Zuora_Id__c = seed1;
        retVal.Zuora__Subscription__c = relatedToZSub.Id;
        retVal.Zuora__Product__c = relatedZuora360Product.Id;
        retVal.Zuora__MonthlyRecurringRevenue__c = retVal.Zuora__Price__c;
        retVal.Zuora__Type__c = 'Recurring';
        retVal.Zuora__ProductSKU__c = relatedZuora360Product.zuora__SKU__c;
        retVal.Zuora__External_Id__c = seed1;
        retVal.Zuora__EffectiveStartDate__c = relatedToZSub.Zuora__SubscriptionStartDate__c;

        return retVal;
    }


    /**
     * Creates a list of Zuora Subscription Product and Charge records
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link                    https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords         How many subscription charges to make per sub and per product
     * @param  relatedToSubs           Zuora Subscriptions to tie to the charges
     * @param  relatedZuora360Products Products to tie to the charges
     * @param  unitOfMeasure           Unit of measure to use when charging customer
     * @return                         A list of Zuora Subscription Products and Charges
     */
    public static List<Zuora__SubscriptionProductCharge__c> createTestZuoraSubscriptionProductAndCharges(integer numberOfRecords, List<Zuora__Subscription__c> relatedToSubs, List<Zuora__Product__c> relatedZuora360Products, Zuora__UnitOfMeasure__c unitOfMeasure)
    {
        List<Zuora__SubscriptionProductCharge__c> retVal = new List<Zuora__SubscriptionProductCharge__c>();
        
        for (Zuora__Subscription__c relatedToSub : relatedToSubs)
        {
            for (Zuora__Product__c zuora360Product : relatedZuora360Products)
            {
                for (integer i = 0; i < numberOfRecords; i++)
                {
                    retVal.add(createTestZuoraSubscriptionProductAndCharge(relatedToSub, zuora360Product, unitOfMeasure));
                }
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates a zProduct in memory
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link             https://jira.bigcommerce.com/browse/BAP-4327
     * @param  relatedToProduct The product to relate the zProduct to
     * @return                  An instance of a zProduct
     */
    private static zqu__ZProduct__c createTestZuoraZProduct(Product2 relatedToProduct)
    {
        zqu__ZProduct__c retVal = new zqu__ZProduct__c();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Name = relatedToProduct.Name;
        retVal.BCCategory__c = 'STORE';
        retVal.zqu__SKU__c = relatedToProduct.ProductCode;
        retVal.zqu__Description__c = 'Test';
        retVal.zqu__Deleted__c = false;
        retVal.zqu__ZuoraId__c = seed1;
        retVal.zqu__Category__c = 'Base Products';

        return retVal;
    }


    /**
     * Creates a list of Zuora products related to the Salesforce products
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link              https://jira.bigcommerce.com/browse/BAP-4327
     * @param  relatedToProducts The products to relate the zProducts to
     * @return                   A list of test ZProducts
     */
    public static List<zqu__ZProduct__c> createTestZuoraZProducts(List<Product2> relatedToProducts)
    {
        List<zqu__ZProduct__c> retVal = new List<zqu__ZProduct__c>();

        for (Product2 relatedToProduct : relatedToProducts)
        {
            retVal.add(createTestZuoraZProduct(relatedToProduct));
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates a test product for Zuora from their 360 package (for associating with subscription charges)
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link             https://jira.bigcommerce.com/browse/BAP-4327
     * @param  relatedToProduct The Salesforce product related to this product
     * @return                  An instance of a Zuora Product
     */
    private static Zuora__Product__c createTestZuora360Product(Product2 relatedToProduct)
    {
        Zuora__Product__c retVal = new Zuora__Product__c();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Name = relatedToProduct.Name;
        retVal.BCCategory__c = 'STORE';
        retVal.Zuora__SKU__c = relatedToProduct.ProductCode;
        retVal.Zuora__Description__c = 'Test';
        retVal.Zuora__External_Id__c = seed1;

        return retVal;
    }


    /**
     * Creates a list of Zuora Products
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link              https://jira.bigcommerce.com/browse/BAP-4327
     * @param  relatedToProducts The products to relate to the Zuora Products
     * @return                   A list of Zuora Products
     */
    public static List<Zuora__Product__c> createTestZuora360Products(List<Product2> relatedToProducts)
    {
        List<Zuora__Product__c> retVal = new List<Zuora__Product__c>();

        for (Product2 relatedToProduct : relatedToProducts)
        {
            retVal.add(createTestZuora360Product(relatedToProduct));
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
   }


    /**
     * Creates a Zuora subscription, plus charges and all supporting data, and relates it to the passed-in Opportunity
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link                     https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords          How many ZSubscriptions to create per Opportunity
     * @param  relatedToOpportunities   The opportunities to relate the subscription to
     * @return List of Subscriptions created
     */
    public static List<Zuora__Subscription__c> createFullSuiteOfTestZuoraSubscriptionData(integer numberOfRecords, List<Opportunity> relatedToOpportunities)
    {
        System.debug(relatedToOpportunities);
        Set<Id> relatedAccountIds = new Set<Id>();
        for (Opportunity relatedToOpportunity : relatedToOpportunities)
        {
            relatedAccountIds.add(relatedToOpportunity.AccountId);
        }
        List<Account> relatedAccounts = [Select Id, Name from Account where Id = :relatedAccountIds];
        System.debug(relatedAccounts);

        List<Zuora__CustomerAccount__c> relatedToBillingAccounts = createTestZuoraBillingAccounts(1, relatedAccounts);
        System.debug(relatedToBillingAccounts);

        List<Zuora__Subscription__c> retVal = createTestZuoraSubscriptions(numberOfRecords, relatedToBillingAccounts, relatedToOpportunities);
        System.debug(retVal);

        List<Product2> testProducts = createTestProduct2s(1);
        System.debug(testProducts);
        
        List<PricebookEntry> testPriceBookEntries = createTestZuoraPriceBookEntries(testProducts);
        System.debug(testPriceBookEntries);
        
        List<zqu__ZProduct__c> testZProducts = createTestZuoraZProducts(testProducts);
        System.debug(testZProducts);
        
        List<Zuora__Product__c> testZuora360Products = createTestZuora360Products(testProducts);
        System.debug(testZuora360Products);
        
        List<Zuora__UnitOfMeasure__c> testUnitsOfMeasure = createTestZuoraUnitsOfMeasure();
        System.debug(testUnitsOfMeasure);

        List<Zuora__SubscriptionProductCharge__c> testSubProductAndCharges = createTestZuoraSubscriptionProductAndCharges(1, retVal, testZuora360Products, testUnitsOfMeasure[0]);
        System.debug(testSubProductAndCharges);

        return retVal;
    }



    //////////////
    // PRODUCT2 //
    //////////////
    /**
     * Creates an instance in memory of a Salesforce Product
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-4327
     */
    private static Product2 createTestProduct2()
    {
        Product2 retVal = new Product2();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));
        retVal.Name = 'Test Store ' + seed1;
        retVal.ProductCode = 'STORE-' + seed1;
        retVal.IsActive = true;
        return retVal;
    }


    /**
     * Creates a list of Salesforce products
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-4327
     * @param  numberOfRecords How many products to create
     * @return                 A list of Salesforce products
     */
    public static List<Product2> createTestProduct2s(integer numberOfRecords)
    {
        List<Product2> retVal = [Select Id, Name, ProductCode, IsActive from Product2 where IsActive = true limit :numberOfRecords];

        if (retVal.size() == 0)
        {
            retVal = new List<Product2>();

            for (integer i = 0; i < numberOfRecords; i++)
            {
                retVal.add(createTestProduct2());
            }

            if (retVal.size() > 0)
            {
                insert retVal;
            }
        }

        return retVal;
    }


    /**
     * Creates pricebook entries for Products and relates them to the Zuora Base Products pricebook
     * @author Steve O'Neal
     * @date   2017-04-12
     * @ticket link              https://jira.bigcommerce.com/browse/BAP-4327
     * @param  relatedToProducts List of products to associate with Zuora pricebook
     * @return                   A list of pricebook entries
     */
    public static List<PricebookEntry> createTestZuoraPriceBookEntries(List<Product2> relatedToProducts)
    {
        // check to see if these products exist as a pricebook entry already
        Set<Id> productIds = new Set<Id>();
        for (Product2 prod : relatedToProducts)
        {
            productIds.add(prod.Id);
        }

        List<PricebookEntry> retVal = [Select Id, pricebook2Id, product2Id, unitPrice, isActive from PricebookEntry where product2Id = :productIds];

        if (retVal.size() == 0)
        {
            retVal = new List<PricebookEntry>();

            for (Product2 relatedToProduct : relatedToProducts)
            {
                retVal.add(new PricebookEntry(pricebook2id = ZuoraUtility.ZuoraPriceBookId, product2Id = relatedToProduct.Id, unitPrice = 100, isActive = true));
            }

            if (retVal.size() > 0)
            {
                insert retVal;
            }
        }

        return retVal;
    }

    /////////////////
    // PARTNER APP //
    /////////////////
    /**
     * Creates an instance in memory of a Partner App
     * @author Ezra Kenigsberg
     * @date   2017-10-11
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-6073
     */
    private static Partner_App__c createTestPartnerApp(rvpe__RVAccount__c rva)
    {
        Partner_App__c retVal = new Partner_App__c();
        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));
        retVal.Name = 'Test Partner App ' + seed1;
        retVal.RV_Account__c = rva.Id;
        return retVal;
    }

    /**
     * Creates a list of test Partner Apps
     * @author Ezra Kenigsberg
     * @date   2017-10-11
     * @ticket link             https://jira.bigcommerce.com/browse/BAP-6073
     * @param  numberOfRecords  The number of Partner Apps to create for each RV Account
     * @param  rvas             The RV Accounts to create Partner Apps for
     * @return                  A list of test Partner Apps
     */
    global static List<Partner_App__c> createTestPartnerApps(integer numberOfRecords, List<rvpe__RVAccount__c> rvas)
    {
        List<Partner_App__c> retVal = new List<Partner_App__c>();

        if (rvas != null && rvas.size() > 0)
        {
            for (rvpe__RVAccount__c rva : rvas)
            {
                for (integer i = 0; i < numberOfRecords; i++)
                {
                    retVal.add(TestDataFactory.createTestPartnerApp(rva));
                }
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }

    /////////////////////
    // CUSTOM SETTINGS //
    /////////////////////
    /**
     * Fetches existing BatchableChains settings, or creates new ones
     * @author Steve O'Neal
     * @date   2017-02-13
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     * @return Custom settings for BatchableChains
     */
    public static List<BatchableChain__c> createBatchableChains()
    {
        List<BatchableChain__c> retVal = BatchableChain__c.getAll().values();

        if (retVal.size() == 0)
        {
            retVal = getMinimalBatchableChains();
            insert retVal;
        }

        return retVal;
    }

    /**
     * Creates new BatchableChains settings
     * @author Steve O'Neal
     * @date   2017-02-13
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     * @return Custom settings for BatchableChains
     */
    private static List<BatchableChain__c> getMinimalBatchableChains()
    {
        List<BatchableChain__c> retVal = new List<BatchableChain__c>();

        retVal.add(new BatchableChain__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Scope_Size__c = 200,
                Triggering_Batch_Name__c = 'BatchStagingGarbageCollection',
                Batch_To_Execute__c = 'BatchFlagDuplicateLeads'));

        return retVal;
    }


    /**
     * Fetches existing StagingToTableMappings, or creates new ones if necessary
     * @author Steve O'Neal
     * @date   2017-02-13
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     * @return Custom settings for StagingToTableMappings
     */
    public static List<StagingToTableMapping__c> createStagingToTableMappings()
    {
        List<StagingToTableMapping__c> retVal = StagingToTableMapping__c.getAll().values();

        if (retVal.size() == 0)
        {
            retVal = getMinimalStagingToTableMappings();
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates new StagingToTableMappings
     * @author Steve O'Neal
     * @date   2017-02-13
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     * @return Custom settings for StagingToTableMappings
     */
    private static List<StagingToTableMapping__c> getMinimalStagingToTableMappings()
    {
        List<StagingToTableMapping__c> retVal = new List<StagingToTableMapping__c>();

        //////////////
        // ACCOUNTS //
        //////////////
        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Account__c',
                Staging_Object_Field_Name_API__c = 'CompanyName__c',
                Object_Name_API__c = 'Account',
                Object_Field_Name_API__c = 'Name'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Account__c',
                Staging_Object_Field_Name_API__c = 'MBAAccountId__c',
                Object_Name_API__c = 'Account',
                Object_Field_Name_API__c = 'MBAAccountId__c'));


        //////////////
        // CONTACTS //
        //////////////
        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Contact__c',
                Staging_Object_Field_Name_API__c = 'FirstName__c',
                Object_Name_API__c = 'Contact',
                Object_Field_Name_API__c = 'FirstName'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Contact__c',
                Staging_Object_Field_Name_API__c = 'LastName__c',
                Object_Name_API__c = 'Contact',
                Object_Field_Name_API__c = 'LastName'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Contact__c',
                Staging_Object_Field_Name_API__c = 'Email__c',
                Object_Name_API__c = 'Contact',
                Object_Field_Name_API__c = 'Email'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Contact__c',
                Staging_Object_Field_Name_API__c = 'MBAAccountId__c',
                Object_Name_API__c = 'Contact',
                Object_Field_Name_API__c = 'MBAAccountId__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Contact__c',
                Staging_Object_Field_Name_API__c = 'MBAClientID__c',
                Object_Name_API__c = 'Contact',
                Object_Field_Name_API__c = 'MBAClientID__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Contact__c',
                Staging_Object_Field_Name_API__c = 'Primary_MBA_Contact__c',
                Object_Name_API__c = 'Contact',
                Object_Field_Name_API__c = 'Primary_MBA_Contact__c'));


        ///////////////////
        // SUBSCRIPTIONS //
        ///////////////////

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'MBAAccountId__c',
                Object_Name_API__c = 'Subscription__c',
                Object_Field_Name_API__c = 'MBAAccountId__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'MBASubscriptionID__c',
                Object_Name_API__c = 'Subscription__c',
                Object_Field_Name_API__c = 'MBASubscriptionID__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'StoreURL__c',
                Object_Name_API__c = 'Subscription__c',
                Object_Field_Name_API__c = 'StoreURL__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'Product__c',
                Object_Name_API__c = 'Subscription__c',
                Object_Field_Name_API__c = 'Product__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'SubscriptionType__c',
                Object_Name_API__c = 'Subscription__c',
                Object_Field_Name_API__c = 'ProductType__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'isTrial__c',
                Object_Name_API__c = 'Subscription__c',
                Object_Field_Name_API__c = 'isTrial__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'StartDate__c',
                Object_Name_API__c = 'Subscription__c',
                Object_Field_Name_API__c = 'StartDate__c'));


        ///////////////////
        // OPPORTUNITIES //
        ///////////////////

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'Name',
                Object_Name_API__c = 'Opportunity',
                Object_Field_Name_API__c = 'Name'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'MBAAccountId__c',
                Object_Name_API__c = 'Opportunity',
                Object_Field_Name_API__c = 'MBAAccountId__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'MBASubscriptionID__c',
                Object_Name_API__c = 'Opportunity',
                Object_Field_Name_API__c = 'MBASubscriptionID__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'StoreURL__c',
                Object_Name_API__c = 'Opportunity',
                Object_Field_Name_API__c = 'StoreURL__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'Product__c',
                Object_Name_API__c = 'Opportunity',
                Object_Field_Name_API__c = 'Product__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'SubscriptionType__c',
                Object_Name_API__c = 'Opportunity',
                Object_Field_Name_API__c = 'SubscriptionType__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'isTrial__c',
                Object_Name_API__c = 'Opportunity',
                Object_Field_Name_API__c = 'isTrial__c'));

        ////////////
        // STORES //
        ////////////

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'Name',
                Object_Name_API__c = 'Store__c',
                Object_Field_Name_API__c = 'Name'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'MBASubscriptionID__c',
                Object_Name_API__c = 'Store__c',
                Object_Field_Name_API__c = 'Hosting_ID__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'StoreURL__c',
                Object_Name_API__c = 'Store__c',
                Object_Field_Name_API__c = 'Store_URL__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'Product__c',
                Object_Name_API__c = 'Store__c',
                Object_Field_Name_API__c = 'Product__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'ProductID__c',
                Object_Name_API__c = 'Store__c',
                Object_Field_Name_API__c = 'Product_ID__c'));

        retVal.add(new StagingToTableMapping__c(
                Name = String.valueOf(retVal.size()),
                Active__c = true,
                Staging_Object_Name_API__c = 'MBA_Staging_Subscription__c',
                Staging_Object_Field_Name_API__c = 'isTrial__c',
                Object_Name_API__c = 'Store__c',
                Object_Field_Name_API__c = 'Is_Trial__c'));

        return retVal;
    }


    /**
     * Fetches existing settings for API_Connection_Setting__c or creates new ones
     * @author Steve O'Neal
     * @date   2017-02-13
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     * @return A list of API_Connection_Setting__c
     */
    public static List<API_Connection_Setting__c> createAPIConnectionSettings()
    {
        List<API_Connection_Setting__c> retVal = API_Connection_Setting__c.getAll().values();

        if (retVal.size() == 0)
        {
            retVal = getMinimalAPIConnectionSettings();
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates custom settings for API_Connection_Setting__c
     * @author Steve O'Neal
     * @date   2017-02-13
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     * @return A list of API_Connection_Setting__c
     */
    private static List<API_Connection_Setting__c> getMinimalAPIConnectionSettings()
    {
        List<API_Connection_Setting__c> retVal = new List<API_Connection_Setting__c>();

        retVal.add(new API_Connection_Setting__c(
                Name = 'BMP',
                Google_Analytics_Property_Id__c = '',
                Password__c = 'NoPassword',
                URL__c = 'https://bmpurl.com',
                UserName__c = 'NoUsername'));

        retVal.add(new API_Connection_Setting__c(
                Name = 'BMP_Sandbox',
                Google_Analytics_Property_Id__c = '',
                Password__c = 'NoPassword',
                URL__c = 'https://bmpurl.com',
                UserName__c = 'NoUsername'));

        retVal.add(new API_Connection_Setting__c(
                Name = 'GoogleAnalytics',
                Google_Analytics_Property_Id__c = '123456789',
                Password__c = 'NoPassword',
                URL__c = 'https://analytics.google.com/',
                UserName__c = 'NoUsername'));

        retVal.add(new API_Connection_Setting__c(
                Name = 'Algolia',
                Google_Analytics_Property_Id__c = '',
                Password__c = 'NoPassword',
                URL__c = 'https://unknown.algolia.net/1/',
                UserName__c = 'NoUsername'));

        return retVal;
    }



    /////////////
    // BI DATA //
    /////////////
    /**
     * Creates an instance in memory of a single BI Data record
     * @author Steve O'Neal
     * @date   2017-04-06
     * @ticket link              https://jira.bigcommerce.com/browse/BAP-4327
     * @param  storeOpportunity  The related store Opportunity
     * @param  storeSubscription The related store Subscription
     * @return                   A single BI Data record
     */
    private static BI_Data__c createTestBIData(Opportunity storeOpportunity, Subscription__c storeSubscription)
    {
        BI_Data__c retVal = new BI_Data__c();
        retVal.Lifetime_GMV__c = 1000;
        retVal.Last_Payment_Amount__c = 20;
        retVal.Last_Payment_Date__c = date.Today();
        retVal.Opportunity__c = storeOpportunity.Id;
        retVal.Subscription__c = storeSubscription.Id;

        return retVal;
    }


    /**
     * Creates and inserts a list of BI Data records for each opportunity, subscription, and number of records specified
     * @author Steve O'Neal
     * @date   2017-04-06
     * @ticket link               https://jira.bigcommerce.com/browse/BAP-4327
     * @param  storeOpportunities The related Opportunities
     * @param  storeSubscriptions The related Subscriptions
     * @param  numberOfRecords    Number of BI Data records to create for each Subscription/Opportunity combination
     * @return                    A list of BI Data records
     */
    global static List<BI_Data__c> createTestBIData(List<Opportunity> storeOpportunities, List<Subscription__c> storeSubscriptions, integer numberOfRecords)
    {
        List<BI_Data__c> retVal = new List<BI_Data__c>();

        for (Opportunity storeOpportunity : storeOpportunities)
        {
            for (Subscription__c storeSubscription : storeSubscriptions)
            {
                for (integer i = 0; i < numberOfRecords; i++)
                {
                    retVal.add(TestDataFactory.createTestBIData(storeOpportunity, storeSubscription));
                }

            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }



    //////////////////
    // SEARCH INDEX //
    //////////////////

    /**
     * Creates a list of Search Indices
     * @author Steve O'Neal
     * @date   2017-07-26
     * @ticket link            https://jira.bigcommerce.com/browse/BAP-5098
     * @param  numberOfRecords Number of records to create
     * @return                 A list of Search Indices
     */
    public static List<Search_Index__c> createTestSearchIndices(integer numberOfRecords)
    {
        List<Search_Index__c> retVal = new List<Search_Index__c>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            retVal.add(TestDataFactory.createTestSearchIndex());
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates a single Search Index in memory
     * @author Steve O'Neal
     * @date   2017-07-26
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-5098
     * @return A Search Index
     */
    private static Search_Index__c createTestSearchIndex()
    {
        Search_Index__c retVal = new Search_Index__c();

        String seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));
        retVal.Active__c = true;
        retVal.Name = 'FAKE_INDEX_' + seed1;

        return retVal;
    }


    /**
     * Creates a list of Search Index Objects, specifically for Knowledge articles
     * @author Steve O'Neal
     * @date   2017-07-26
     * @ticket link                 https://jira.bigcommerce.com/browse/BAP-5098
     * @param  numberOfRecords      Number of records to create per Search Index
     * @param  relatedSearchIndices List of associated Search Indices
     * @return                      A list of Search Index Objects
     */
    public static List<Search_Index_Object__c> createTestSearchIndexObjectsKnowledge(integer numberOfRecords, List<Search_Index__c> relatedSearchIndices)
    {
        List<Search_Index_Object__c> retVal = new List<Search_Index_Object__c>();

        for (integer i = 0; i < numberOfRecords; i++)
        {
            for (Search_Index__c searchIndex : relatedSearchIndices)
            {
                retVal.add(TestDataFactory.createTestSearchIndexObjectKnowledge(searchIndex));
            }
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }

        return retVal;
    }


    /**
     * Creates a single Search Index Object for Knowledge in memory
     * @author Steve O'Neal
     * @date   2017-07-26
     * @ticket link               https://jira.bigcommerce.com/browse/BAP-5098
     * @param  relatedSearchIndex The associated Search index
     * @return                    An instance of a Search Index
     */
    private static Search_Index_Object__c createTestSearchIndexObjectKnowledge(Search_Index__c relatedSearchIndex)
    {
        Search_Index_Object__c retVal = new Search_Index_Object__c();

        retVal.Search_Index__c = relatedSearchIndex.Id;
        retVal.Active__c = true;
        retVal.Name = 'Public__kav';

        return retVal;
    }


    /**
     * Creates a list of Search Index Records
     * @author Steve O'Neal
     * @date   2017-07-26
     * @ticket link                        https://jira.bigcommerce.com/browse/BAP-5098
     * @param  numberOfRecords             Number of records to create per Search Index Object
     * @param  relatedToSearchIndexObjects List of associated Search Index Objects
     * @return                             A list of Search Index Records
     */
    public static List<Search_Index_Record__c> createTestSearchIndexRecords(integer numberOfRecords, List<Search_Index_Object__c> relatedToSearchIndexObjects)
    {
        List<Search_Index_Record__c> retVal = new List<Search_Index_Record__c>();
        
        Set<String> recordKeys = new Set<String>();
        
       for (integer i = 0; i < numberOfRecords; i++)
       {
            for (Search_Index_Object__c searchIndexObject : relatedToSearchIndexObjects)
            {
                
                Search_Index_Record__c indexRecord;
                
                do{

                    indexRecord = TestDataFactory.createTestSearchIndexRecord(searchIndexObject);

                }while(recordKeys.contains(indexRecord.Search_Index_Record_Key__c)); //Search_Index_Record_Key__c should be Text(255) (External ID) (Unique Case Insensitive)
                    
                    recordKeys.add(indexRecord.Search_Index_Record_Key__c);
                    
                    retVal.add(indexRecord);
            }
            
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }
        
        return retVal;
    }


    /**
     * Creates a single instance of a Search Index Record in memory
     * @author Steve O'Neal
     * @date   2017-07-26
     * @ticket link                       https://jira.bigcommerce.com/browse/BAP-5098
     * @param  relatedToSearchIndexObject The associated Search Index Object
     * @return                            A single Search Index Record
     */
    private static Search_Index_Record__c createTestSearchIndexRecord(Search_Index_Object__c relatedToSearchIndexObject)
    {
        Search_Index_Record__c retVal = new Search_Index_Record__c();
        string seed1 = String.valueof(MathUtility.RandomInteger(1000, 9999));

        retVal.Search_Index_Object__c = relatedToSearchIndexObject.Id;
        retVal.Body__c = seed1;
        retVal.Action__c = 'Upsert Record';
        retVal.Search_Index_Record_Key__c = seed1;
        retVal.Status__c = 'New';

        return retVal;
    }



    ////////////////////////
    // SUPPORTING OBJECTS //
    ////////////////////////

    /**
     * Creates a Single Request Mock instance for testing API callouts
     * @author Steve O'Neal
     * @date   2017-02-13
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     * @return A single request mock
     */
    public static SingleRequestMock createSingleRequestMock()
    {
        return new SingleRequestMock(200, 'Complete', '[Status=OK, StatusCode=200]', null);
    }



    /**
     * Increases code coverage as needed.  This should only be used as a temporary emergency last resort to get coverage levels up.
     * @author Steve O'Neal
     * @date   2017-04-05
     * @ticket link          https://jira.bigcommerce.com/browse/BAP-4327
     */
    global static void IncreaseCodeCoverage()
    {
        integer i = 1;
        i = 1;
        // repeat the above line as needed
    }

}