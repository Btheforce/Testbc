global class BatchNPSPopulateConData_Schedule implements schedulable {
    global void execute(SchedulableContext sc) {
      BatchNPSPopulateConData b = new BatchNPSPopulateConData(''); 
      database.executebatch(b);
   }
}