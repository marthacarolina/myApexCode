// Controller for campaign summary PDF visualforce page: printCampaignSummaryPDF
// this class retrieves the campaign info and the volunteer campaign info to print
// a summary of the Adventure campaign
// 
// Martha Vance 2/20/18


public class printCampaignSummary {
    public Campaign volCampaign{get;set;}
    public List<volunteer> volunteers {get;set;}
    public List<partcpnt> participants {get;set;}
    public Campaign campaign {get;set;}
    public integer totNewParticipants {get;set;}
    public integer totAllInclusiveActDays {get;set;}
    public List<Activity_Recap__c> theRecap {get;set;}
    public boolean haveRecap {get;set;}
    public boolean noVolunteers {get;set;}
    public boolean noParticipants {get;set;}
    public string forDate{get;set;}
    public string forTime{get;set;}
    private integer totLines;
    public List<onePpage> pPages {get;set;}
    public List<oneVpage> vPages {get;set;}
    
    public printCampaignSummary(){}
    
    public void autoRun()
    {
        campaign = new campaign();
        id campId = (id)ApexPages.currentPage().getParameters().get('id');
        //initialize variables
        //set the variables used for the current date and time of the report
        totLines = 0;
        datetime theDate = system.now();
        forDate = string.valueOf(theDate.date().format());
        integer minutes = theDate.time().minute();
        string stMinutes = minutes > 9 ? string.valueOf(minutes) : '0' + string.valueOf(minutes);
        forTime = string.valueOf(theDate.time().hour()) + ':'+ stMinutes;
        totAllInclusiveActDays = 0;
        theRecap = new List<Activity_Recap__c>();
        haveRecap = false;
        noVolunteers = false;
        noParticipants = false;
        volCampaign = new Campaign();
        volunteers = new List<volunteer>();
        participants = new List<partcpnt>();
        totNewParticipants = 0;
        //retrieve the campaign record -- I tried just using the campaign record
        //sent by the std, but it kept giving an error saying the Related_Campaign__c
        //field had not been queried
        campaign = [SELECT id, name, description, type, StartDate, EndDate,
                    Head_Count__c, Activity_Miles__c, 
                    Contract_Reservation_Fee__c, Fee_paid_by_DA__c, Salary_Wages__c,
                    Supplies_Cost__c, Transportation_Rental__c, Transportation_Gas__c,
                    Related_Campaign__c, NumberOfOpportunities, AmountAllOpportunities,
                    NumberOfWonOpportunities, AmountWonOpportunities, ActualCost,
                    Participant_Days__c
                    FROM Campaign WHERE id = :campId]; 
        //retrieve the campaign members (participants)
        List<CampaignMember> cms = [SELECT firstName, lastName,
                                    Activity_Days__c, Additional_Invitees__c,
                                    Party_of__c, ContactId, Status
                                    FROM CampaignMember 
                                    WHERE campaignId = :campId];
        List<id> contIds = new List<id>();
        //load the campaignmember contact Id's in a set to query the contact object
        for (CampaignMember cm : cms)
            contIds.add(cm.ContactId);
        //query the contact object and load the result in a map indexed by the contact id        
        Map<id, Contact> mapContacts = 
            new Map<id, Contact>([SELECT id, Name, FirstAdventureDate__c, Participant__c,
                                    Caregiver__c, Relationship_w_Participant__c
                                    FROM Contact WHERE id IN :contIds]);
        //create the list of participants with the info from cms & mapContacts
        for (CampaignMember cm : cms)
        {
            partcpnt nPart = new partcpnt(cm, mapContacts.get(cm.ContactId), campaign.StartDate);
            if (nPart.isNew) totNewParticipants++;
            totAllInclusiveActDays = totAllInclusiveActDays + nPart.ActivityDays;
            participants.add(nPart);
        }
        if (participants.size() < 1) noParticipants = true;
        //retrieve the volunteer campaign record
        if (campaign.Related_Campaign__c != null) 
        {
            volCampaign = [SELECT id, Name, 
                           GW_Volunteers__Volunteer_Completed_Hours__c,
                           GW_Volunteers__Number_of_Volunteers__c, 
                           Related_Campaign__c FROM Campaign 
                       WHERE id = :campaign.Related_Campaign__c limit 1];
            if (volCampaign != null)
            {
                //retrieve the volunteer job id and then from the volunteer hours object
                //retrieve the contacts that volunteered and the hours for each
                if (volCampaign.GW_Volunteers__Number_of_Volunteers__c > 0)
                {
                    volunteers = getVols(volCampaign.id, volCampaign.Name);
                }
                if (volunteers.size() == 0) noVolunteers = true;
            }
        } 
        else
            noVolunteers = true;  
        //query the recap object to get the records for this campaign
        theRecap = [SELECT Activity_Overview__c,CampaignId__c,
                    Opportunities_for_Improvement__c, Stories_Notes__c,
                    Strength_Weaknesses__c
                    FROM Activity_Recap__c where CampaignId__c = :campId];
        if (theRecap.size() > 0) haveRecap = true;
        preparePagination(); 
    }
    
