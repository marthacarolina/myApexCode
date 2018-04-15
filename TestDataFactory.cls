@isTest
public class TestDataFactory {
    
    public static List<Contact> CreateContacts(integer totContacts, integer startIndex){
        List<Contact> conts = new List<Contact>();  
        for (Integer x=startIndex; x<totContacts + startIndex; x++){
            Contact cont1 = new Contact(FirstName = 'Contact' + x,
                                        LastName = 'Test'+ x,
                                       email = 'contactTest'+x+'@testing.com');
            conts.add(cont1);
        }
        insert conts;
        return conts;
    }
    
    public static id CreateFee(String cType, Decimal amount)
    {             
        //insert fee for the campaign
        Fee__c fee = new Fee__c (Activity_Type__c = cType,
                                Amount__c = amount);                               
        insert fee;
        return fee.id;
    }
    
    public static void CreateGAU (String gauName) //
    {
        //insert the general accounting unit used for the opportunities
        npsp__General_Accounting_Unit__c genAcUnit = 
            new npsp__General_Accounting_Unit__c (Name = gauName,
                                                 npsp__Active__c = true);
        insert genAcUnit;      
    }
    
    public static void CreateCMStatusDefault(String ctype)
    {
        //AAKCS__Campaign_Status_Default__c statDef = 
        //    new AAKCS__Campaign_Status_Default__c (Name = ctype,
        //                                           AAKCS__Action__c = 'Replace All',
        //                                           AAKCS__Active__c = true);
        //insert statDef;
        //insert the Status defaults for the Campaign Members for this type of campaign
        //List<String> defNames = new List<String>{'Attended', 'Signed Up', 'Cancelled', 'No-Show', 'Staff', 'Waiting list'};
        //List<Boolean> stDef = new List<Boolean>{false, true, false, false, false, false};
        //List<Boolean> stResp = new List<Boolean>{true, true, false, false, false, false};
        //List<AAKCS__Campaign_Status_Default_Value__c> sdValues =
        //    new List<AAKCS__Campaign_Status_Default_Value__c> ();
        //for (integer x = 0; x < defNames.size(); x++)
        //{
        //    AAKCS__Campaign_Status_Default_Value__c sdValue =
        //    new AAKCS__Campaign_Status_Default_Value__c(Name = defNames[x],
        //                                                AAKCS__Default__c = stDef[x],
        //                                                AAKCS__Responded__c = stResp[x],
        //                                                AAKCS__Campaign_Status_Default__c = statDef.id);
        //    sdValues.add(sdValue);
        //}
        //insert sdValues;        
    }
    
    public static void CreateCampaigns(String cName, String recType, String ctype, integer totCamp, integer startIndex, Date sDate, Date eDate, Id fee)
    {
        //get record type ids
        Map<String, id> recTypeIds = new Map<String, id>();
        List<RecordType> recs = [select id, Name, DeveloperName from RecordType
                                where sObjectType = 'Campaign'];
        for (RecordType rt : recs)
            recTypeIds.put(rt.DeveloperName, rt.id);  
        // insert campaigns
        List<Campaign> myCampaigns = new List<Campaign>();
        for (Integer i=startIndex; i< totCamp + startIndex; i++){
            Campaign aCampaign = new Campaign(RecordTypeId = recTypeIds.get(recType),
                                             Name = cName + i,
                                             IsActive = True,
                                             Type = ctype,
                                             Fee_for_Activity__c = fee, 
                                             Status = 'Planned',
                                             EndDate = eDate,
                                             StartDate = sDate);
            myCampaigns.add(aCampaign);
        }
        insert myCampaigns;                                     
    }
    
    public static void CreateCampaignMembers(List<Campaign> campaigns, List<Contact> contacts, Integer contsInCamp, List<String> stats)
    {
        List<CampaignMember> theCMs = new List<CampaignMember>();
        if (contacts.size() < stats.size())
            system.debug('Not enough contacts, or too many statuses');
        else
        {
            Integer z = 0;
            for(Campaign c : campaigns)
            {
                Integer startIndex = z;
                Integer statusIndex = 0;
                for (Integer x=z; x < startIndex + contsInCamp; x ++)
                {
                    Integer y = statusIndex < stats.size() ? statusIndex : stats.size() - 1;
                    CampaignMember aCamMember = new CampaignMember(CampaignId = c.id,
                                                                   ContactId = contacts[x].id,
                                                                   Status = stats[y]);
                    theCMs.add(aCamMember);
                    z++; statusIndex++;
                }
            }
            insert theCMs;
        }
    }
    
    public static void CreateJobShift(List<Campaign> camps)
    {
        List<GW_Volunteers__Volunteer_Job__c> jobs = 
            new List<GW_Volunteers__Volunteer_Job__c>();
        Map<id, Date> cDates = new Map<id, Date>();
        for (Campaign c : camps)
        {
            GW_Volunteers__Volunteer_Job__c job = new GW_Volunteers__Volunteer_Job__c(
                GW_Volunteers__Campaign__c = c.Related_Campaign__c,
                GW_Volunteers__Description__c = 'description for campaign',
                GW_Volunteers__Location_City__c = 'PHoenix',
                GW_Volunteers__Location_Information__c = 'info',
                GW_Volunteers__Location__c = 'location',
                GW_Volunteers__Location_Street__c = 'street');
            jobs.add(job);
            cDates.put(c.Related_Campaign__c, c.StartDate);
        }
        insert jobs;
        List<GW_Volunteers__Volunteer_Shift__c> shifts = new List<GW_Volunteers__Volunteer_Shift__c>();
        time sTime = time.newInstance(8, 30, 0, 0);
        for (GW_Volunteers__Volunteer_Job__c job : jobs)
        {
            Date sDate = cDates.get(job.GW_Volunteers__Campaign__c);
            GW_Volunteers__Volunteer_Shift__c shift = new GW_Volunteers__Volunteer_Shift__c(
                GW_Volunteers__Desired_Number_of_Volunteers__c = 4,
                GW_Volunteers__Duration__c = 3,
                GW_Volunteers__Start_Date_Time__c = DateTime.newInstance(sDate, sTime),
                GW_Volunteers__Volunteer_Job__c = job.id);
            shifts.add(shift);
        }
        insert shifts;
    }
}