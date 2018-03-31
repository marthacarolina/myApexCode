// This is the class controller for the visualforce page QAMonthlyPdfVF it
// runs the report QA Total Activity Days and parces the information to print 
// 
// Martha Vance 3/30/2018


public class QAMonthlyController extends QAReports{
    public List<OnePage> allPages {get;set;} //pages of participants
    public List<OnePage> sUPages {get;set;} //pages of new-sign-ups
    public List<participantInfo> participants{get;set;}
    public List<participantInfo> newSignUps{get;set;}
    Public Integer totalMAD{get;set;}
    Public Integer totParticipantDays {get;set;}
    Public Integer serialParticipants{get;set;}
    Public Integer totalParticipants{get;set;}
    Public Integer totNewParticipants{get;set;}
    Public Integer newSigned {get;set;}
    PUblic Integer totAllInclusiveActDays {get;set;}
    Public Date endRangeDate;
    integer breakPoint = 40; //this value only works for the first page
    integer subseqPageBrakes = 59; //this is the number of lines for the rest of the pages
    integer linesInPage = 0;
    public integer participantPages {get;set;}
    public boolean newPage {get;set;}

    public void QAMonthlyController(){
        totalMAD = 0;
    }

    public void MonthlyQA()
    {
        totalMAD = 0;
        serialParticipants = 0;
        totNewParticipants = 0;
        //get the range for the report
        String monthNum = ApexPages.currentPage().getParameters().get('m');
        year = ApexPages.currentPage().getParameters().get('y');
        getMonthYear(monthNum, year);
        newSignUps = ParticipantStats();
        newSigned = newSignUps.size();
        ParticipantsMonthly();
        TotalParticipantDaysforMonth();
        prepareLinesForPrinting();
    }
    
    public List<participantInfo> ParticipantStats()
    {
        endRangeDate = date.valueOf(endRange);
        //This query returns the contacts that have signed up with DA during the
        //report time range
        List<Contact> contSignups = [Select Name, Member_Since__c from Contact
                                     Where Participant__c = true AND
                                     Member_Since__c >= :beginRangeDate
                                     And Member_Since__c <= :endRangeDate];            
        List<participantInfo> newPart = new List<participantInfo>();
        for (Contact c : contSignups)
        {
            participantInfo nP = new participantInfo();
            nP.Name = c.Name;
            nP.memberSince = c.Member_Since__c;
            newPart.add(nP);
        }
        return newPart;
    }
            
