@isTest
private class SupportT2LiveAgentPreChatController_Test { 

    public static SupportT2LiveAgentPreChatController scc { get; set; }
    public static Subscription__c testSub { get; set; }
    public static Account testAccount { get; set; }
    public static Contact testContact { get; set; }
    public static Account testPartnerAccount { get; set; }
    public static Contact testPartnerContact { get; set; }
    public static Opportunity testOpp { get; set; }
    public static rvpe__RVMember__c rvmember { get; set; }
    public static CaseSubmissionSettings__c css { get; set; }
    public static CaseQueueRouting__c testSupportQueue { get; set; }

        
    public static void setUp() {
        SupportT2LiveAgentPreChatController_Test.setUp(true);
    }    

    public static void setUp(Boolean newScc) {
        System.debug('SupportT2LiveAgentPreChatController_Test->setUp()');

 
        testSub = new Subscription__c(
            RecordTypeId = Subscription__c.getSObjectType().getDescribe().getRecordTypeInfosByName().get('MBA Subscription').getRecordTypeId(),
            StoreURL__c= 'testingStorebigcommerce',
            ProductType__c = 'Store',
            Status__c = 'Active',
            productId__c ='28',
            Source__c = 'Direct Trial'                  
            );

        insert testSub;
      testAccount = new Account(
            RecordTypeId = Account.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Client Record Type').getRecordTypeId(),
            Name = 'testName',
            Type = 'Client',
            Status__c = 'Open', 
            Client_Start_Date__c = date.today(), 
            SupportPin__c = '1234'
            );

        insert testAccount;

        testContact = new Contact(
            LastName = 'testLastName',
            accountId = testAccount.id
            );
        insert testContact;
        
        testPartnerAccount = new Account(
            RecordTypeId = Account.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Channel Partner Record Type').getRecordTypeId(),
            Name = 'testPartnerName',
            Type = 'Partner',
            Status__c = 'Open', 
            Client_Start_Date__c = date.today(), 
            SupportPin__c = '12345'
            );

        insert testPartnerAccount;

        testPartnerContact = new Contact(
            LastName = 'testPartnerLastName',
            accountId = testPartnerAccount.id
            );
        insert testPartnerContact;
        
        List<Account> listAccounts = new List<Account>();
        listAccounts.add(testAccount);
        
        testOpp = testDataFactory.createTestOpportunities(1, listAccounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase'))[0];
        
        List<rvpe__RVAccount__c> rvAccounts = TestDataFactory.CreateTestRVAccounts(1);
        List<rvpe__RVMember__c> rvMembers = TestDataFactory.CreateTestRVMembers(1, rvAccounts);
        rvAccounts[0].rvpe__SFAccount__c = testPartnerAccount.id;
        update rvAccounts;
        rvmember = rvMembers[0];
        rvmember.rvpe__SFContact__c = testPartnerContact.id;
        testPartnerContact.RV_Member__c = rvmember.id;
        testPartnerContact.RV_Account__c  = rvmember.rvpe__RVAccount__c;
        update testPartnerContact;
        
        testOpp.rvpe__RVAccount__c = rvmember.rvpe__RVAccount__c;
        testOpp.rvpe__RVMember__c = rvmember.id;
        testOpp.StoreURL__c = testSub.StoreURL__c;
        update testOpp;

        testSub.Account__c = testAccount.Id;
        testSub.Contact__c = testContact.Id;
        testSub.Opportunity__c = testOpp.id;
        update testSub;
        
        


        testSub = [SELECT Id, Account__c, Contact__c,StoreURL__c,Support_PIN__c FROM Subscription__c WHERE Id =: testSub.Id];

        css = new CaseSubmissionSettings__c(
            Name = 'Partner',
            Case_Origin__c ='Web',
            Case_Record_Type__c = Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Partner Support').getRecordTypeId(),
            Contact_Record_Type__c = '',
            Default_Support_Account_ID__c = '',
            Default_Support_Owner_ID__c = '00Ga0000003ATBV',
            LiveAgent_Button_Name__c = 'Tier_2_Support',
            Redirect_URL__c = '/SubmitCaseThanks'
        );
        upsert css;
        
        

        System.assertEquals(testAccount.Id, testSub.Account__c);
        System.assertEquals(testContact.Id, testSub.Contact__c);
        Id QueueId = [SELECT QueueId FROM QueueSobject WHERE Queue.Name = 'Support' limit 1][0].QueueId;

        testSupportQueue = new CaseQueueRouting__c (
            Name = 'General Product Support',
            Queue_ID__c = QueueId,
            Queue_Name__c = 'Support',
            Help_text__c = 'test'
            );
        insert testSupportQueue;

        System.debug('testQueue : ' + testSupportQueue);

        if(newScc) {
            scc = new SupportT2LiveAgentPreChatController();
            scc.csse = 'Partner';
        }           
        
    }
    
    static testmethod void test_chat() {
        
        SupportT2LiveAgentPreChatController_Test.setUp();
        
		String testEndpoint = 'https%3A%2F%2F1.la1a1.salesforceliveagent.com';
        String testcsse = 'Partner';
        
        PageReference pg = Page.SupportT2LiveAgentPreChatPage;
        Test.setCurrentPage(pg);
        ApexPages.currentPage().getParameters().put('endpoint', testEndpoint);      
        ApexPages.currentPage().getParameters().put('csse', testcsse);     
        
        SupportT2LiveAgentPreChatController lacc = new SupportT2LiveAgentPreChatController();
        ApexPages.currentPage().getParameters().put('pid', string.valueOf(lacc.rvMemberId)); 
        
        lacc.theContact.FirstName = 'John';
        lacc.theContact.LastName = 'Smith';
        lacc.theContact.Email = 'johnsmith@test.com';
        lacc.theContact.Description = 'This some text';
        lacc.fireit();
        lacc.clickChat();
	}
    

    static testMethod void myPrepopulatedQueryStringTest() {
        PageReference pg = Page.SupportT2LiveAgentPreChatPage;
        Test.setCurrentPage(pg);

        SupportT2LiveAgentPreChatController_Test.setUp(true);

        ApexPages.currentPage().getParameters().put('storeUrl', testSub.StoreURL__c); 
        ApexPages.currentPage().getParameters().put('storeUrl', 'http;/testingBigcommerce#');
        ApexPages.currentPage().getParameters().put('storeUrl', 'http;/testingBigcommerce?');
        ApexPages.currentPage().getParameters().put('supportPin', testAccount.SupportPin__c); 
        ApexPages.currentPage().getParameters().put('pid', string.valueOf(rvmember.rvpe__ExtMemberId__c.intValue()));
        ApexPages.currentPage().getParameters().put('supportsetting', 'Partner');

        SupportT2LiveAgentPreChatController_Test.scc = new SupportT2LiveAgentPreChatController();
        scc.rvMemberId = rvmember.rvpe__ExtMemberId__c;
        scc.formDeptName.value = 'General Product Support';
        scc.formDescription.value = 'Test Dept';
        scc.formSubject.value = 'Test Subject';
        scc.validateStoreYes();
        scc.getOpps();    
        scc.getValuesFromSub();
        scc.validatePIN0();
        
        scc.caseBuilder(css);
        
        scc.getDepts();
        scc.onIssueTypeChange();
        scc.getValuesFromOpp();
    }  

    static testMethod void myPrepopulatedQueryStringTest2() {
        PageReference pg = Page.SupportT2LiveAgentPreChatPage;
        Test.setCurrentPage(pg);

        SupportT2LiveAgentPreChatController_Test.setUp(true);

        ApexPages.currentPage().getParameters().put('storeUrl', testSub.StoreURL__c); 
        ApexPages.currentPage().getParameters().put('storeUrl', 'http;/testingBigcommerce#');
        ApexPages.currentPage().getParameters().put('storeUrl', 'http;/testingBigcommerce?');
        ApexPages.currentPage().getParameters().put('supportPin', testAccount.SupportPin__c); 
        ApexPages.currentPage().getParameters().put('pid', string.valueOf(rvmember.rvpe__ExtMemberId__c.intValue()));
        ApexPages.currentPage().getParameters().put('supportsetting', 'Partner');

        SupportT2LiveAgentPreChatController_Test.scc = new SupportT2LiveAgentPreChatController();
        scc.rvMemberId = rvmember.rvpe__ExtMemberId__c;
        scc.formDeptName.value = 'General Product Support';
        scc.formDescription.value = 'Test Dept';
        scc.formSubject.value = 'Test Subject';
        scc.enterStoreURL = true;
        scc.storeurl = testOpp.StoreURL__c;
        scc.validateStoreNo();
       // scc.validatePIN();
        scc.getOpps();    
        scc.getValuesFromSub();
        scc.caseBuilder(css);
        scc.getDepts();
        scc.getisStoreRelatedText();
        scc.initFromChat();
        
    }  
    
    static testMethod void mySubmitCaseFailsTest() {
        PageReference pg = Page.SupportT2LiveAgentPreChatPage;
        Test.setCurrentPage(pg);

        SupportT2LiveAgentPreChatController_Test.setUp(false);

        ApexPages.currentPage().getParameters().put('SupportSetting', 'Partner');
        ApexPages.currentPage().getParameters().put('storeUrl', testSub.StoreURL__c); 
        ApexPages.currentPage().getParameters().put('supportPin', testAccount.SupportPin__c); 

        SupportT2LiveAgentPreChatController_Test.scc = new SupportT2LiveAgentPreChatController();
        SupportT2LiveAgentPreChatController_Test.scc.css = css;

        scc.formDeptId.value = testSupportQueue.Queue_ID__c;

        PageReference nextAction = scc.submitCase();

        System.assertEquals(null, nextAction);

    }

    static testMethod void myValueAndErrorTest() {
        SupportT2LiveAgentPreChatController_Test.setUp();
        
        SupportT2LiveAgentPreChatController.ValueAndError testValueAndError= new SupportT2LiveAgentPreChatController.ValueAndError();
        testValueAndError.value =  'value';
        testValueAndError.error = 'error';
        System.assertEquals(testValueAndError.value,  'value');
        System.assertEquals(testValueAndError.error, 'error');
        System.assertEquals(testValueAndError.isEmpty(), false);
        System.assertEquals(testValueAndError.getHasError(), true);

        testValueAndError.error = null;
        System.assertEquals(testValueAndError.getHasError(), false);

    }

    static testMethod void myIDValueAndErrorTest() {
        SupportT2LiveAgentPreChatController_Test.setUp();

        SupportT2LiveAgentPreChatController.IDValueAndError testIDValueAndError = new SupportT2LiveAgentPreChatController.IDValueAndError();
                
        testIDValueAndError.error = 'error';               
        System.assertEquals(testIDValueAndError.error, 'error');
        System.assertEquals(testIDValueAndError.isEmpty(), true);
        System.assertEquals(testIDValueAndError.getHasError(), true);

        testIDValueAndError.error = null;
        System.assertEquals(testIDValueAndError.getHasError(), false);
    }

    static testMethod void myFormUrlFormatterTest() {
        SupportT2LiveAgentPreChatController_Test.setUp();

        //formURLFormatter UNIT Testing
        scc.formURLFormatter('http://testingStorebigcommerce/');
        scc.formURLFormatter('https://testingStorebigcommerce/');
        scc.formURLFormatter('www.https://testingStorebigcommerce/');
    }

    static testMethod void mySupportT2LiveAgentPreChatController_Test() {
        SupportT2LiveAgentPreChatController_Test.setUp();

        String fullUrl = 'http://' + testSub.StoreURL__c;
        List<Subscription__c> testSubList = [SELECT Id, Account__c, Account__r.OwnerId, Contact__c, Lead__c, Support_PIN__c, StoreURL__c, Email__c FROM Subscription__c
                                                WHERE Support_PIN__c = :testSub.Support_PIN__c AND (StoreURL__c = :testSub.StoreURL__c OR StoreURL__c = :fullUrl)
                                                AND Status__c = 'Active' LIMIT 1];


        scc.deptName = null;
        scc.deptName ='Support';

        System.assertEquals(testSubList.isEmpty(), false);
    
    } 

    static testMethod void myValidateFileUpload(){
        SupportT2LiveAgentPreChatController_Test.setUp();
        scc.fileAtt = Blob.valueOf('Good Extension and Size');
        scc.fileName = 'test-file.txt';
        scc.fileSize = 27800;

        Boolean testUpload = scc.validateFileUpload();      
        System.assertEquals(false, testUpload);


        scc.fileAtt = Blob.valueOf('Good Size bad extension ');
        scc.fileName = 'test-file.x';
        scc.fileSize = 2780;

        Boolean testExtensionUpload = scc.validateFileUpload();        
        System.assertEquals(true, testExtensionUpload);

        scc.fileAtt = Blob.valueOf('Good extension bad size ');
        scc.fileName = 'test-file.txt';
        scc.fileSize = 5302880;

        Boolean testsizeUpload = scc.validateFileUpload();        
        System.assertEquals(true, testsizeUpload);


        PageReference currPage = Page.SubmitCase;
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'This file exceeds the maximum size limit of 10MB.'));
        Test.setCurrentPage(currPage);
        System.assertEquals(true, ApexPages.hasMessages(ApexPages.severity.ERROR));

