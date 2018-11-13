/**
 * Helper class to provide utility methods related to NPS Bundle
 * @author Alakh Biniwale
 * @date   07/16/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7588
 */
public class NPSBundleHelper {
    
	public Map<Id, NPS_Bundle__c> npsBundleMap;     
    
    public Set<Date> removeDates;

    public NPSBundleHelper(){
                
        removeDates = new Set<Date>();
        
        for(Federal_Holiday__mdt rmdate : [SELECT Holiday_Date__c FROM Federal_Holiday__mdt WHERE Disable__c = false]){
            
            removeDates.add(rmdate.Holiday_Date__c);
        }
                
        npsBundleMap = new Map<Id, NPS_Bundle__c>([SELECT Id, Send_Date__c, Next_Send_Date__c, Limit__c, Size__c, 
                                                   		Active__c, Previous_Bundle__c, Processed__c 
                           								FROM NPS_Bundle__c 
                          								WHERE is_complete__c != true 
                          								AND Send_Date__c >= :getCurrentNpsStartDate()
                          								AND Send_Date__c <= :getCurrentNpsEndDate() 
                                                   		order by Send_Date__c ASC]);   
    }

    //Need to refactor in future -- Temp 
    public static List<NPS_Bundle__c> generateNPSBundles(){
        
        //Get Days for firstHalf and secondHalf of the year
        Integer numDays, FirstHalfDays, SecondHalfDays;
        NPS_Date_Setting__mdt firstHalf, SecondHalf;
        
        for(NPS_Date_Setting__mdt npsDate : [SELECT Start_Date__c, End_Date__c, DeveloperName FROM NPS_Date_Setting__mdt]){
            
            if(npsDate.DeveloperName == 'First_Half_Year'){
                
                firstHalf = npsDate;
                firstHalfDays = npsDate.Start_Date__c.date().daysBetween(npsDate.End_Date__c.date());
            }
            else{
                
                SecondHalf = npsDate;
                secondHalfDays =  npsDate.Start_Date__c.date().daysBetween(npsDate.End_Date__c.date());
            }
        }
        
        numDays = (firstHalfDays <= SecondHalfDays ? firstHalfDays : SecondHalfDays);
        
        //Dates To remove
        Set<Date> removeDates = new Set<Date>();

        for(Federal_Holiday__mdt rmDate : [SELECT Holiday_Date__c FROM Federal_Holiday__mdt WHERE Disable__c = false]){
            removeDates.add(rmDate.Holiday_Date__c);
        }
        
        //Assign Dates to NPS Bundle
        List<NPS_Bundle__c> retVal = new List<NPS_Bundle__c>();
        
        for (Integer i = 0, j = 0; i < numDays;)
        {
            
            NPS_Bundle__c bundle = new NPS_Bundle__c();
            bundle.Size__c = 0;
            bundle.Processed__c = 0;
            bundle.Failed__c = 0;
            
            do{
                
                bundle.Send_Date__c = SecondHalf.Start_Date__c.addDays(i);
                if(bundle.Send_Date__c.date() < Date.today()){
                    bundle.Is_Complete__c = true;
                }

                i++;
                
            }while(removeDates.contains(bundle.Send_Date__c.date()) ||bundle.Send_Date__c.format('E') == 'Sat' 
                   || bundle.Send_Date__c.format('E') == 'Sun');
            
            do{
                    
                  bundle.Next_Send_Date__c = firstHalf.Start_Date__c.addDays(j);
                  j++;
                    
                }while(removeDates.contains( bundle.Next_Send_Date__c.date()) || bundle.Next_Send_Date__c.format('E') == 'Sat' 
                   ||  bundle.Next_Send_Date__c.format('E') == 'Sun');
            
             retVal.add(bundle);
        }

        if (retVal.size() > 0)
        {
            insert retVal;
        }
        
        return retVal;
    }
    
    //return npsBundle list
    public List<NPS_Bundle__c> getNpsBundles(){
        
        return npsBundleMap.values();
    }
    
