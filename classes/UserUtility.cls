public  class UserUtility {
	
   public static boolean isSSOinProgress;
    public static void AddCommunityUserToGroup(list<ID> cUsers) 
    {
       try {

            Integer matches = Label.Community_Chatter_Groups.countMatches(';');
			List<String> groups = new List<String>();

           /**
            * Fix for missing Collaboration Group in sandbox tests
            * @author Steve O'Neal
            * @date   2018-05-11
            * @ticket link       https://jira.bigcommerce.com/browse/BAP-7278
            */
            if (Test.isRunningTest())
            {
                Network bcNetwork = [Select Id from Network where name = 'BigCommerce Community' limit 1];
                CollaborationGroup cg = new CollaborationGroup(Name = 'New Group', CollaborationType = 'Public', NetworkId = bcNetwork.Id);
                insert cg;
                groups.add(cg.Id);
            }
            else
            {
                Label.Community_Chatter_Groups.split(';',matches+1);
            }
			system.debug('first string' +groups[0]);
			
            List<CollaborationGroupMember> cgm = new List<CollaborationGroupMember>();
                                    
            for( Id userId : cUsers)
            {       
            	for (string s :groups)
            	{                   
            		system.debug(s);
               		cgm.add(new CollaborationGroupMember (CollaborationGroupId = s, MemberId = userId));   
            	}
            } 
            insert cgm;
        }
        catch (QueryException qe) {
            System.debug('QueryException in AddCommunityUserToGroup is :' + qe);  
        } 
        catch (Exception ex) {
            System.debug('Exception in AddCommunityUserToGroup is :' + ex);
        }    
    }
    
    //Update the Contact of the Community user
    //@Author: Bala Rajagopal
    //@ticket: PROJECT-1366
    @future
    public static void updateCommunityUserContact(set<Id> userIds){
        Map<Id,User> mapContactIdtoUser = new Map<Id,User>();
        List<Contact> conList = new List<Contact>();
        List<User> commUsers = new List<User>([select id,username,FirstName,LastName,contactid from User where Id IN :userIds]);
        
        //Ensure this is not happening in the SSO context
        if(isSSOinProgress==null || !isSSOinProgress){
            conList = [select id from Contact where Id IN (select contactid from User where isPortalEnabled = TRUE AND Id IN :userIds)];
            for(User usr:commUsers){
                mapContactIdtoUser.put(usr.contactid, usr);
            }
            for(Contact con:conList){
                con.FirstName = mapContactIdtoUser.get(con.id).FirstName;
                con.LastName = mapContactIdtoUser.get(con.id).LastName;
            }
            if(!conList.isEmpty()){
                try{
                   update conList; 
                } catch(exception e){
                    system.debug('>><< Contact update failed after User Insert: '+e.getMessage());
                }	
        	}
        }     
    }

}