public class QAMonthlyController {
    public List<participantInfo> participants{get;set;}
    Public String month{get;set;}
    Public String year{get;set;}
    Public Integer totalMAD{get;set;}
    Public Integer serialParticipants{get;set;}
    Public Integer totalParticipants{get;set;}
    Public Integer totNewParticipants{get;set;}
    Public Fee__c forDate{get;set;}

    public void QAMonthlyController(){
        totalMAD = 0;
    }

    public void MonthlyQA()
    {
        forDate = new Fee__c(Effective_Date__c = date.today());
        List<String> theMonths = new String[]{'January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September','October','November', 'December'};
        totalMAD = 0;
        //get the range for the report
        String monthNum = ApexPages.currentPage().getParameters().get('m');
        month = theMonths[integer.valueOf(monthNum) - 1];
        if (monthNum.length() == 1) monthNum = '0'+ monthNum;
        year = ApexPages.currentPage().getParameters().get('y');
        String beginRange = year+'-'+ monthNum + '-01';
        Integer endOfMonth = date.daysInMonth(integer.valueOf(year), integer.valueOf(monthNum));
        system.debug('endOfMonth = ' + endOfMonth);
        system.debug('beginRange = '+beginRange);
        String endRange = year + '-' + monthNum + '-' + endOfMonth;
        system.debug('endRange = ' + endRange);
        // Get the report ID
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
        serialParticipants = 0;
        totNewParticipants = 0;
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
                integer overallActDays = integer.valueOf(dataCells[5].getValue());
                if (firstAdventure)
                {
                  participant.firstTime = participant.totActDays >= overallActDays;
                  totNewParticipants++;
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

    public class adventure{
        public String Name {get;set;}
        public String sdate {get;set;}
        public Integer ActivityDays {get;set;}
        public Boolean Attended {get;set;}
        public Boolean Staff {get;set;}
        public adventure(){}
    }
    public class participantInfo{
        public String Name {get;set;}
        public Integer totCamp {get;set;}
        public Integer totActDays {get;set;}
        public List<adventure> adventures {get;set;}
        public Boolean firstTime{get;set;}
        public participantInfo(){}
    }

}
