@isTest
public class RandomizerTest {
	
    @isTest 
    static void testRandom() {
          test.startTest();
          Integer testInt = Randomizer.getRandomNumber(10);
          Boolean testBool = Randomizer.getRandomBoolean();
          List<String> testStringList = new List<String>();
          testStringList.add('one');
          testStringList.add('two');
          testStringList.add('three');
          String testString = Randomizer.getRandomString(testStringList);
          String testPlaceholder = Randomizer.getPlaceholderText(10);
          test.stopTest();
     }
    
}