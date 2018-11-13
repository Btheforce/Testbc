/** 
 * @author Alakh Biniwale
 * @date 04/30/2018
 * @description Random generator Utility Class
 */
public class Randomizer{

     /** 
 	  * @author Alakh Biniwale
      * @date 04/30/2018
      * @description returns a random Integer
	  */
     public static Integer getRandomNumber(Integer size){
          Double d = math.random() * size;
          return d.intValue();
     }

     /** 
 	  * @author Alakh Biniwale
      * @date 04/30/2018
      * @description returns either true or false randomly
	  */
     public static Boolean getRandomBoolean(){
          if(math.mod(getRandomNumber(10),2) == 0){
               return true;
          }
          else{
               return false;
          }
     }

     /** 
 	  * @author Alakh Biniwale
      * @date 04/30/2018
      * @description returns a random value from a list of strings
	  */
     public static String getRandomString(List<String> strings){
          List<Double> ranks = new List<Double>();
          Map<Double,String> rankMap = new Map<Double,String>();

          for(String s : strings){
               Boolean isDup = true;
               Double rank;

               While(isDup){
                    Double x = getRandomNumber(100000);
                    if(!rankMap.containsKey(x)){
                         rank = x;
                         isDup = false;
                    }
               }

               ranks.add(rank);
               rankMap.put(rank,s);
          }

          ranks.sort();
          return rankMap.get(ranks.get(0));
     }
    
     /** 
 	  * @author Alakh Biniwale
      * @date 04/30/2018
      * @description returns Lorem Ipsum placeholder text
	  */
     public static String getPlaceholderText(Integer length){
          String firstSentence = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ';
          List<String> sentenceList = new List<String>();
          sentenceList.add('Vivamus nec lacus eget massa cursus pulvinar. ');
          sentenceList.add('Morbi vel odio eget nunc auctor posuere eget eget ante. ');
          sentenceList.add('Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. ');
          sentenceList.add('Pellentesque lacus eros. ');
          sentenceList.add('Sed suscipit tristique varius. ');
          sentenceList.add('Mauris ultricies, nibh eu fermentum accumsan, justo quam pulvinar tellus, sed tempor quam eros sit amet ante. ');
          sentenceList.add('Duis mi libero, cursus nec facilisis ut, commodo eget nunc. ');
          sentenceList.add('Nulla eros augue, iaculis sed volutpat et, sagittis quis sem. ');
          sentenceList.add('Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla placerat accumsan vulputate. ');
          sentenceList.add('Fusce placerat tellus eget tellus faucibus a gravida sapien fermentum. ');

          String s = firstSentence;

          while (s.length() < length+1){
               s += getRandomString(sentenceList);
          }

          s = s.trim();

          while (s.length() >= length-1){
               s = s.substring(0,s.length()-1).trim();
          } 

          s = s.substring(0,s.length()-1).trim();
          s += '.';
          return s;
     }

}