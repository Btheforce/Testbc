/** 
 * @author Alakh Biniwale
 * @date 04/30/2018
 * @description PickList Utility Class
 */
public class PickListUtils {

    /** 
 	 * @author Alakh Biniwale
     * @date 04/30/2018
     * @description Return List of picklist values for given sObjectType and fieldName
     */
    public static List<String> getPickListValues(Schema.sObjectType objType, string fieldName){
        
        List<String> allValues = new List<String>();
        
        // Describe the SObject using its object type.
  		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        
        // Get a map of fields for the SObject
  		Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Get the list of picklist values for this field.
  	    List<Schema.PicklistEntry> values = fieldMap.get(fieldName).getDescribe().getPickListValues();
        
        // Add these values to the selectoption list.
  		for (Schema.PicklistEntry a: values) {
   			allValues.add(a.getValue());
  		}
        
        allValues.sort();
        
        return allValues;
    }
    
    /** 
 	 * @author Alakh Biniwale
     * @date 04/30/2018
     * @description Return Map<Key, Value> for given sObjectType and fieldName
     */
    public static Map<String, String> getPickListLabelMap(Schema.sObjectType objType, string fieldName){
        
         Map<String, String> labelMap = new Map<String, String>();
        
        // Describe the SObject using its object type.
  		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        
        // Get a map of fields for the SObject
  		Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Get the list of picklist values for this field.
  	    List<Schema.PicklistEntry> values = fieldMap.get(fieldName).getDescribe().getPickListValues();
        
        // Add these values to the selectoption list.
  		for (Schema.PicklistEntry a: values) {
   			labelMap.put(a.getValue(), a.getLabel());
  		}
                
        return labelMap;
        
    }
    
    /** 
 	  * @author Alakh Biniwale
      * @date 04/30/2018
      * @description Return Map<fieldName, values> of all picklists and multiselect picklist for given sObjectType
      */
    public static Map<String,List<String>> getPickListFieldValuesMap(Schema.sObjectType objType){
        
     	Map<String,List<String>> FieldValuesMap = new Map<String,List<String>>();
        
		// Describe the SObject using its object type.
  		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        
        // Get a map of fields for the SObject
  		Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for(String fieldName : fieldMap.keyset()){
              
        	List<String> allValues = new List<String>();
              
            //Get Field Describe
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
              	
            //Check field is Picklist or MultiPicklist
            if(dfr.GetType() == Schema.DisplayType.Picklist 
               	|| dfr.GetType() == Schema.DisplayType.MultiPicklist){
                        
         	// Get the list of picklist values for this field.
  	   		List<Schema.PicklistEntry> values = fieldMap.get(fieldName).getDescribe().getPickListValues();
                   
            // Add these values to the selectoption list.
  			for (Schema.PicklistEntry a: values) {
   				allValues.add(a.getValue());
  			}	
                   
            allValues.sort();
                        
            FieldValuesMap.put(String.valueOf(fieldMap.get(fieldName)), allValues);
                    
            }
        }
        
        return FieldValuesMap;
     }
    
    /** 
 	 * @author Alakh Biniwale
     * @date 04/30/2018
     * @description Return random single picklist value for given sObjectType and fieldName
     */
    public static string getRandomPickListValue(Schema.sObjectType objType, String fieldName){
         
       return Randomizer.getRandomString(getPickListValues(objType, fieldName));
         
     }
}