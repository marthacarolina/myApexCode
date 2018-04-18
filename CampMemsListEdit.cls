//This class is the controller extension for the Visualforce page ChngMemStatus
//It changes the status (picked by the user) of the Campaign Member's selected.
//
//Martha Vance April 2018


public class CampMemsListEdit
{
    private ApexPages.StandardController std;
    @TestVisible private final Campaign camp;
    public String message{get;set;}
    public List<CampaignMember> participants {get;set;}
    public List<wrapCampMem> wrapParticipantList {get; set;}
    public wrapCampMem wCM {get;set;}
    public String selectedStatus {get;set;}
    //public Picklist_Values__c theStatus {get;set;}
    
    public void processSelected(){
        //give all the selected participants the status chosen
        if (selectedStatus != null)
        {
                Integer i = 0;
                for (wrapCampMem a: wrapParticipantList){
                    if (a.selected == true) 
                    {   
                        participants[i].Status = selectedStatus;
                    }                    
                        i++;
                }
        }
    }
    
    public CampMemsListEdit(ApexPages.StandardController stdCtrl)
    {
        camp = [SELECT id, Name, Type FROM Campaign
                WHERE id = :stdCtrl.getId() LIMIT 1];
        message = '';
        //The default value for Status is SIGNED UP
        wrapParticipantList = New List<wrapCampMem>();
        participants=[select id, Name, Email, Status, Activity_Days__c 
                      from CampaignMember where CampaignId =: camp.id 
                      order by Name asc limit 50];
        //if there are no participants in the campaign
        if (participants.size() == 0) message = 'There are no participants in this campaign.';
        else
        {
            for (CampaignMember cm : participants){
                wCM = new wrapCampMem(cm);
                //system.debug('wCM.Name = '+ wCM.part.Name);
                wrapParticipantList.add(wCM);            
            }
        }
    }
    
    public List<SelectOption> getPossibleStatuses()
    {
        //retrieve the possible statuses for this campaign
        List<SelectOption> PossibleStatuses = new List<SelectOption>();
        List<CampaignMemberStatus> cms = 
            [SELECT label, campaignid, SortOrder, isDefault from campaignmemberstatus WHERE
             campaignId = :camp.id ORDER BY SortOrder ASC];
        for (CampaignMemberStatus sts : cms)
        {
            PossibleStatuses.add(new SelectOption(sts.Label,sts.Label));
            if (sts.isDefault)
                selectedStatus = sts.Label;
        }        
        return PossibleStatuses;
    }
        
    public void recordChanges()
    {
        // update the participants' status and update records
        processSelected();
        update participants;
    }
 
    public PageReference saveChanges()
    {
        recordChanges();
        //reload the same page 
        PageReference result= ApexPages.currentPage();
        result.setRedirect(true);      
        return result;
    }
    
    public PageReference done()
    {
        recordChanges();
        //go back to the campaign page
        PageReference result= new PageReference('/'+camp.Id);
        result.setRedirect(true); 
        return result;
    }
    
    public class wrapCampMem{
        //wrapper class used for the rows in the table
        public CampaignMember part {get;set;}
        public Boolean selected {get;set;}
        
        public wrapCampMem (CampaignMember p){
            part = p;
            selected = false;
        }
            
    }
}