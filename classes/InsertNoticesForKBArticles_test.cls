@isTest
public class InsertNoticesForKBArticles_test {
    
    public static testmethod void test1(){
        //Instantiate an Internal Article
        Internal_Article__kav article=new Internal_Article__kav(Title='Unit Test');
        article.UrlName = 'Selling-On-eBay-Test-4455';
        article.Language = 'en_US';
        article.Article__c = 'Hi';
		insert article; 
        
        //Instantiate datacategory for the article
        Internal_Article__DatacategorySelection ds = new Internal_Article__DatacategorySelection(parentId = article.Id,dataCategoryName='News', dataCategoryGroupName='Internal_Knowledge');
        insert ds;
        
        //Setting publish notices checkbox to true so that it triggers the process builder 'KB News Internal Article Publication V3'
        article.Publish_Notices__c = true;
        update article;
    }
}