    //current nps campaign start date
    public Date getCurrentNpsStartDate(){
        
        Date startDate;
        
        if(system.today() >= date.newInstance(System.today().year(), 1, 1) && system.today() <= date.newInstance(System.today().year(), 6, 30)){
            
            startDate = date.newInstance(System.today().year(), 1, 1);
            
        } else if(system.today() >= date.newInstance(System.today().year(), 7, 1) && system.today() <= date.newInstance(System.today().year(), 12, 31)){
            
            startDate = date.newInstance(System.today().year(), 7, 1);
        }
        
        return startDate;
    }
    
    //current nps campaign end date
    public Date getCurrentNpsEndDate(){
        
        Date endDate;
        
        if(system.today() >= date.newInstance(System.today().year(), 1, 1) && system.today() <= date.newInstance(System.today().year(), 6, 30)){
            
            endDate = date.newInstance(System.today().year(), 6, 30);
            
        } else if(system.today() >= date.newInstance(System.today().year(), 7, 1) && system.today() <= date.newInstance(System.today().year(), 12, 31)){
            
            endDate = date.newInstance(System.today().year(), 12, 31);  
        }
        
        return endDate;
    }
    
    //next nps campaign start date
    public Date getNextNpsStartDate(){
        
        Date nextStartDate;
        
        	if(getCurrentNpsEndDate().isSameDay(date.newInstance(System.today().year(), 6, 30))){
                
            	nextStartDate = date.newInstance(System.today().year(), 7, 1);
        	}
        
           else if(getCurrentNpsEndDate().isSameDay(date.newInstance(System.today().year(), 12, 31))){
               
               nextStartDate = date.newInstance(System.today().year() + 1, 1, 1);
           }
          
        return nextStartDate;
    }
    
    //next nps campaign end date
    public Date getNextNpsEndDate(){
        
        Date nextEndDate;
        
        	if(getNextNpsStartDate().isSameDay(date.newInstance(System.today().year(), 7, 1))){
                
            	nextEndDate = date.newInstance(System.today().year(), 12, 31);
        	}
        
           else if(getNextNpsStartDate().isSameDay(date.newInstance(System.today().year() + 1, 1, 1))){
               
               nextEndDate = date.newInstance(System.today().year() + 1, 6, 30);
           }
          
        return nextEndDate;
        
    }
    
    //days between current nps start and end date
    public Integer getCurrentNpsTotalDays(){
        
        return getCurrentNpsStartDate().daysBetween(getCurrentNpsEndDate());        
    }
    
    //valid datetime removing weekend and federal holidays
    public DateTime getValidNpsDateTime(DateTime fromDateTime, Integer numDays){
        
        DateTime validNpsDateTime; 
        
        do{
            validNpsDateTime = fromDateTime.addDays(numDays);
            numDays++;
        
        }while(removeDates.contains(validNpsDateTime.date()) ||validNpsDateTime.format('E') == 'Sat' || validNpsDateTime.format('E') == 'Sun');
        
        return validNpsDateTime;
    }
    
    //valid date removing weekend and federal holidays
    public Date getValidNpsDate(Date fromDate, Integer numDays){
        
        DateTime validNpsDateTime; 
        
        do{
            validNpsDateTime = fromDate.addDays(numDays);
            numDays++;
        
        }while(removeDates.contains(validNpsDateTime.date()) ||validNpsDateTime.format('E') == 'Sat' || validNpsDateTime.format('E') == 'Sun');
        
        return validNpsDateTime.date();
    }
    
    //next valid date 
    public Date getNextValidNpsDate(Date fromDate){
         
        DateTime validNpsDate;
        Integer numDays = 1;
        
        do{
            validNpsDate = fromDate.addDays(numDays);
            numDays++;
            
        }while(removeDates.contains(validNpsDate.date()) ||validNpsDate.format('E') == 'Sat' || validNpsDate.format('E') == 'Sun');
            
        return validNpsDate.date();
        
    }
    
}