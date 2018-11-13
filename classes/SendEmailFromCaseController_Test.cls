/**
 * SendEmailFromCaseController_Test
 * Author: Bala Rajagopal
 * Purpose: Test Class for the SendEmailFromCaseController Controller
 * Ticket: BAP-5604
 * 
 */
@isTest
private class SendEmailFromCaseController_Test
{
	static testmethod void myTest()
	{
        TestDataGenerator td = new TestDataGenerator();
      
      	list<Account> lstAcct = td.getAccounts(true);
      
        // Create a new case for the account
        Case cs = td.createCase(lstAcct[0].Id, 'Support', true);
          
        // Make sure the case is associated to the correct account
        cs.AccountId = lstAcct[0].Id;
        update cs;
		Id RecordTypeIdMacro = Schema.SObjectType.Macro.getRecordTypeInfosByName().get('Client Success').getRecordTypeId();
        List<Macro> mcList = new List<Macro>();
        Macro mc1 = new Macro(name='Propose a Solution',RecordTypeId=RecordTypeIdMacro);
        mcList.add(mc1);
        Macro mc2 = new Macro(name='Ask for more info',RecordTypeId=RecordTypeIdMacro);
        mcList.add(mc2);
        Macro mc3 = new Macro(name='Providing Info, Closing',RecordTypeId=RecordTypeIdMacro);
        mcList.add(mc3);
        Macro mc4 = new Macro(name='Escalate the case',RecordTypeId=RecordTypeIdMacro);
        mcList.add(mc4);
        insert mcList;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(cs);
		SendEmailFromCaseController controller = new SendEmailFromCaseController(sc);
        
		test.startTest();
        	system.assertNotEquals(null, controller.ProposeSolutionMacroId);
        	system.assertNotEquals(null, controller.AskforMoreInfoMacroId);
        	system.assertNotEquals(null, controller.ProvideInfoCloseMacroId);
		test.stopTest();
	}
}