    public void TotalParticipantDaysforMonth()
    {
        //this method gets the total participant in each campaign days for the time range
        // **  3-30-18 I am going to comment most of the method because I don't think
        // **  we need to include Total Activity Days -- not the ways it's calculated here

        //it uses a report report that queries the campaigns that have CMs with status of
        //Attended, Completed or Staff
        List <Report> reportList = [SELECT Id,DeveloperName FROM Report where
                                    DeveloperName = 'QA_Total_Activity_Days'];
        String reportId = (String)reportList.get(0).get('Id');
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
        Reports.ReportMetadata rm = describe.getReportMetadata();
        Reports.ReportFilter filter1 = rm.getReportFilters()[0];
        Reports.ReportFilter filter2 = rm.getReportFilters()[1];
        filter1.setValue(beginRange);
        filter2.setValue(endRange);
        // Run the report - syncronously
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, rm, true);
        // Get the grand total Participant Days
        Reports.ReportFact grandTotal = (Reports.ReportFact)results.getFactMap().get('T!T');
        decimal tempDec = (Decimal)grandTotal.getAggregates().get(1).getValue();
        totParticipantDays = integer.valueOf(tempDec);
        // Get the groupings (campaigns)
        //Reports.Dimension dim = results.getGroupingsDown();
        //List<Reports.GroupingValue> groupingVal = dim.getGroupings();
        //List<String> factMapKeys = new List<String>(); 
        //Integer tots = 0;
        // Parse the report by campaigns
        //for (Reports.GroupingValue gV : groupingVal)
        //{
        //    String campName = gv.getLabel();
        //    String factMapKey = gV.getKey() + '!T';
        //    Reports.ReportFactWithDetails factDetails =
        //        (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
        //    List<Reports.ReportDetailRow> detailRows = factDetails.getRows();
        //    List<Reports.ReportDataCell> firstRowCells = detailRows[0].getDataCells();
        //    date startCamp = date.valueOf(firstRowCells[0].getValue());
        //    date endCamp = date.valueOf(firstRowCells[1].getValue());            
        //    Integer actDays = startCamp.daysBetween(endCamp) + 1;
        //    Integer campADays = detailRows.size() * actDays;
        //    tots = tots + campADays;
        //}        
    }
    
    public void ParticipantsMonthly()
    {
        List <Report> reportList = [SELECT Id,DeveloperName FROM Report where
                                    DeveloperName = 'Participants_and_Activity_Days'];
        String reportId = (String)reportList.get(0).get('Id');
        // Get the report metadata
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
        Reports.ReportMetadata rm = describe.getReportMetadata();
        //Set the filters (bypass 0, set 1 and 2 with month's first date and last date)
        Reports.ReportFilter filter1 = rm.getReportFilters()[1];
        Reports.ReportFilter filter2 = rm.getReportFilters()[2];
        filter1.setValue(beginRange);
        filter2.setValue(endRange);
        // Run the report - syncronously
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, rm, true);
        //System.debug('Synchronous results: ' + results);

        // Get detail columns
        List<String> columnFields = rm.getDetailColumns();
        Integer numOfColumns = columnFields.size();

        // Get report format
        //System.debug('Report format: ' + rm.getReportFormat());
        // Get the down-groupings in the report
        Reports.Dimension dim = results.getGroupingsDown();
        List<Reports.GroupingValue> groupingVal = dim.getGroupings();
        List<String> factMapKeys = new List<String>();
        participants = new List<participantInfo>();
        // Iterate thorugh the members
        for (Reports.GroupingValue gV : groupingVal)
        {
            Boolean firstTimer = false;
            participantInfo participant = new participantInfo();
            participant.Name = gv.getLabel();
            // Construct a fact map key, using the grouping key value
            String factMapKey = gV.getKey() + '!T';
            factMapKeys.add(factMapKey);
            // Get the fact map for this grouping from the report results
            Reports.ReportFactWithDetails factDetails =
                (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
            // Get the summary amounts from the fact map it should be
            // Total Adventures, Total Activity Days and Total records
            List<Reports.SummaryValue> sumVal = factDetails.getAggregates();
            participant.totCamp = integer.valueOf(sumVal[0].getValue());
            participant.totActDays = integer.valueOf(sumVal[1].getValue());
            totalMAD = totalMAD + participant.totActDays;
            // Get the fields value for the grouping
            List<Reports.ReportDetailRow> detailRows = factDetails.getRows();
            List<adventure> advs = new List<adventure>();
            Boolean firstAdventure = true;
            for (Reports.ReportDetailRow dr : detailRows)
            {
                List<Reports.ReportDataCell> dataCells = dr.getDataCells();
                adventure adv = new adventure();
                adv.Name = dataCells[0].getLabel();
                adv.sdate = dataCells[1].getLabel();
                adv.ActivityDays = integer.valueOf(dataCells[2].getValue());
                adv.Attended = boolean.valueOf(dataCells[3].getValue());
                adv.Staff = boolean.valueOf(dataCells[4].getValue());                
                integer overallActDays = integer.valueOf(dataCells[8].getValue());                
                if (firstAdventure)
                {
                  participant.firstTime = participant.totActDays >= overallActDays;
                  if (!adv.staff)
                  {
                      totNewParticipants++;
                      if (boolean.valueOf(dataCells[5].getValue()))
                          participant.typeOfMember = 'Member';
                      else
                          participant.TypeOfMember = boolean.valueOf(dataCells[6].getValue()) ? 'Family/Friend' : 'Caregiver';
                  }
                    firstAdventure = false;
                }
                advs.add(adv);
            }
            participant.adventures = advs;
            if (participant.totCamp > 1 && participant.totActDays > 0 && ! participant.adventures[0].Staff)
                serialParticipants++;
            if (!advs[0].Staff) participants.add(participant);
        }
        totalParticipants = participants.size();
    }
    
    private void prepareLinesForPrinting()
    {
        integer counter = 0; // includes the header for the page
        allPages = new List<OnePage>();
        OnePage aPage = new OnePage();
        for (participantInfo pI : participants)
        {
            counter = counter + 2 + pI.adventures.size();
            if (counter > breakPoint)
            {
                breakPoint = subseqPageBrakes;
                allPages.add(aPage);
                aPage = new OnePage();
                counter = 0;
            }
            else
            {
                aPage.allParticipants.add(pI);
            }           
        }
        if (aPage.allParticipants.size() > 0) allPages.add(aPage);
        participantPages = allPages.size();
        OnePage SUpage = new OnePage(); //Pages with new-sign-ups
        counter = counter + 5; //includes the header for new-sign-ups
        sUPages = new List<OnePage>();
        integer totalLines = counter + newSignUps.size();
        newPage = false;
        boolean firstOfFirst = true;
        if (totalLines > breakPoint)
        {
            for (participantInfo pI : newSignUps)
            {
                if (counter > breakPoint)
                {
                    if (SUpage.allParticipants.size() > 0) 
                    {
                        sUpages.add(SUpage);
                        counter = 0;
                        SUpage = new OnePage();
                        firstOfFirst = false;
                    }
                    else 
                        newPage =  firstOfFirst;
                }
                else
                {
                    SUpage.allParticipants.add(pI);
                }
                
            }
            if (SUpage.allParticipants.size() > 0) sUpages.add(SUpage);
            firstOfFirst = false;
        }
        else
        {
            SUpage.allParticipants = newSignUps;
            sUpages.add(SUpage);            
        } 
    }
    
    public class OnePage{
        public List<participantInfo> allParticipants{get;set;}
        public OnePage()
        {
            this.allParticipants = new List<participantInfo>();
        }
    }

}