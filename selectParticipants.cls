// this class is used for adding participants to an Adventure Campaign
//
//  Martha C. Vance --  April, 2018

public class selectParticipants
{
    public String nameQuery {get; set;}
    public List<Contact> selectedContacts {get; set;}
    public List<CampaignMember> campMembers {get; set;}
    public set<id> currentCM {get; set;}
    public List<partContainer> participants {get; set;}
    @TestVisible private Campaign camp;
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
        camp = [SELECT id, Name, Type FROM Campaign 
                WHERE id = :stdCtrl.getId() LIMIT 1];       
        currentCM = new set<id>();
        participants = new List<partContainer>();
        thereAreContacts = False;
        nameQuery = '';
        mess = '';
        selectedStatus = 'Signed Up';
        wrapContactList = new List<wrapContact>();
        campMembers = [SELECT id, ContactId, Name, Email, Status FROM CampaignMember
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
                            oneCampMem.CampaignId = theCampaignId;
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
        Campaign_Type__mdt campTypeGroup = [SELECT Status_Group__c FROM
                                           Campaign_Type__mdt WHERE 
                                           MasterLabel =: camp.Type
                                           LIMIT 1];
        List<CM_Status_Setting__mdt> theStatuses = [SELECT MasterLabel FROM
                                              CM_Status_Setting__mdt
                                              WHERE 
                                              Group_Number__c =: campTypeGroup.Status_Group__c
                                              Order by Order__c];
        for (CM_Status_Setting__mdt sts : theStatuses)
            PossibleStatuses.add(new SelectOption(sts.MasterLabel,sts.MasterLabel));        
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