        Boolean testsizeMaxUpload = scc.validateFileUpload(); 
        System.assertEquals(true, testsizeMaxUpload);        
        
    }   
    
    static testMethod void myCaseSubjectValidatorTest() {
        SupportT2LiveAgentPreChatController_Test.setUp();
        scc.formSubject.value = '';

        Boolean subjectHasErrors = scc.validateSubject();
        
        System.assertEquals(subjectHasErrors, true);

        scc.formSubject.value = 'test';
        subjectHasErrors = scc.validateSubject();
        System.assertEquals(subjectHasErrors, false);
    }
    
    static testMethod void myDeptTest() {
        SupportT2LiveAgentPreChatController_Test.setUp();
        
        List<SelectOption> selDept = scc.getDepts();

        System.assertEquals(selDept.size() >0, true);
    }

    static testMethod void mySaveCaseHappyPathTest() {
        SupportT2LiveAgentPreChatController_Test.setUp();

        System.debug('mySaveCaseHappyPathTest: CaseQueueRouting__c.getAll(): ' + CaseQueueRouting__c.getAll());

        // Values created during validatePin()
        scc.AcctId = testAccount.Id;
        scc.ContId = testContact.Id;
        scc.subId = testSub.Id;

        scc.formFname.value = testContact.FirstName;
        scc.formLname.value = testContact.LastName;
        scc.formPhone.value = '555-555-5555';

        // Values supplied in Form Step2
        scc.caseDescription = 'some text';
        scc.formDeptId.value = testSupportQueue.Queue_ID__c;  // 00Ga0000003ATBVEA4
        scc.css = css; 

        System.debug('mySaveCaseHappyPathTest: subId : '+scc.subId);

        System.debug('mySaveCaseHappyPathTest: deptId : '+ scc.formDeptId.value);

        System.debug('mySaveCaseHappyPathTest: css : '+ scc.css);

        PageReference nextAction =  scc.submitCase();  

        System.debug('mySaveCaseHappyPathTest: caseNum: ' + scc.caseNum); 

    }    
}