public class CampaignTriggerHandler extends TriggerHandler{
    public Map<String, id> campRecType;

    public CampaignTriggerHandler()
    {
        campRecType = getRecTypeId();
    }

    protected override void afterInsert() {
        AddAdventureCampaign();
    }

    protected override void beforeDelete() {
        PrepareForDeletion();
    }

    protected override void afterUpdate() {
        ChangeVolCampDates();
    }

    public void AddAdventureCampaign()
    {
        list<Campaign> aList = new List<Campaign>();
        list<Campaign> adventCampaign = new List<Campaign>();
        list<Campaign> mailChimpCampaign = new List<Campaign>();
        list<Campaign> campaignToUpdate = new List<Campaign>();
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
                    Campaign anAdvCamp = new Campaign(id = each.id);
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
        }
        // Add the CampaignMember Status for all the new Adventure Campaigns
        insertCampaignMembersStats(adventCampaign);
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
        //This part is not inside the if, but only works with the records that were
        //of record type Adventure.
        npsp__General_Accounting_Unit__c genAcUnit =
            [select id from npsp__General_Accounting_Unit__c
             where Name = 'Activity Fees'];

        if (adventCampaign.size() > 0)
        {
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

    private void insertCampaignMembersStats(List<Campaign> adventCampaign){
        //make a set with all the new campaign ids
        List <id> advCampIds = new List <id> ();
        for (Campaign advc : adventCampaign){
          advCampIds.add(advc.id);
        }
        //Retrieve all the possible Status for Adventure campaigns from the Custom Metadata Type CM_Status_Setting
        List <CM_Status_Setting__mdt> allStatus = [select DeveloperName, MasterLabel, Default__c,
                                                    Responded__c, Order__c FROM CM_Status_Setting__mdt];
        List <CampaignMemberStatus> DefStatuses = [SELECT id, CampaignID, HasResponded, IsDefault, Label, SortOrder
                                                                                    FROM CampaignMemberStatus
                                                                                    WHERE CampaignID IN advCampIds];
        Delete DefStatuses;
        List <CampaignMemberStatus> newStatuses = new List<CampaignMemberStatus>();
        for (id campId : advCampIds){
          for (CM_Status_Setting__mdt cmStat : allStatus)
          {
            CampaignMemberStatus campMemStat = new CampaignMemberStatus(CampaignID = campId,
                                                HasResponded = cmStat.Responded__c,
                                                IsDefault = cmStat.Default__c,
                                                Label = cmStat.MasterLabel,
                                                SortOrder = cmStat.Order__c);
            newStatuses.add(campMemStat);
          }
        }
        insert newStatuses;
    }

    private Map<String, id> getRecTypeId ()
    {
        Map<String, id> recTypeIds = new Map<String, id>();
        List<RecordType> recs = [select id, Name, DeveloperName from RecordType
                                where sObjectType = 'Campaign'];
        for (RecordType rt : recs)
            recTypeIds.put(rt.DeveloperName, rt.id);
        return recTypeIds;
    }

    private void PrepareForDeletion()
    {
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
        List<Campaign> oldRec = (List<Campaign>) trigger.old;
        Map<id, Campaign> MapOldRec = new Map<id, Campaign>(oldRec);
        List<Campaign> newRec = (List<Campaign>) trigger.new;
        Map<id, Campaign> MapNewRec = new Map<id, Campaign>(newRec);
        //first, check to see if need to retreive the volunteer campaigns
        Map<id, Campaign> changedCamps = new Map<id, Campaign> ();
        for (integer x = 0; x < newRec.size(); x++)
        {
            if ((newRec[x].StartDate != oldRec[x].StartDate ||
                 newRec[x].EndDate != newRec[x].EndDate)
                && newRec[x].RecordTypeId == campRecType.get('Adventure')
                && newRec[x].Related_Campaign__c != null)
                changedCamps.put(newRec[x].Related_Campaign__c, newRec[x]);
        }
        if (changedCamps.size() > 0)
        {
             changeVolShiftDates(changedCamps);
        }
    }

    private void changeVolShiftDates(Map<id, Campaign> changedCamps)
    {
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
}
