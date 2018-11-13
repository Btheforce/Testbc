/**
 * Updated all method singantures  
 * @updatedBy Alakh Biniwale
 * @date   10/08/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-8237
 */
@isTest
private class brEmailNotificationTest {

    @testSetup
    static void setup(){

        User testUser = brTestDataFactory.createTestStandardProfileUser();

        System.assertEquals('sysuserbaker@test.com', testUser.UserName, 'wrong username');


        System.runAs(testUser) {

            //Inline initialization 
            List<brLghtIdeasSettings__c> communitySettings = new List<brLghtIdeasSettings__c>
            {
                new brLghtIdeasSettings__c(Name = 'community', Value__c = 'TestPublic'), 
                new brLghtIdeasSettings__c(Name = 'orgwide_email_id', Value__c = '')
                    
           };

            insert communitySettings;

            String cId = brLghtIdeasHelper.getCommunityId('');
            system.debug('-33 ' + cId);
            Idea testIdea = new Idea(Title = 'Test idea_1', Body = 'Body of test idea_1', Status = 'New', Categories = 'test_1',
                    CommunityId = cId);
            insert testIdea;

            IdeaComment comment = new IdeaComment(CommentBody = 'First comment', IdeaId = testIdea.Id);

            insert comment;

            testIdea = [SELECT Title FROM Idea WHERE Id = :testIdea.Id];
            comment = [SELECT IdeaId FROM IdeaComment WHERE Id = :comment.Id];

            System.assertEquals('Test idea_1', testIdea.Title);
            System.assertEquals(testIdea.Id, comment.IdeaId);
        }
    }

    @isTest
    private static void testAddIdeaCreatedNotification(){
        User testUser = [SELECT Id, UserName FROM User WHERE UserName = 'sysuserbaker@test.com'];

        Test.startTest();

        System.runAs(testUser) {

            Integer elogNumOriginal = [SELECT COUNT() FROM brTestEmail__c];

            Idea testIdea = [SELECT Status, Title, Body, CommunityId, CreatorName FROM Idea LIMIT 1];

            brEmailNotification en = new brEmailNotification();
            
            //Added to fix soql 101 bad practice BAP-8237 Alakh Biniwale
        	EmailTemplate templateAssignee = new EmailTemplate();
        	templateAssignee = en.getEmailTemplate('NewIdeaNotificationToCategoryAssignee');
            
            //Added to fix soql 101 bad practice BAP-8371 Alakh Biniwale
        	String orgWideEmailAddressId = brLghtIdeasHelper.getConfigValue('orgwide_email_id');

            en.addIdeaCreatedNotification(UserInfo.getUserEmail(), testIdea, templateAssignee, orgWideEmailAddressId);
            en.sendEmails();

            Integer elogNum = [SELECT COUNT() FROM brTestEmail__c];

            System.assertEquals(elogNumOriginal + 1, elogNum);
        }

        Test.stopTest();
    }

    @isTest
    private static void testAddNewCommentNotification(){
        User testUser = [SELECT Id, UserName FROM User WHERE UserName = 'sysuserbaker@test.com'];

        Test.startTest();

        System.runAs(testUser) {

            Integer elogNumOriginal = [SELECT COUNT() FROM brTestEmail__c];

            Idea testIdea = [SELECT Id FROM Idea LIMIT 1];
            IdeaComment comment = [
                    SELECT CommentBody, Idea.CommunityId, Idea.Title
                    FROM IdeaComment
                    WHERE IdeaId = :testIdea.Id
                    LIMIT 1
            ];

            brEmailNotification en = new brEmailNotification();

            //Added to fix soql 101 bad practice BAP-8237 Alakh Biniwale
        	EmailTemplate templateSubscriber = new EmailTemplate();
        	templateSubscriber = en.getEmailTemplate('NewCommentNotificationToSubscriber');
            
            //Added to fix soql 101 bad practice BAP-8237 Alakh Biniwale
            EmailTemplate templateAssignee = new EmailTemplate();
        	templateAssignee = en.getEmailTemplate('NewCommentNotificationToCategoryAssignee');
            
            //Added to fix soql 101 bad practice BAP-8371 Alakh Biniwale
        	String orgWideEmailAddressId = brLghtIdeasHelper.getConfigValue('orgwide_email_id');
            
            en.addNewCommentNotification1(UserInfo.getUserEmail(), comment, templateSubscriber, orgWideEmailAddressId);
            en.addNewCommentNotification1(UserInfo.getUserEmail(), comment, templateAssignee, orgWideEmailAddressId);
            en.sendEmails();

            Integer elogNum = [SELECT COUNT() FROM brTestEmail__c];

            System.assertEquals(elogNumOriginal + 2, elogNum);
        }

        Test.stopTest();
    }

    @isTest
    private static void testAddStatusChangeNotification(){
        User testUser = [SELECT Id, UserName FROM User WHERE UserName = 'sysuserbaker@test.com'];

        Test.startTest();

        System.runAs(testUser) {

            Integer elogNumOriginal = [SELECT COUNT() FROM brTestEmail__c];

            Idea testIdea = [SELECT Status, Title, Body, CommunityId FROM Idea LIMIT 1];

            brEmailNotification en = new brEmailNotification();
            
 			//Added to fix soql 101 bad practice BAP-8237 Alakh Biniwale
            EmailTemplate templateSubscriber = new EmailTemplate();
        	templateSubscriber = en.getEmailTemplate('ChangeStatusNotificationToSubscriber');
            
            //Added to fix soql 101 bad practice BAP-8237 Alakh Biniwale
            EmailTemplate templateAssignee = new EmailTemplate();
            templateAssignee = en.getEmailTemplate('ChangeStatusNotificationToCategoryAssignee');
            
            //Added to fix soql 101 bad practice BAP-8371 Alakh Biniwale
        	String orgWideEmailAddressId = brLghtIdeasHelper.getConfigValue('orgwide_email_id');

            en.addStatusChangeNotification1(UserInfo.getUserEmail(), testIdea, 'OldStatus', templateSubscriber, orgWideEmailAddressId);
            en.addStatusChangeNotification1(UserInfo.getUserEmail(), testIdea, 'OldStatus', templateAssignee, orgWideEmailAddressId);
            en.sendEmails();

            Integer elogNum = [SELECT COUNT() FROM brTestEmail__c];

            System.assertEquals(elogNumOriginal + 2, elogNum);

            Test.stopTest(); 
        }
    }
}