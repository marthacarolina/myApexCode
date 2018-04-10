public class deleteAZGivesRecs {
        
    public static void deleteRecords(){
        list <AZGives_Donor__c> donors = [SELECT id FROM AZGives_Donor__c];
        delete donors;
    }
    
    public static void resetRecords(){
        list<AZGives_Donor__c> donors = [SELECT id, Processed__c,
                                         Matched_Email__c FROM AZGives_Donor__c];
        for (AZGives_Donor__c d : donors)
        {
            d.Matched_Email__c = false;
            d.Processed__c = false;
        }
        update donors;
    }
}