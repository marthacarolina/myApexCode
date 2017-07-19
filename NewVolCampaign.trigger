// this class is no longer in use and has been replaced by CampaignTriggerHandler & Campaign Trigger

// This trigger opperates when a new Campaign is created
// if it is an Adventure Campaign, it adds a Volunteer Campaign record and it
// saves the id of the Adventure Campaign in the Related Campaign field of the Volunteer
// campaign and the id of the volunteer campaign in the related campaign field of
// the Adventure campaign.

trigger NewVolCampaign on Campaign (after insert)
{
    //Campaign RecordType 'Adventure Campaign' id = '012o0000000xwhO' both sndbx & prod
    //Campaign RecordType Fundraising id = '012o0000000xwhT' both sndbx & prod
    //Campaign RecordType Volunteer in prod = '012o0000001AJaa'
    //Campaign RecordType Volunteer in sandbox = '012210000004Q2O'

    //GAU RecordType Activities Fee production id = a0Vo000000911wY
    //GAU RecordType Activities Fee sandbox id = a0V21000000Ng45


    list<Campaign> aList = new List<Campaign>();
    list<Campaign> adventCampaign = new List<Campaign>();
    list<Campaign> mailChimpCampaign = new List<Campaign>();
    list<Campaign> campaignToUpdate = new List<Campaign>();
    Integer mc = 0;
    for (Campaign each : trigger.new)
    {
        //check that the campaign is an Adventure campaign
        if (each.RecordTypeId == '012o0000000xwhO')
        {
            //If it is a Mail Chimp campaign, change the record type to Fundraiser
            if (each.Name.contains('MailChimp'))
            {
                Campaign aMCCampaign = new Campaign(id = each.id,
                                                    Name = each.name,
                                                    RecordTypeId = '012o0000000xwhT',
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
                volunteerCampaign.RecordTypeId = '012o0000001AJaa';
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
    for (Campaign each : adventCampaign)
        campaignToUpdate.add(each);
    for (Campaign each : mailChimpCampaign)
        campaignToUpdate.add(each);
    update campaignToUpdate;

    //Now it needs to add a GAU Alocation (General fund Activities Fee)
    //for the Adventure Campaign
    //This part is not inside the if, but only works with the records that were
    //of record type Adventure.
    if (adventCampaign.size() > 0)
    {
        List<npsp__Allocation__c> theAllocation = new List<npsp__Allocation__c>();
        for (Campaign each : adventCampaign)
        {
            npsp__Allocation__c theAlloc = new npsp__Allocation__c(
                npsp__Campaign__c = each.id,
                npsp__General_Accounting_Unit__c = 'a0Vo000000911wY',
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
