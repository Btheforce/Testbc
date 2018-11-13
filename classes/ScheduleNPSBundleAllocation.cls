global class ScheduleNPSBundleAllocation implements Schedulable{
    
     global void execute(SchedulableContext cxt){
        
        BatchNPSBundleAllocation job = new BatchNPSBundleAllocation();
        Database.executeBatch(job, 200);
         
    }

}