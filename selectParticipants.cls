// this class is used for adding participants to an Adventure Campaign
// it is the controller for the visualforce page selectCampaignMembers2
//
//  Martha C. Vance --  April, 2018

public class selectParticipants
{
    @TestVisible private final Campaign camp;
    public String nameQuery {get; set;}
    public List<Contact> selectedContacts {get; set;}
    public List<CampaignMember> campMembers {get; set;}
    public set<id> currentCM {get; set;}
    public List<partContainer> participants {get; set;}
    public List<wrapContact> wrapContactList {get; set;}
    public id theCampaignId {get; set;}
    public Boolean thereAreContacts {get; set;}
    public String mess {get; set;}
    public String selectedStatus {get;set;}
    
    public PageReference executeSearch()
    {
        if (nameQuery != null)
        {
            // Initialize or clear the Contact List that will contain contacts from the search
            wrapContactList = new List<wrapContact>();
            String queryStr='%' + nameQuery + '%';
            for (Contact c : [select id, Name, FirstName, LastName, Email, Participant__c from Contact 
                              where (name like :queryStr) or (email like :queryStr) limit 10])
            {    wrapContactList.add(new wrapContact(c)); }
            if ((wrapContactList == null) || (wrapContactList.size() < 1))
            { ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter a Name or Email'));
            }
        }
        else
        { ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No contacts were found mathcing ' + nameQuery));
        }                          
        return null;
    }
    
    
    public selectParticipants(ApexPages.StandardController stdCtrl)
    {
        camp = (Campaign) stdCtrl.getRecord();
        currentCM = new set<id>();
        participants = new List<partContainer>();
        thereAreContacts = False;
        nameQuery = '';
        mess = '';
        wrapContactList = new List<wrapContact>();
        campMembers = [SELECT id, ContactId, Name, Email, Status, CampaignId FROM CampaignMember
                       WHERE CampaignId = :camp.id ORDER BY FirstName];
        for (CampaignMember p : campMembers) {
            partContainer aPart = new partContainer(p, p.Name, p.Email);
            participants.add(aPart);
            currentCM.add(p.contactid);
        }
    }
    
    public void processSelected() {
        selectedContacts = new List<Contact>();
        // make sure that the list has records
        if (wrapContactList.size() > 0){
            for(wrapContact wrapContactObj : wrapContactList) {
                //only process contacts that have been selected
                if(wrapContactObj.selected == true) {
                    //check if contact is already a campaign member, if not then add
                    //otherwise notify the user that the contact is already a member
                    if ( ! currentCM.contains(wrapContactObj.cont.id) )
                    {
                        CampaignMember oneCampMem = new CampaignMember();
                        oneCampMem.CampaignId = camp.Id;
                        oneCampMem.ContactId = wrapContactObj.cont.id;
                        oneCampMem.Status = selectedStatus;
                        partContainer onePart = new partContainer(oneCampMem, wrapContactObj.cont.Name, wrapContactObj.cont.Email);
                        participants.add(onePart);
                        currentCM.add(wrapContactObj.cont.id);
                    }
                    else {
                        mess = wrapContactObj.cont.Name + ' is already a member of the adventure.';
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,mess));
                    }
                }
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
    
    public PageReference saveNewParticipants(){
        List<CampaignMember> fullList = new List<CampaignMember>();
        for (partContainer q : participants){
            fullList.add(q.theParticipant);}
        try {
            upsert fullList;
            PageReference retPage = new PageReference('/'+ theCampaignId);
            return retPage;
        } catch (DmlException e) {
            System.debug(e.getMessage());
            return null;
        }
    }
    
    public class partContainer {
        public CampaignMember theParticipant {get; set;}
        public String pName {get; set;}
        public String pEmail {get; set;}
        
        public partContainer(CampaignMember p, String n, String e) {
            theParticipant = p;
            pName = n;
            pEmail = e;          
        }
    }
    
    public class wrapContact {
        public Contact cont {get; set;}
        public Boolean selected {get; set;}
        
        public wrapContact(Contact c) {
            cont = c;
            selected = false;
        }
    }
}