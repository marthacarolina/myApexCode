//Martha Vance
//Rev. April 2, 2018

public class CampaignTriggerHandler extends TriggerHandler{
    public Map<String, id> campRecType;
    
    public CampaignTriggerHandler()
    {
        //get a map of the record types for Campaign
        campRecType = getRecTypeId();
    }
    
    protected override void afterInsert() {
        //If the campaign inserted is an Adventure Campaign add the adventure campaign
        //as well as the Volunteer campaign related to it.
        AddAdventureCampaign();
    }
    
    protected override void beforeDelete() {
        //prepare the campaign record to be deleted. I will not allow the user to delete
        //a campaign that has a related Volunteer campaign, or
        //an adventure campaign that has members with Attended status
        PrepareForDeletion();
    }
    
    protected override void afterUpdate() {
        //if the dates of the Volunteer campaign has changed then change the
        //dates for the volunteer jobs and shifts associated to the campaign
        ChangeVolCampDates();
    }
    
    public void AddAdventureCampaign()
    {
        list<Campaign> aList = new List<Campaign>();
        list<Campaign> adventCampaign = new List<Campaign>();
        list<Campaign> mailChimpCampaign = new List<Campaign>();
        list<Campaign> campaignToUpdate = new List<Campaign>();
        list<Campaign> fundCampaigns = new List<Campaign>();
        //Retrieve all campaign types and their CampaignMember Status_Group
        Map<String, Campaign_Type__mdt> mapTypes = getMapOfTypes();
        //Retrieve all the possible Status for Adventure campaigns from the Custom Metadata Type CM_Status_Setting
        //and delete those status from CampaignMemberStatus
        List <CM_Status_Setting__mdt> allStatus = [select DeveloperName, MasterLabel, Default__c,
                                                   Responded__c, Order__c, Group_Number__c FROM CM_Status_Setting__mdt
                                                  ORDER BY Group_Number__c];
        Map<String, id> campRecType = getRecTypeId();
        Integer mc = 0;
        for (Campaign each : (List<Campaign>) Trigger.new)
        {
            //check that the campaign is an Adventure campaign
            if (each.RecordTypeId == campRecType.get('Adventure'))
            {
                //If it is a Mail Chimp campaign, change the record type to Fundraiser
                if (each.Name.contains('MailChimp'))
                {
                    Campaign aMCCampaign = new Campaign(id = each.id,
                                                        Name = each.name,
                                                        RecordTypeId = campRecType.get('Fundraiser'),
                                                        IsActive = each.IsActive,
                                                        Type = each.Type,
                                                        Status = each.Status,
                                                        ParentId = each.ParentId,
                                                        StartDate = each.StartDate,
                                                        EndDate = each.EndDate,
                                                        Description = each.Description,
                                                        ExpectedResponse = each.ExpectedResponse,
                                                        NumberSent = each.NumberSent,
                                                        OwnerId = each.OwnerId);
                    mailChimpCampaign.add(aMCCampaign);
                }
                else
                {
                    //Add the volunteer campaign
                    Campaign anAdvCamp = new Campaign(id = each.id,
                                                      Type = each.Type);
                    Campaign volunteerCampaign = new Campaign();
                    // Add the word volunteer to the begining of the Campaign Name
                    // to differentiate from Adventure Campaign
                    volunteerCampaign.Name = 'Volunteer ' + each.Name;
                    //Set the record type to Volunteer
                    volunteerCampaign.RecordTypeId = campRecType.get('Volunteers_Campaign');
                    //Set the related campaign with the id of the Adventure Campaign
                    volunteerCampaign.Related_Campaign__c = each.Id;
                    // Copy the rest of the information
                    volunteerCampaign.IsActive = each.IsActive;
                    volunteerCampaign.Type = each.Type;
                    volunteerCampaign.Status = each.Status;
                    volunteerCampaign.Description = each.Description;
                    volunteerCampaign.EndDate = each.EndDate;
                    volunteerCampaign.Parent  = each.Parent;
                    volunteerCampaign.StartDate  = each.StartDate;
                    //add the record to the list
                    adventCampaign.add(anAdvCamp);
                    aList.add(volunteerCampaign);
                }
            }
            //make a list of fundraising and Benevon campaigns that 
            //have Campaign Member Status other
            //than SENT and RESPONDED to assign new Campaign Member Status
            if (each.RecordTypeId == campRecType.get('Fundraising')
               || each.RecordTypeId == campRecType.get('Benevon'))
            {
                if (mapTypes.get(each.Type).Status_Group__c > 0)
                {
                    fundCampaigns.add(each);
                }                
            }               
        }
        // Add the CampaignMember Status for all the new Adventure Campaigns and
        // the new fundraising campaigns that need new CMStatus
        if (adventCampaign.size()>0)
            insertCampaignMembersStats(adventCampaign, mapTypes, allStatus);
        if (fundCampaigns.size()>0)
            insertCampaignMembersStats(fundCampaigns, mapTypes, allStatus);
        if (aList.size() > 0)
        {
            //Insert the new Volunteer Campaign records
            Database.SaveResult[] srList = Database.insert(aList, false);
            
            Integer i = 0;
            for (Database.SaveResult sr : srList)
            {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    // and add it to the Adventure Campaign in the Related Campaign field.
                    adventCampaign[i].Related_Campaign__c = sr.getId();
                }
                else
                {
                    // Operation failed, so get all errors
                    for(Database.Error err : sr.getErrors())
                    {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Campaign fields that affected this error: ' + err.getFields());
                    }
                }
                i++;
            }
        }
        // Consolidate both campaign lists for the update.
        campaignToUpdate.addAll(adventCampaign);
        campaignToUpdate.addAll(mailChimpCampaign);
        update campaignToUpdate;
        
