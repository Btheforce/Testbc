@isTest
public class PurgingBatch_test {
    
static testMethod void testMethod1() 
    {
        RecordType rectype = [select Id from RecordType where sObjecttype ='Account' and name='Client Record Type'];
        List<account> ac = TestDataFactory.createTestAccounts(1, false, rectype);
        String query = 'select Id from Account';
        test.startTest();
        PurgingBatch pBatch = new PurgingBatch(query);
        database.executeBatch(pBatch);
        test.stopTest();
        List<Account> acc1 = [select Id from Account where Id=: ac[0].Id];
        system.assertEquals(0,acc1.size());
    }
}