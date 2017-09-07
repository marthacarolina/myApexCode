public class QAMonthlyController extends QAReports{
    public List<participantInfo> participants{get;set;}
    public List<participantInfo> newSignUps{get;set;}
    Public Integer totalMAD{get;set;}
    Public Integer serialParticipants{get;set;}
    Public Integer totalParticipants{get;set;}
    Public Integer totNewParticipants{get;set;}
    Public Integer newSigned {get;set;}
    PUblic Integer totAllInclusiveActDays {get;set;}
    Public Date endRangeDate;

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
        totAllInclusiveActDays = TotalActivityDaysforMonth();
    }

    public List<participantInfo> ParticipantStats()
    {
        endRangeDate = date.valueOf(endRange);
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

    public integer TotalActivityDaysforMonth()
    {
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
        Reports.Dimension dim = results.getGroupingsDown();
        List<Reports.GroupingValue> groupingVal = dim.getGroupings();
        List<String> factMapKeys = new List<String>();
        Integer tots = 0;
        for (Reports.GroupingValue gV : groupingVal)
        {
            String campName = gv.getLabel();
            String factMapKey = gV.getKey() + '!T';
            Reports.ReportFactWithDetails factDetails =
                (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
            List<Reports.ReportDetailRow> detailRows = factDetails.getRows();
            List<Reports.ReportDataCell> firstRowCells = detailRows[0].getDataCells();
            date startCamp = date.valueOf(firstRowCells[0].getValue());
            date endCamp = date.valueOf(firstRowCells[1].getValue());
            Integer actDays = startCamp.daysBetween(endCamp) + 1;
            Integer campADays = detailRows.size() * actDays;
            tots = tots + campADays;
        }
        return tots;
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
        System.debug('Detail columns: ' + columnFields);
        Integer numOfColumns = columnFields.size();

        // Get report format
        System.debug('Report format: ' + rm.getReportFormat());
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
            System.debug('Key: ' + gV.getKey());
            participant.Name = gv.getLabel();
            System.debug('Label: ' + participant.Name);
            System.debug('Value: ' + gV.getValue());
            // Construct a fact map key, using the grouping key value
            String factMapKey = gV.getKey() + '!T';
            system.debug('factMapKey for grouping = ' + factMapKey);
            factMapKeys.add(factMapKey);

            // Get the fact map for this grouping from the report results
            Reports.ReportFactWithDetails factDetails =
                (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);

            // Get the summary amounts from the fact map it should be
            // Total Adventures, Total Activity Days and Total records
            List<Reports.SummaryValue> sumVal = factDetails.getAggregates();
            participant.totCamp = integer.valueOf(sumVal[0].getValue());
            System.debug('Summary Value (total campaigns): ' + participant.totCamp);
            participant.totActDays = integer.valueOf(sumVal[1].getValue());
            totalMAD = totalMAD + participant.totActDays;
            System.debug('Summary Value (total activity days for participant): ' + participant.totActDays);

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
                          participant.typeOfMember = 'Participant';
                      else
                          participant.TypeOfMember = boolean.valueOf(dataCells[6].getValue()) ? 'Family/Friend' : 'Caregiver';
                  }
                  firstAdventure = false;
                }
                advs.add(adv);
                system.debug('adventure row: Campaign '+adv.Name+' date '+adv.sdate+' actDays '+adv.ActivityDays+
                             ' attended '+adv.Attended+ ' Staff '+adv.Staff);
                //System.debug(detailRow.getDataCells()[0].getLabel());
            }
            participant.adventures = advs;
            if (participant.totCamp > 1 && participant.totActDays > 0 && ! participant.adventures[0].Staff)
                serialParticipants++;
            if (!advs[0].Staff) participants.add(participant);
        }
        totalParticipants = participants.size();
    }

}