    private List<volunteer> getVols(id cId, string cName)
    {
        //this method runs the report Volunteer_list using the campaign id and the
        //campaign name as filters. The report returns all the volunteers signed up
        //for the campaign grouped by campaign.
        String theID = '' + cId;
        theID = theID.left(15);
        List<volunteer> vols = new List<volunteer>();
        List <Report> reportList = [SELECT Id,DeveloperName FROM Report where
                                    DeveloperName = 'Volunteer_List'];
        String reportId = (String)reportList.get(0).get('Id');
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
        Reports.ReportMetadata rm = describe.getReportMetadata();
        Reports.ReportFilter filter1 = rm.getReportFilters()[0];
        Reports.ReportFilter filter2 = rm.getReportFilters()[1];
        filter1.setValue(theID);
        filter2.setValue(cName);
        // Run the report - syncronously
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, rm, true);
        Reports.Dimension dim = results.getGroupingsDown();
        List<Reports.GroupingValue> groupingVal = dim.getGroupings();
        List<String> factMapKeys = new List<String>(); 
        for (Reports.GroupingValue gV : groupingVal)
        {
            String campName = gv.getLabel();
            String factMapKey = gV.getKey() + '!T';
            Reports.ReportFactWithDetails factDetails =
              (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
            List<Reports.ReportDetailRow> detailRows = factDetails.getRows();
            //cycle through the report rows
            //each row of the report corresponds to one volunteer
            for (Reports.ReportDetailRow dR : detailRows)
            {
                volunteer vol = new volunteer();
                List<Reports.ReportDataCell> rowCells = dr.getDataCells();
                vol.hours = string.valueOf(rowCells[1].getLabel());
                vol.status = string.valueOf(rowCells[2].getLabel());
                vol.name = string.valueOf(rowCells[4].getLabel());
                if (! (vol.name == null || vol.name == '-'))
                    vols.add(vol);
            }
        }         
        return vols;
    }

    private void preparePagination(){
        totLines = 20;
        decimal lCount = 0;
        pPages = new List<onePpage>();
        onePpage pPage = new onePpage();
        if (participants.size() > 0)
        {
            for (partcpnt p : participants)
            {           
                if (lCount > totLines)
                {                    
                    pPages.add(pPage);
                    pPage = new onePpage();
                    lCount = 3;
                    totLines = 60;
                }
                pPage.aPage.add(p);
                lCount = lCount + 1.5;               
            }
            if (pPage.aPage.size() > 0) pPages.add(pPage);            
        }
        vPages = new List<oneVpage>();
        oneVpage vPage = new oneVpage();
        if (volunteers.size() > 0)
        {
            for (volunteer v : volunteers)
            {           
                if (lCount > totLines)
                {                    
                    vPages.add(vPage);
                    vPage = new oneVpage();
                    lCount = 3;
                    totLines = 60;
                }                
                vPage.aPage.add(v);
                lCount = lCount + 1.5;                               
            }
            if (vPage.aPage.size() > 0) vPages.add(vPage);            
        }
    }
    
    public class onePage{
        public List<partcpnt> aPage{get;set;}
        public List<volunteer> bPage{get;set;}

        public onePage(boolean part){
            if (part) this.aPage = new List<partcpnt>();
            else this.bPage = new List<volunteer>();
        }
    }

    public class onePpage{
        public List<partcpnt> aPage{get;set;}

        public onePpage(){
            this.aPage = new List<partcpnt>();
        }
    }    

    public class oneVpage{
        public List<volunteer> aPage{get;set;}

        public oneVpage(){
            this.aPage = new List<volunteer>();
        }
    }
    
    public class partcpnt
    {
        public string Name {get;set;}
        public string Status {get;set;}
        public boolean IsNew {get;set;}
        public integer ActivityDays {get;set;}
        public string Type {get;set;}
        public integer Party_of{get;set;}
        
        public partcpnt(CampaignMember cm, Contact cont, date cDate)
        {
            this.Name = cont.name;
            this.Status = cm.status;
            this.IsNew = false;
            this.ActivityDays = integer.valueOf(cm.Activity_Days__c);
            this.Party_of = integer.valueOf(cm.Party_of__c);
            if (cont.FirstAdventureDate__c == cDate) this.isNew = true;
            if (cm.status == 'Staff') 
            {
                this.Type = cm.status;
            }
            else 
            {
                this.Type = 'Participant';
                if (cont.Participant__c) this.type = 'Member';
                else 
                    if (cont.Caregiver__c) this.type = 'Caregiver';
                    else if (cont.Relationship_w_Participant__c) this.type = 'FoF';
            }
        }
        
        public partcpnt(){}
    }
    
    public class volunteer
    {
        public string Name {get;set;}
        public string Status {get;set;}
        public string Hours {get;set;}
        
        volunteer(){}
        
    }
}