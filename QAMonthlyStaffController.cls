//This class prints the QA Staff Involvement Report
//
//Martha Vance 3/30/18


public class QAMonthlyStaffController extends QAReports {
    Public Integer totalCamp {get;set;}
    Public List<cType> allCampaignsByType{get;set;}
    List<CampaignMember> cms;
    Map<Id, Contact> contacts;
    Public List<onePage> allPages {get; set;}
    
    public void QAMonthlyStaffController (){}
    
    public PageReference printPDFReport()
    {
        String monthNum = ApexPages.currentPage().getParameters().get('m');
        year = ApexPages.currentPage().getParameters().get('y');
        getMonthYear(monthNum, year);        
        totalCamp = 0;
        Date endRangeDate = date.valueOf(endRange);
        //get from the metadata type the types of campaigns that will have 
        //active participants
        Map<id, Campaign_Type__mdt> theTypes = new Map<id, Campaign_Type__mdt>(
                                           [SELECT id, Label 
                                            FROM Campaign_Type__mdt
                                            WHERE Status_Group__c != 0]);
        //Make a list with the types for the query
        List<String> allTypes = new List<String>();
        for (Campaign_Type__mdt tp : theTypes.values())
        {
            allTypes.add(tp.Label);
        }  
        //Get the RecordTypeid for the Campaign record to set the order of the query
        Map<Id, RecordType> recTypes = new Map<id, RecordType>([select id, Name, DeveloperName, sObjectType from RecordType
                                                WHERE sObjectType = 'Campaign' 
                                                Order By Name]);
        //query the Campaign object to get all the campaigns with active participants
        //within the time range
        Map<Id,Campaign> campaigns = new Map<id, Campaign>([SELECT id, Name, Type, RecordTypeId, StartDate,
                                      EndDate, IsActive, Related_Campaign__c, Participant_Days__c from
                                      Campaign
                                      WHERE StartDate >= :beginRangeDate AND
                                      StartDate <= :endRangeDate AND
                                      Type IN :allTypes                   
                                      Order By Type, StartDate, RecordTypeId]);
        //retrieve all the campaign members in campaigns
        cms = [SELECT id, FirstName, LastName, Status, ContactId, CampaignId, CampaignDate__c
                                    FROM CampaignMember
                                    WHERE CampaignId IN :campaigns.keySet() order by CampaignId, Status];
        //make a list of Contact id's to use in the Contact query to retrieve the contact records
        //of the Campaign Members
        list<id> contIds= new List<id>();
        for (CampaignMember cm : cms)
        {
            contIds.add(cm.ContactId);
        }
        //query contacts
        contacts = new Map<Id, Contact>([Select id, Participant__c,Caregiver__c, Relationship_w_Participant__c
                                  From Contact WHERE id IN :contIds]);        
        allCampaignsByType = new List<cType>();
        Map<id, campaignEvent> theCampaigns = new Map<id, campaignEvent>();
        String newType = 'Nothing';
        cType oneType;
        List<Campaign> campsQueried = campaigns.values();
        // Iterating over the Campaigns
        for (Campaign camp : campsQueried)      
        {
            //this if creates the Type grouping for the campaigns
            if (camp.Type != newType)
            {    
                if (oneType != null)
                {
                    List<campaignEvent> campOfOneType = theCampaigns.values();
                    campOfOneType.sort();
                    totalCamp = totalCamp + campOfOneType.size();
                    oneType.campaigns = campOfOneType;
                    oneType.tot_ce = oneType.campaigns.size();
                    allCampaignsByType.add(oneType);
                }
                oneType = new cType(camp.Type);
                theCampaigns = new Map<id, campaignEvent>();
                newType = camp.Type;
            }
            String campRecType = recTypes.get(camp.RecordTypeId).Name;
            campaignEvent campE = new campaignEvent(camp.id, camp.Name, campRecType, 
                                                    string.valueOf(camp.StartDate), 
                                                    string.valueOf(camp.EndDate), 
                                                    string.valueOf(camp.Participant_Days__c));
            List<cMember> mems = getTheMembers(camp, campRecType);
            // if the campaign is not a Volunteer campaign
            if (mems.size() > 0)if (campRecType == 'Volunteer Campaign')
            {
                //get the list of campaign members from the volunteer campaign
                if (campRecType == 'Volunteer Campaign')
                {
                    campaignEvent temp_camp = theCampaigns.get(camp.Related_Campaign__c);
                    if (temp_camp != null)
                    {
                        temp_camp.Members.addAll(mems);
                        theCampaigns.put(camp.Related_Campaign__c, temp_camp);
                    }
                    else
                    {
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
            campOfOneType.sort();
            totalCamp = totalCamp + campOfOneType.size();
            oneType.campaigns = campOfOneType;
            oneType.tot_ce = oneType.campaigns.size();
            allCampaignsByType.add(oneType);
            allCampaignsByType.sort();
        }
        //once all the information has been gathered and is ready to print
        //run it through the pagination method to separate the pages for the PDF
        allPages = preparePages();
        return null;
    }
    
    public List<onePage> preparePages()
    {
        //number of lines to include in the first page
        integer firstBreak = 55;
        //number of lines to include in any subsequent pages
        integer subsequentBreaks = 60;
        integer lineLimit = firstBreak;
        List<onePage> pages = new List<onePage>();
        onePage aPage = new onePage();
        integer lineCount = 0;
        //re-arange the cTypes in pages
        for (cType campType : allCampaignsByType)
        {
            //inicialize a cType variable to hold the information from the
            //current type group. 
            cType ct = new cType(campType);
            //hold the campaing information up to the line limit for the page 
            //8 is the approximate amount of lines taken by the Type heather           
            lineCount = lineCount + 8;
            for (integer i=0; i < campType.Campaigns.size(); i++)
            {
                campaignEvent ce = new campaignEvent();
                ce = campType.campaigns[i];
                //2 is the approximate amounte of lines taken by the Campaign header
                lineCount = lineCount + 2 + ce.Members.size();
                If (lineCount > lineLimit)
                {
                    if (!( aPage.Types.size() == 0 && ct.campaigns.size() < 1))
                    {
                        // if the linecount goes over the page limit then add the current page
                        // to the pages list and put this campaign in another
                        // page (include the Type information for the header.)
                        lineLimit = subsequentBreaks;
                        boolean continues = false;
                        if (ct.campaigns.size() > 0)
                        {
                            aPage.Types.add(ct); 
                            continues = true;
                        }                  
                        pages.add(aPage);
                        aPage = new onePage();
                        ct = new cType(campType);
                        if (continues) ct.tot_ce = 0;
                        ct.campaigns.add(ce);
                        //type header taken in consideration for linecout
                        lineCount = 8 + 2 + ce.Members.size();
                    }
                    else
                    {
                        //if this is the first type and the first campaign on the page
                        //break the campaign and add the first campaign to the page
                        //and the second to a new page
                        integer currentLines = lineLimit - 10;//8 lines for tye type header and 2 for the campaign header
                        List<campaignEvent> ceBroken = breakCampaign(currentLines, ce);
                        ct.campaigns.add(ceBroken[0]);
                        aPage.Types.add(ct);
                        pages.add(aPage);
                        lineLimit = subsequentBreaks;
                        aPage = new onePage();
                        ct = new cType(campType);
                        ct.tot_ce = 0;
                        ce = new campaignEvent();
                        ce = ceBroken[1];
                        ct.campaigns.add(ce);
                        lineCount = 8 + 2 + ce.Members.size();
                    }
                }
                else
                {
                    //put the campaign in the same page
                    ct.campaigns.add(ce);
                }            
            }
            aPage.Types.add(ct);
            lineLimit = subsequentBreaks;
        }
        //add the last page to the list if it has information.
        if (aPage.Types.size() > 0)
        {
            pages.add(aPage);
        }
        return pages;
    }
    
    private List<campaignEvent> breakCampaign(integer lines, campaignEvent camp)
    {
        List<campaignEvent> twoCampaigns = new List<campaignEvent>();
        campaignEvent ce = new campaignEvent(camp);        
        for (integer i = 0; i < camp.Members.size(); i++)
        {
            if (i < lines)
            {
                ce.Members.add(camp.Members[i]);                
            }
            else
            {
                if (i == lines)
                {
                    twoCampaigns.add(ce);// add the the campaign to the list
                    ce = new campaignEvent(camp);
                    ce.id = 200;
                }
                ce.Members.add(camp.Members[i]);
            }
        }
        twoCampaigns.add(ce);
        return twoCampaigns;
    }
            
    private Map<Id, campaignEvent> addMembers(Map<Id, campaignEvent> campMap, 
                                              campaignEvent theCampaign, 
                                              List<cMember> memberList)
    {
        theCampaign.Members.addAll(memberList);
        campMap.put(theCampaign.cId, theCampaign);
        return campMap;
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
        public Integer id{get; set;}
        public Id cId;
        public String Name{get;set;}
        public String StartDate{get;set;}
        public String EndDate{get;set;}
        public String cRecordType{get;set;}
        public String sParticipantDays{get;set;}
        public List<cMember> Members{get;set;}
        
        public campaignEvent()
        {
            this.Members = new List<cMember>();
        }
        
        public campaignEvent(campaignEvent ce)
        {
            this.id = ce.id;
            this.Name = ce.name;
            this.StartDate = ce.StartDate;
            this.EndDate = ce.EndDate;
            this.cRecordType = ce.cRecordType;
            this.sParticipantDays = ce.sParticipantDays;
            this.Members = new List<cMember>();
        }
        
        public campaignEvent(Id campId, String n, String cRt, String sd, String ed, String pd)
        {
            date sDate = date.valueOf(sd);
            this.id = sDate.day(); //this field is used to order the list of campaigns
            this.cId = campId;
            this.Name = n;
            this.cRecordType = cRt;
            this.StartDate = sd;
            this.EndDate = ed;
            if(pd == null) this.sParticipantDays = '0';
               else this.sParticipantDays = pd;
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
        //The Comparable Interface is used to order a list, in this case ordering by ID
        //
        //this class holds the information for each type of campaign
        public integer id;
        public String type {get;set;}
        public integer tot_ce {get;set;}
        public string totString {get;set;}
        public List<campaignEvent> campaigns{get;set;}
        
        public cType(){}

        public cType(cType campType)
        {
            this.id = campType.id;
            this.type = campType.type;
            this.tot_ce = campType.tot_ce;
            this.totString = 'Total Activities: ' + campType.tot_ce;
            this.campaigns = new List<campaignEvent>();
        }        

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
            this.totString = '';
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
    
    public class onePage {
        public List<cType> Types{get; set;}        
        public onePage()
        {
            this.Types = new List<cType>();
        }
    }
}