        //Now it needs to add a GAU Alocation (General fund Activities Fee)
        //for the Adventure Campaign

        if (adventCampaign.size() > 0)
        {
            npsp__General_Accounting_Unit__c genAcUnit =
            [select id from npsp__General_Accounting_Unit__c
             where Name = 'Activity Fees'];
            List<npsp__Allocation__c> theAllocation = new List<npsp__Allocation__c>();
            for (Campaign each : adventCampaign)
            {
                npsp__Allocation__c theAlloc = new npsp__Allocation__c(
                    npsp__Campaign__c = each.id,
                    npsp__General_Accounting_Unit__c = genAcUnit.id,
                    npsp__Percent__c = 100);
                theAllocation.add(theAlloc);
            }
            
            try {
                insert theAllocation;
            } catch(DmlException e) {
                System.debug('An unexpected error has occurred: ' + e.getMessage());
            }
        }
    }
    
    private void insertCampaignMembersStats(List<Campaign> campaigns,
                                           Map<String, Campaign_Type__mdt> mapTypes,
                                           List <CM_Status_Setting__mdt> allStatus)
    {
         //this method gathers all the old CM Status for the campaigns in the list,
         //makes a new list of statuses, inserts the new list and deletes the old statuses for
         //those campaigns.                                      
                                               
        //make a set with all the new campaign ids
        List <id> CampIds = new List <id> ();
        for (Campaign c : campaigns){
            CampIds.add(c.id);
        }        
        List <CampaignMemberStatus> DefStatuses = [SELECT id, CampaignID, HasResponded, IsDefault, Label, SortOrder
                                                   FROM CampaignMemberStatus
                                                   WHERE CampaignID IN :CampIds];
        //if IsDefault is turned on the record can't be deleted so it needs to be
        //turned off 
        for (CampaignMemberStatus cms : DefStatuses){
            if (cms.IsDefault) cms.IsDefault = false;}
        //Before updating the default statuses need to add new defaults
                
        //create a list of new status to be inserted per campaign
        List <CampaignMemberStatus> newStatuses = new List<CampaignMemberStatus>();
        for (Campaign c : campaigns){
            //check if the Campaign Type is included in the list for CM status
            if (mapTypes.containsKey(c.Type))
            {
                //In the Custom Metadata Type for Campaign types, each campaign type has
                //a group number that corresponds with the group of Campaign Member Status
       
                Campaign_Type__mdt ct = mapTypes.get(c.Type);            
                integer grp = Integer.valueOf(ct.Status_Group__c);
                for (CM_Status_Setting__mdt cmStat : allStatus)
                {
                    //check to see if this type of campaign needs a different group of CM statuses
                    If (cmStat.Group_Number__c == grp){
                        CampaignMemberStatus campMemStat = new CampaignMemberStatus(CampaignID = c.Id,
                                                                                    HasResponded = cmStat.Responded__c,
                                                                                    IsDefault = cmStat.Default__c,
                                                                                    Label = cmStat.MasterLabel,
                                                                                    SortOrder = Integer.ValueOf(cmStat.Order__c));
                        newStatuses.add(campMemStat);
                    }
                }
            }
        }
        //if there are new Campaign Member statuses for the campaign                                    
        if (newStatuses.size() > 0) 
        {
            //make a list of new statuses that will be inserted in the CampaignMemberStatus object
            List<CampaignMemberStatus> realNewStatuses = new List<CampaignMemberStatus>();
            //make a map (mapOldStat) with all the existing CM statuses for the campaign
            map<String, CampaignMemberStatus> mapOldStat = 
                new Map<String, CampaignMemberStatus>();
            for (CampaignMemberStatus dcms : DefStatuses)
            {
                mapOldStat.put(dcms.Label, dcms);
            }
            for (CampaignMemberStatus cms : newStatuses)
            {
                if (mapOldStat.containsKey(cms.Label))
                {
                    Integer theIndex = getIndex(DefStatuses, cms.Label);
                    DefStatuses.remove(theIndex);
                }
                else
                {
                    realNewStatuses.add(cms);
                }
            }
            if (realNewStatuses.size() > 0) insert realNewStatuses;
            If (DefStatuses.size() > 0) 
            {
                Update DefStatuses;
                Delete DefStatuses;
            }
        }
    }
    
    private Integer getIndex(List<CampaignMemberStatus> campMemSt, String theLabel)
    {
        //this method obtains the index of the record in the list that has theLabel
        Integer theIndex = 0;
        for (integer x = 0; x < campMemSt.size(); x++)
        {
            if (campMemSt[x].Label == theLabel)
            {
                theIndex = x;
                break;
            }
        }
        return theIndex;
    }
    
    private Map<String, id> getRecTypeId ()
    {
        //This method returns a map of all the record types indexed by the Record Type name
        Map<String, id> recTypeIds = new Map<String, id>();
        List<RecordType> recs = [select id, Name, DeveloperName from RecordType
                                 where sObjectType = 'Campaign'];
        for (RecordType rt : recs)
            recTypeIds.put(rt.DeveloperName, rt.id);
        return recTypeIds;
    }
    
    private void PrepareForDeletion()
    {
        //this method checks if the campaign can be deleted. Campaigns with members that have 
        //status of Attended can't be deleted
        List<Campaign> delCampaign = (List<Campaign>) trigger.old;
        for (Campaign eachCampaign : delCampaign)
        {
            //If the campaign is Adventure type check to see if there are campaign members
            //with status "Attended" and if there is a related campaign: volunteer campaign
            If (eachCampaign.RecordTypeId == campRecType.get('Adventure'))
            {
                If (eachCampaign.Related_Campaign__c != NULL)
                    eachCampaign.adderror('Before deleting the campaign you must delete the volunteer campaign associated with it.');
                List<CampaignMember> cMs = [SELECT id, status FROM CampaignMember
                                            WHERE CampaignId = :eachCampaign.Id AND
                                            Status = 'Attended'];
                If (cMs.size() > 0)
                    eachCampaign.adderror('Cannot delete a campaign that has members with status Attended. Their status must be changed first.');
            }
            Else
            {
                //If the campaign is a volunteer campaign then retreive the Adventure campaign related to it
                //and delete the related campaign from the Adventure record
                If (eachCampaign.RecordTypeId == campRecType.get('Volunteers_Campaign'))
                {
                    if (eachCampaign.Related_Campaign__c != NULL)
                    {
                        Campaign relCampRecord = [SELECT ID, Related_Campaign__c FROM Campaign
                                                  WHERE Id = :eachCampaign.Related_Campaign__c];
                        relCampRecord.Related_Campaign__c = NULL;
                        Update relCampRecord;
                    }
                }
            }
        }
    }
    
    private void ChangeVolCampDates()
    {
        //This method checks if the dates or type of campaign have changed. If the
        //dates have changed, then it changes the volunteer campaign dates of the related
        //campaign as well as the volunteer job and shift dates.
        //If the campaign type has changed and the Campaing Member Status
        //group has changed it changes the possible Campaign Member Status for the campaign,
        //deleting the previous choices.
        
        //Retrieve all campaign types and their CampaignMember Status_Group
        map<String, Campaign_Type__mdt> mapTypes = getMapOfTypes();
        //Retrieve all the possible Status for Adventure campaigns from the Custom Metadata Type CM_Status_Setting
        //and delete those status from CampaignMemberStatus
        List <CM_Status_Setting__mdt> allStatus = [select DeveloperName, MasterLabel, Default__c,
                                                   Responded__c, Order__c, Group_Number__c FROM CM_Status_Setting__mdt
                                                   ORDER BY Group_Number__c];
        //if the campaign dates have changed then change the dates on the volunteer campaign, job & shift
        List<Campaign> oldRec = (List<Campaign>) trigger.old;
        Map<id, Campaign> MapOldRec = new Map<id, Campaign>(oldRec);
        List<Campaign> newRec = (List<Campaign>) trigger.new;
        Map<id, Campaign> MapNewRec = new Map<id, Campaign>(newRec);
        //first, check to see if need to retreive the volunteer campaigns
        Map<id, Campaign> changedCamps = new Map<id, Campaign> ();
        List<Campaign> changedType = new List<Campaign>();
        //Loop through all the campaigns in the trigger
        for (integer x = 0; x < newRec.size(); x++)
        {
            if ((newRec[x].StartDate != oldRec[x].StartDate ||
                 newRec[x].EndDate != newRec[x].EndDate)
                && newRec[x].RecordTypeId == campRecType.get('Adventure')
                && newRec[x].Related_Campaign__c != null)
                changedCamps.put(newRec[x].Related_Campaign__c, newRec[x]);            
            if (newRec[x].Type != oldRec[x].Type)
            {
                //before changing the status for the campaign members check that there
                //are no campaign members for the campaign                
                Integer campMembers = [SELECT count() FROM CampaignMember
                                       WHERE CampaignId = :newRec[x].id];
                if (campMembers == 0)
                {   
                    if (mapTypes.containsKey(newRec[x].Type))
                    {
                        Decimal oldGrp = 0;
                        If (oldRec[x].Type != null)
                        {
                            oldGrp = mapTypes.get(oldRec[x].Type).Status_Group__c;
                        }                        
                        if (mapTypes.get(newRec[x].Type).Status_Group__c !=
                            oldGrp)
                        {
                            changedType.add(newRec[x]);
                        }
                    }
                }
                else
                {
                    newRec[x].addError('Cant change the type of a campaign that has Campaign Members');
                }
            }
        }
        if (changedCamps.size() > 0)
        {
            changeVolShiftDates(changedCamps);
        }
        if (changedType.size() > 0)
        {
            insertCampaignMembersStats(changedType, mapTypes, allStatus);
        }
    }
    
    private void changeVolShiftDates(Map<id, Campaign> changedCamps)
    {
        // this method changes the dates on the volunteer campaigns, jobs and shifts
        Map<id, Campaign> MapVolCamp =
            new Map<id, Campaign>([Select id, StartDate, EndDate from Campaign
                                   where id IN :changedCamps.keySet()]);
        List<Campaign> changedVolCamps = new List<Campaign>();
        for (Campaign c : changedCamps.values())
        {
            Campaign volCamp = MapVolCamp.get(c.Related_Campaign__c);
            volCamp.StartDate = c.StartDate;
            volCamp.EndDate = c.EndDate;
            changedVolCamps.add(volCamp);
        }
        update changedVolCamps;
        //find the jobs and shifts for the campaign and change the shift start date
        Map<id, GW_Volunteers__Volunteer_Job__c> jobsMap =
            new Map<id, GW_Volunteers__Volunteer_Job__c>([select id, GW_Volunteers__Campaign__c
                                                          from GW_Volunteers__Volunteer_Job__c
                                                          where GW_Volunteers__Campaign__c IN :changedCamps.keySet()]);
        Map<id, GW_Volunteers__Volunteer_Shift__c> shiftsMap =
            new Map<id, GW_Volunteers__Volunteer_Shift__c>([select id, name,
                                                            GW_Volunteers__Start_Date_Time__c,
                                                            GW_Volunteers__Volunteer_Job__c
                                                            from GW_Volunteers__Volunteer_Shift__c
                                                            where
                                                            GW_Volunteers__Volunteer_Job__c IN
                                                            :jobsMap.keySet()]);
        for (GW_Volunteers__Volunteer_Shift__c shift : shiftsMap.values())
        {
            GW_Volunteers__Volunteer_Job__c job =
                jobsMap.get(shift.GW_Volunteers__Volunteer_Job__c);
            Campaign vCamp = MapVolCamp.get(job.GW_Volunteers__Campaign__c);
            time shiftTime = shift.GW_Volunteers__Start_Date_Time__c.time();
            shift.GW_Volunteers__Start_Date_Time__c = DateTime.newInstance(vCamp.StartDate, shiftTime);
        }
        update shiftsMap.values();
    }
    
    private Map<String, Campaign_Type__mdt> getMapOfTypes()
    {
        list<Campaign_Type__mdt> camp_Type = [SELECT MasterLabel, Status_Group__c
                                              FROM Campaign_Type__mdt];
        Map<String, Campaign_Type__mdt> mapTypes = new Map<String, Campaign_Type__mdt>();
        for (Campaign_Type__mdt ct : camp_Type){
            mapTypes.put(ct.MasterLabel, ct);
        }
        return mapTypes;
    }
    
}