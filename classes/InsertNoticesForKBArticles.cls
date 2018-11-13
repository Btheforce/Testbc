/***************************************************************************************************************************************
@Author : Sruthi Kattula
@Date Created : 3/27/2018
@JIRA : BAP - 6831 
@description : Notices are created whenever Internal news articles have 'Publish Notices' checkbox checked. This method will be invoked from process builder
			   This would be sent to these roles:
                   1.Client Success Manager
                   2.Client Success Rep
                   3.Client Success Escalation Team
@invoked by : Process Builders - KB Internal News Article Publication V2
@History 
VERSION 	AUTHOR   		DATE       	DETAIL
1.0			Sruthi K		3/27/2018	BAP - 6831
2.0			Sruthi K		4/13/2018	BAP - 6831 : Modified to accomodate the logic 'Create Notices for a published internal news article
3.0			Sruthi K		4/24/2018	BAP - 6831 : Modified the logic to capture article content into notice 'detail' field. 
***************************************************************************************************************************************/
public class InsertNoticesForKBArticles {
    public static final String PREFIX_INTERNAL = 'kA0';
    
    @InvocableMethod(label='insertNoticesForKBArticles' description='inserts notices')
    public static void insertNotices(List<Id> insertedArticlesId){
        List<ID> publicArticleIds = new List<ID>();
        List<ID> internalArticleIds = new List<ID>();
        List<ianb__Notice__c> noticeResult = new List<ianb__Notice__c>();
        for(Id eachId : insertedArticlesId){
            if(String.valueOf(eachId).startsWithIgnoreCase(PREFIX_INTERNAL)){
                internalArticleIds.add(eachId);
            }
        }
        if(internalArticleIds != null && internalArticleIds.size() > 0){
            noticeResult.addAll(insertNoticesForInternalArticles(internalArticleIds));
        }
        if(noticeResult != null && noticeResult.size() >0 ){
            database.insert(noticeResult);
            system.debug('Inserted the notices');
        }
    }
    
    public static List<ianb__Notice__c> insertNoticesForInternalArticles(List<Id> insertedArticlesId){
        system.debug('insertNoticesForInternalArticles');
        List<Internal_Article__kav> insertedArticles = [select Id,Title,PublishStatus,Article__c, (select Id, dataCategoryName, dataCategoryGroupName from DatacategorySelections) from Internal_Article__kav where Id =: insertedArticlesId];
        List<ianb__Notice__c> noticeList = new List<ianb__Notice__c>();
        //**checking to see if article is of 'news' datacategory
        for(Internal_Article__kav kv : insertedArticles){
            system.debug('Inside the loop for inserted articles');
            //if(kv.PublishStatus.equalsIgnoreCase('online')){
                if(kv.DatacategorySelections != null){
                    for(Internal_Article__DatacategorySelection ds : kv.DatacategorySelections){
                        if(ds.dataCategoryName.equalsIgnoreCase('news')){
                            //**Calling create a notice method
                            system.debug('Datacategory is news');
                            ianb__Notice__c result = createNotice(kv);
                            noticeList.add(result);
                        }
                    }
                }
            //}
        }
        return noticeList;
    }
    
    public static ianb__Notice__c createNotice(Internal_Article__kav kv){ 
        //**Inserting 'Client Success' - noticeboard record if this is being called from a test class to avoid seeAllData annotation.
        if(Test.isRunningTest()){
            ianb__NoticeBoard__c nb = new ianb__NoticeBoard__c(Name = 'Client Success');
            insert nb;
        }
        //**query for the 'Client Success' noticeboard
        List<ianb__NoticeBoard__c> csNoticeBoard = [select Id from ianb__NoticeBoard__c where Name = 'Client Success'];
        //querying recipient list definition from custom mdt 'Notice_RecipientListDefinition__mdt'
        Notice_RecipientListDefinition__mdt rdl = [select List_Definition__c,MasterLabel from Notice_RecipientListDefinition__mdt where MasterLabel='CSRep_Mgr_Billing_EAM_kb'];
        //**creating notices and mapping fields accordingly
        ianb__Notice__c notice = new ianb__Notice__c();
        notice.ianb__NoticeBoard__c = csNoticeBoard[0].Id;
        //**Eg : notice.ianb__RecipientListDefinition__c = '00Gm0000001FAaXEAW"TestSruthiGroup (0:0)"GroupInternal';
        notice.ianb__RecipientListDefinition__c = rdl.List_Definition__c;
        notice.Name = kv.title;
        notice.ianb__Title__c = kv.title;
        notice.ianb__NoticeStatus__c = 'Drafted';
        notice.ianb__NoticeMode__c = 'List';
        notice.Origin__c = 'Article';
        String detailMessage = '';
        detailMessage += '<b> Details </b><br/><br/>';
        detailMessage += 'THIS NOTIFICATION WILL NOT BE UPDATED. FOR UP TO DATE INFORMATION PLEASE VISIT THE ARTICLE : ';
        detailMessage += '<a href="' + System.URL.getSalesforceBaseURL().toExternalForm()+'/'+kv.Id+ '">HERE</a>';
        detailMessage += '<br/><br/><br/><br/>';
        if(kv.Article__c != null){
            detailMessage += '<b> Article Content </b> <br/><br/>';
            detailMessage += kv.Article__c;
        }
        notice.ianb__Detail__c = detailMessage;
        notice.ianb__RequiredAction__c = 'Read and Acknowledge';
        return notice;
    }
    

}