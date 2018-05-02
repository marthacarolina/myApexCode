public class Utilities {
    
    public static Map<id, RecordType> CampaignRecTypes() {
        Map<id, RecordType> recTypes = 
            new Map<id, RecordType>([select id, Name, DeveloperName 
                                     from RecordType
                                     where sObjectType = 'Campaign']);
        return recTypes;
    }
}