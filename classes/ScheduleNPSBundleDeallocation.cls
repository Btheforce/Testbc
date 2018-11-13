global class ScheduleNPSBundleDeallocation implements Schedulable{

    global void execute(SchedulableContext cxt){
        
        BatchNPSBundleDeallocation job = new BatchNPSBundleDeallocation();
        Database.executeBatch(job, 2000);
         
    }
}