//test class for printMemberInfoMeds
//
//Martha Vance 2/24/18

@isTest
public class printMemberInfoMeds_Test {
    @isTest (SeeAllData='true')
    public static void printMemberInfoMeds_Test(){
        List<contact> members = [SELECT id from Contact
                                WHERE participant__c = true
                                LIMIT 5];
        for (contact mem : members)
        {
            ApexPages.StandardController std = 
                new ApexPages.StandardController(mem);
            printMemberInfoMeds controllerExt = new printMemberInfoMeds(std);
            List<Medication__c> medicines = ControllerExt.getMeds();
            Integer memMeds = [Select count() from Medication__c
                                          where Contact_meds__c = :mem.id];
            system.assertEquals(memMeds, medicines.size());
        }
        
    }

}