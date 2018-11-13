/**
 * TestArticleFeedbackDeflection
 * Author: Maria Huemmer
 * Purpose: Test Class for ArticleFeedbackDeflection trigger 
 * Ticket: BAP-3927
 *
 * Updates:
 * *********
 * 
 */
@isTest
public class TestArticleFeedbackDeflection {
	
	//Create a Test Article and bring it in to the test class
    @isTest
    static void testmethod1(){
        
        //create a noticeboard
        ianb__NoticeBoard__c csNoticeBoard = new ianb__NoticeBoard__c(Name='Client Success');
        insert csNoticeBoard;
        
        //Instantiate a Public Article
        Public__kav article=new Public__kav(Title='Unit Test');
        article.UrlName = 'Selling-On-eBay-Test10';
        //article.PublishStatus = 'Online';
        article.Language = 'en_US';
		insert article;        
        
        
        //Create a User to Set as the Author
        
        //Test Article with an Author
        
        Public__kav testArticle = new Public__kav(title = 'TestArticle', Summary = 'Article summary');
        testArticle.Author__c = userinfo.getUserId();
        testArticle.UrlName = 'Selling-On-eBay-Test1100';
        testArticle.Language = 'en_US';
        insert testArticle;
        
        //Create an Article Feedback Deflection record and test 
        
        // Get the KnowledgeArticleId
        Public__kav insertedTestArticle = [Select KnowledgeArticleId,Author__c,ArticleNumber,Language,id from Public__kav where ID = :testArticle.Id];
        
        //Publish Article
        KbManagement.PublishingService.publishArticle(insertedTestArticle.KnowledgeArticleId,true);
        
        PKB_Article_Feedback_Deflection__c af = new PKB_Article_Feedback_Deflection__c();
        af.Article_ID__c = insertedTestArticle.id;
        af.Article_Number__c = insertedTestArticle.ArticleNumber;
        insert af;
    }
    
    @isTest
    static void testmethod2(){
        //create a noticeboard
        ianb__NoticeBoard__c csNoticeBoard = new ianb__NoticeBoard__c(Name='Client Success');
        insert csNoticeBoard;
        
        //Instantiate an Internal Article
        Internal_Article__kav article=new Internal_Article__kav(Title='Unit Test');
        article.UrlName = 'Selling-On-eBay-Test-4455';
        //article.PublishStatus = 'Online';
        article.Language = 'en_US';
		insert article; 
    }
    
}