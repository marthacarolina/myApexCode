public class QAMonthlyStaffController extends QAReports {
    Public Integer totalCamp {get;set;}
    Public List<cType> allCampaignsByType{get;set;}
    List<CampaignMember> cms;
    Map<Id, Contact> contacts;

    public void QAMonthlyStaffController (){}

    public PageReference printPDFReport()
    {
        String monthNum = ApexPages.currentPage().getParameters().get('m');
        year = ApexPages.currentPage().getParameters().get('y');
        getMonthYear(monthNum, year);
        totalCamp = 0;
        Date endRangeDate = date.valueOf(endRange);
        system.debug('beginRangeDate = ' + beginRangeDate);
        List<String> allTypes = new String[]{'Backpacking', 'Cycling', 'Healthy Day','Hiking',
            'Kayaking','Camping','XCskiing','Sled Hockey','Fundraising',
            'Outreach','Orientation','River Trip'};
        Map<Id, RecordType> recTypes = new Map<id, RecordType>([select id, Name, DeveloperName, sObjectType from RecordType
                                                WHERE Name = 'Adventure' OR
                                                Name = 'Fundraising' OR
                                                Name = 'Volunteer Campaign'
                                                Order By Name]);

        Map<Id,Campaign> campaigns = new Map<id, Campaign>([SELECT id, Name, Type, RecordTypeId, StartDate,
                                      EndDate, IsActive, Related_Campaign__c from
                                      Campaign
                                      WHERE StartDate >= :beginRangeDate AND
                                      StartDate <= :endRangeDate AND
                                      Type IN :allTypes
                                      Order By Type, StartDate, RecordTypeId]);
        cms = [SELECT id, FirstName, LastName, Status, ContactId, CampaignId, CampaignDate__c
                                    FROM CampaignMember
                                    WHERE CampaignId IN :campaigns.keySet() order by CampaignId, Status];
        list<id> contIds= new List<id>();
        for (CampaignMember cm : cms)
        {
            contIds.add(cm.ContactId);
        }
        contacts = new Map<Id, Contact>([Select id, Participant__c,Caregiver__c, Relationship_w_Participant__c
                                  From Contact WHERE id IN :contIds]);
        allCampaignsByType = new List<cType>();
        Map<id, campaignEvent> theCampaigns = new Map<id, campaignEvent>();
        String newType = 'Nothing';
        cType oneType;
        List<Campaign> campsQueried = campaigns.values();
        system.debug('number of campaigns queried = ' + campsQueried.size());
        // Iterating over the Campaigns
        system.debug('list of campaigns:');
        for (campaign qc : campsQueried)
            system.debug('Name: ' + qc.Name + ' Type: '+ qc.type + ' related campaign = ' + qc.Related_Campaign__c);
        for (Campaign camp : campsQueried)
        {
            system.debug('entering the campaign loop: camp.Name = '+ camp.Name + '  * Type = ' + camp.Type);
            if (camp.Type != newType)
            {
                system.debug('++++++  This is a new TYPE   ++++++');
                if (oneType != null)
                {
                    List<campaignEvent> campOfOneType = theCampaigns.values();
                    campOfOneType.sort();
                    system.debug('campOfOneType.size = ' + campOfOneType.size());
                    totalCamp = totalCamp + campOfOneType.size();
                    oneType.campaigns = campOfOneType;
                    oneType.tot_ce = oneType.campaigns.size();
                    allCampaignsByType.add(oneType);
                    system.debug('allCampaignsByType.size = '+allCampaignsByType.size());
                }
                oneType = new cType(camp.Type);
                theCampaigns = new Map<id, campaignEvent>();
                newType = camp.Type;
            }
            String campRecType = recTypes.get(camp.RecordTypeId).Name;
            campaignEvent campE = new campaignEvent(camp.id, camp.Name, campRecType, string.valueOf(camp.StartDate), string.valueOf(camp.EndDate));
            List<cMember> mems = getTheMembers(camp, campRecType);
            system.debug('mems.size() = ' + mems.size()+'     camp.Name = '+camp.Name + '   recordType = ' + campRecType);
            // if the campaign is not a Volunteer campaign
            if (mems.size() > 0)if (campRecType == 'Volunteer Campaign')
            {
                system.debug('campRecType = ' + campRecType);
                //get the list of campaign members from the volunteer campaign
                if (campRecType == 'Volunteer Campaign')
                {
                    campaignEvent temp_camp = theCampaigns.get(camp.Related_Campaign__c);
                    if (temp_camp != null)
                    {
                        showRelCamps(theCampaigns.values(), camp.type);
                        system.debug('temp_camp Campaign Name: ' + temp_camp.Name + '    temp_camp rec.type = '+temp_camp.cRecordType);
                        system.debug('temp_camp.Members.size() = '+temp_camp.Members.size());
                        temp_camp.Members.addAll(mems);
                        theCampaigns.put(camp.Related_Campaign__c, temp_camp);
                    }
                    else
                    {
                        system.debug('volunteer campaign with no related campaign');
                        theCampaigns = addMembers(theCampaigns, campE, mems);
                    }
                }
                Else
                {
                    theCampaigns = addMembers(theCampaigns, campE, mems);
                }
            }
            else
            {
                theCampaigns = addMembers(theCampaigns, campE, mems);
            }
        }
        if (theCampaigns.values().size() > 0)
        {
            List<campaignEvent> campOfOneType = theCampaigns.values();
            system.debug('out of loop - campOfOneType.size() = '+ campOfOneType.size() );
            campOfOneType.sort();
            totalCamp = totalCamp + campOfOneType.size();
            oneType.campaigns = campOfOneType;
            oneType.tot_ce = oneType.campaigns.size();
            allCampaignsByType.add(oneType);
            allCampaignsByType.sort();
        }
        return null;
    }

    private Map<Id, campaignEvent> addMembers(Map<Id, campaignEvent> campMap,
                                              campaignEvent theCampaign,
                                              List<cMember> memberList)
    {
        theCampaign.Members.addAll(memberList);
        campMap.put(theCampaign.cId, theCampaign);
        return campMap;
    }

    public void showRelCamps(List<campaignEvent> customCamp, string tp)
    {
        system.debug('campaigns of this type '+ tp + ' so far:');
        for (campaignEvent ce : customCamp)
            system.debug('Name: ' + ce.Name + ' ce cid = '+ ce.cId+' record type = ' + ce.cRecordType);
    }

    public List<cMember> getTheMembers (Campaign camp, String campRecType)
    {
        List<cMember> cmembers = new List<cMember>();
        for (CampaignMember cm : cms) // Iterating over the campaign members
        {
            if (cm.CampaignId == camp.id)
            {
                Contact c = contacts.get(cm.ContactId);
                cMember member = new cMember(cm.FirstName, cm.LastName, cm.Status, c.Participant__c,
                                     c.Relationship_w_Participant__c, c.Caregiver__c, campRecType);
                cmembers.add(member);
            }
        }
        return cmembers;
    }

    public class cMember{
        // this class holds the information for each campaign member
        public String Name{get;set;}
        public String Status{get;set;}
        public String Type {get;set;}
        public cMember(){}
        //this method initializes the cMember object with the type of member
        public cMember (String fn, String ln, String st, Boolean p, Boolean fof,
                        boolean cgvr, String ct)
        {
            this.Name = fn + ' '+ ln;
            this.Status = st;
            this.Type = 'Interested';
            if (ct == 'Volunteer Campaign')
                this.Type = 'Volunteer';
            else
                If (st == 'Staff')
                this.Type = 'Staff';
            else
                if (p) this.Type = 'Participant';
            else
                if (fof) this.Type = 'Family or Friend';
            else this.Type = 'Caregiver';
        }
    }

    public class campaignEvent implements Comparable
    {
        //this class holds the information for each campaign
        public Integer id;
        public Id cId;
        public String Name{get;set;}
        public String StartDate{get;set;}
        public String EndDate{get;set;}
        public String cRecordType{get;set;}
        public List<cMember> Members{get;set;}

        public campaignEvent(Id campId, String n, String cRt, String sd, String ed)
        {
            date sDate = date.valueOf(sd);
            this.id = sDate.day();
            this.cId = campId;
            this.Name = n;
            this.cRecordType = cRt;
            this.StartDate = sd;
            this.EndDate = ed;
            this.Members = new List<cMember>();
        }

        public integer compareTo(Object compareTo)
        {
            campaignEvent compareToCamp = (campaignEvent)compareTo;
            if (id == compareToCamp.id) return 0;
            if (id > compareToCamp.id) return 1;
            return -1;
        }
    }

    public class cType implements Comparable{
        //this class holds the information for each type of campaign
        public integer id;
        public String type {get;set;}
        public integer tot_ce {get;set;}
        public List<campaignEvent> campaigns{get;set;}

        public cType(){}

        public cType(String t)
        {
            this.id = -1;
            List<String> allTypes = new List<String>{'Backpacking', 'Camping', 'Cycling',
                'Fundraising', 'Healthy Day',  'Hiking', 'Kayaking', 'Outreach',
                'Orientation', 'River Trip', 'Sled Hockey', 'XCskiing'};
                    for (Integer x = 0; x < allTypes.size(); x++)
                {
                    if (t == allTypes[x])
                    {
                        this.id = x;
                        x = allTypes.size() + 1;
                    }
                }
            this.id = this.id < 0 ? allTypes.size() : this.id;
            this.type = t;
            this.tot_ce = 0;
            this.campaigns = new List<campaignEvent>();
        }
        // Implement the compareTo() method to sort list
        public integer compareTo(Object compareTo)
        {
            cType compareToType = (cType)compareTo;
            if (id == compareToType.id) return 0;
            if (id > compareToType.id) return 1;
            return -1;
        }
    }
}
