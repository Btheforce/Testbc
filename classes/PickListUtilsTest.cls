/**
  * @description Test Class for PickListUtils
  * @author Alakh Biniwale
  * @date   04/30/2018
  */
@isTest
public class PickListUtilsTest {

    @isTest static void testPickListMethods(){
        
      List<String> values =  PickListUtils.getPickListValues(Account.sObjectType, 'Type');
      Map<String, List<String>> FieldValuesMap = PickListUtils.getPickListFieldValuesMap(Account.sObjectType);
      String randomValue = PickListUtils.getRandomPickListValue(Account.sObjectType, 'Type');
      Map<String, String> labelMap = PickListUtils.getPickListLabelMap(Account.sObjectType, 'Type');
    }
}