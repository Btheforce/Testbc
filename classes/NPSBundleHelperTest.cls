/**
 * Test class to cover NPSBundleHelper
 * @author Alakh Biniwale
 * @date   07/16/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7588
 */
@isTest(isParallel = true)
public class NPSBundleHelperTest {

    
    @isTest
    static void NPSBundleTest(){
        
        List<NPS_Bundle__c> npsBundleList = NPSBundleHelper.generateNPSBundles();
        
        NPSBundleHelper helper = new NPSBundleHelper();
        helper.getNpsBundles();
        Date fromDate = helper.getCurrentNpsStartDate();
        DateTime fromDateTime = helper.getCurrentNpsStartDate();
        helper.getCurrentNpsEndDate();
        helper.getCurrentNpsTotalDays();
        helper.getNextNpsStartDate();
        helper.getNextNpsEndDate();
        helper.getValidNpsDate(fromDate, 10);
        helper.getValidNpsDateTime(fromDateTime, 10);
        helper.getNextValidNpsDate(fromDate);

    }
    
}