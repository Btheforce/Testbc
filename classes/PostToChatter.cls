/**
* Utility class to post to Chatter from a "Post to Chatter" field. 
* Intended to be run before inserts and before updates.
* @author		Ezra Kenigsberg
* @date			2018-08-01
* @param		List<Case> lstPostToChatter, a List of Cases with non-null "Post to Chatter" fields		
* @ticket link	https://jira.bigcommerce.com/browse/BAP-7803
*/
public class PostToChatter {
    // this procedure adapted from http://bit.ly/postfeedelementbatch (the Apex Developer 
    // Guide article "Post a Batch of Feed Elements"). Here's the object hierarchy:
	// 1) the list of BatchInputs ("lstBI") is built of 
    // 2) individual BatchInputs ("bi"), which is built from 
	// 3) a FeedItemInput ("fii"), which is built from 
	// 4) a MessageBodyInput ("mbi"), which is built from
	// 5) individual MessageSegments, which are built using ConnectApiHelper's 
	//    getMessageSegmentInputs() method breaking down the Post_to_Chatter__c field
    public static void postRich(List<Case> lstPostToChatter){
        // create List of Batch Inputs to be posted to Chatter
        List<ConnectApi.BatchInput> lstBI = new List<ConnectApi.BatchInput>();
        for (Case cas : lstPostToChatter) { // iterate through lstPostToChatter
            ConnectApi.FeedItemInput fii = new ConnectApi.FeedItemInput();
            fii.subjectId = cas.Id;
            ConnectApi.MessageBodyInput mbi = new ConnectApi.MessageBodyInput();
            // change <br> tags into <p></p>. ConnectApiHelper.getMessageSegmentInputs()
            // can't handle <br> tags.
            String str = cas.Post_to_Chatter__c.replace('<br>', '<p></p>');
            // use ConnectApiHelper.getMessageSegmentInputs() to handle 
            // the "Post to Chatter" field's RICH TEXT 
            mbi.messageSegments = ConnectApiHelper.getMessageSegmentInputs(str);
            fii.body = mbi;
            // create the Batch Input rec and add it to lstBI
            ConnectApi.BatchInput bi = new ConnectApi.BatchInput(fii);
            lstBI.add(bi);
        }    
		// batchpost lstBI
        ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), lstBI);
    }
}