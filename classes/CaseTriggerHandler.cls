/***************************************************************************************************************************************
@Author : Sruthi Kattula
@Date Created : 07/12/2018
@JIRA : BAP-7270
@description : Trigger handler class for Case (To be used in Refactor of Case Triggers)
@test-class : CaseTriggerHandlerTest
@History 
VERSION 	AUTHOR   		DATE       	DETAIL
1.0			Sruthi K		07/12/2018	BAP-7270
***************************************************************************************************************************************/
public class CaseTriggerHandler {
    
    public String constructFeedMessage(String fieldName, String oldValue, String newValue){
        String feedPostMessage = '\n The '+ fieldName +' has been updated : ';
        //feedPostMessage += '\nNew Field Name : '+ fieldName;
        //feedPostMessage += '\n Old Value : '+ oldValue;
        feedPostMessage += '\n New Value : '+ newValue;
        return feedPostMessage;
    }

}