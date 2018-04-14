//This class links two campaigns together using the Related_Campaign__c field
//
//Martha Vance April 2018

public class LinkCampaigns {
    Private Final Campaign camp;
    Public Boolean secondCamp {get;set;}
    Public map<id, Campaign> VolCamp;
    Private map<String, id> recTypes;
    Public id VolCampId {get;set;}
    Public String beginDate {get;set;}
    
    public LinkCampaigns (ApexPages.StandardController stdController){
        secondCamp = false;
        this.camp = (Campaign)stdController.getRecord();
        beginDate = string.valueOf(camp.StartDate);
        getRecTypeIds();
        if (camp.RecordTypeId != recTypes.get('Volunteer Campaign'))
        {
            //if the campaign is not a volunteer campaign
            if (camp.Related_Campaign__c != null)
            {
                //if this campaign already has a Related Campaign
                 ApexPages.addmessage(new ApexPages.Message
                                 (ApexPages.severity.info, 
                                  'This campaign already has a Related Campaign'));
            }
            else            
                secondCamp = true; // if the campaign doesn't have a related campaing continue
        }
        else
            //if this is a Volunteer Campaign
            ApexPages.addmessage(new ApexPages.Message
                                 (ApexPages.severity.info, 
                                  'You need to start with the Adventure or Fundraising Campaign'));
    }
    
    public List<SelectOption> getVolCampaigns(){
        //retrieve the next 5 Volunteer Campaigns that dont have a Related_Campaign__c
        //with the same StartDate
        VolCamp = new Map<id, Campaign>([SELECT ID, Name, StartDate, Related_Campaign__c
                                         FROM Campaign
                                         WHERE RecordTypeId = :recTypes.get('Volunteer Campaign')
                                         AND StartDate >= :camp.StartDate
                                         AND Related_Campaign__c = null
                                         Limit 5]);
        List<SelectOption> vCamps = new List<SelectOption>();
        List<Campaign> vCampaigns = VolCamp.values();
        for (Campaign c : vCampaigns)
            vCamps.add(new SelectOption(c.id,c.Name));        
        return vCamps;
    }
    
    public PageReference LinkIt() {
        if (VolCampId != null)
        {
            //if the user has picked a Volunteer campaign to link
            //set the Related Campaign fields and update the records
            //redirect the user to the campaign detail page
            camp.Related_Campaign__c = VolCampId;
            Campaign volRelCamp = VolCamp.get(VolCampId);
            volRelCamp.Related_Campaign__c = camp.id;
            List<Campaign> bothCamps = new List<Campaign>();
            bothCamps.add(camp);
            bothCamps.add(volRelCamp);
            update bothCamps;
            return (new PageReference('/'+ camp.id));
        }
        else
        {
            //If the user didn't select a volunteer campaign to link but
            //clicked the Link It button
            ApexPages.addmessage(new ApexPages.Message
                                 (ApexPages.severity.info, 
                                  'Select a Volunteer campaign to link'));
            return null;
        }
    }
    
    public PageReference goBack(){
        //go back to the campaign record detail page
        return (new PageReference('/'+ camp.id));
    }
                        
    private void getRecTypeIds(){
        //retrieve all the record types from the campaign object
        List<RecordType> rTs = [select id, name from RecordType
                               where sObjectType = 'Campaign'];
        recTypes = new Map<String, id>();
        for (RecordType rt : rTs)        
            recTypes.put(rt.name, rt.id);        
    }

}