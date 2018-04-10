@isTest
public class deleteAZGivesRecs_Test {

    private static testMethod void testDelete(){
        List<Contact> conts = new List<Contact>();
        List<AZGives_Donor__c> donors = new List<AZGives_Donor__c>();
        //make contacts
        for (Integer i = 0; i < 30; i++){
            Contact c = new Contact(LastName = 'Ln'+i,
                                    FirstName = 'Fn'+i,
                                    Email = 'person'+i+'@gmail.com');
            conts.add(c);            
        }
        insert conts;
        //make donors
        for (Integer i = 0; i < 15; i++){
            Boolean inv = false;
            If (i>9) inv = true;
            AZGives_Donor__c d = 
                new AZGives_Donor__c(Amount__c = i * 10, 
                                     Transaction_Date_Time__c = datetime.newInstance(2018, 4, 3),
                                     Anonymous__c = 'No', 
                                     FirstName__c = 'Fn' + i, 
                                     LastName__c = 'Ln' + i, 
                                     Email__c = 'person'+i+'@gmail.com', 
                                     Phone_Number__c = i+'5'+i+'5',
                                     Address_1__c = i + ' street', 
                                     Address_2__c = '', 
                                     City__c = 'Phoenix', 
                                     State__c= 'AZ', 
                                     Country__c = '',
                                     Zip_Code__c = '85300', 
                                     Cover_Fees_Txt__c = 'Yes', 
                                     In_Memory__c = 'Jesus', 
                                     Comments__c = 'Have a nice Day', 
                                     Get_Involved__c = inv,
                                     Campaign_Name__c = '');
            donors.add(d);
        }
        insert donors;
        
        deleteAZGivesRecs.resetRecords();
        deleteAZGivesRecs.deleteRecords();
        Integer theTotal = [select count() from AZGives_Donor__c];
        system.assertEquals(0, theTotal);
    }
}