global class ScheduleNPSEmailSend implements Schedulable{

    global void execute(SchedulableContext cxt){
        
        BatchNPSEmailSend job = new BatchNPSEmailSend();
        Database.executeBatch(job, 200);
    }
}