public class QAquarterVolController{
    public List<volunteer> volunteers{get;set;}
    public Integer totNewVolunteers{get;set;}

    public void QAquarterVolController() {
        totNewVolunteers = 0;
    }

    public void QAquarterly()
    {
        String[] beginDates = new String[] {'-01-01', '-04-01', '-07-01', '-10-01'};
            String[] endDates = new String[] {'-03-31', '-06-30', '-09-30', '-12-31'};
                //get the parameters q - quarter and y - year
                String qStr = ApexPages.currentPage().getParameters().get('q');
        Integer qNum = integer.valueOf(qStr);
        String year = ApexPages.currentPage().getParameters().get('y');
        //set up the date for the begining and ending of the range
        String beginRange = year + beginDates[qNum - 1];
        String endRange = year + endDates[qNum - 1];
        system.debug('beginRange = '+ beginRange);
        system.debug('endRange = ' + endRange);
        List<Report> reportList = [SELECT Id, DeveloperName FROM Report where
                                    DeveloperName = 'Volunteer_Hours_QA'];
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
        // Get the down-groupings in the report in this report, the records are grouped by volunteers
        Reports.Dimension dim = results.getGroupingsDown();
        List<Reports.GroupingValue> groupingVal = dim.getGroupings();
        List<String> factMapKeys = new List<String>();
        volunteers = new List<volunteer>();
        totNewVolunteers = 0;
        //iterate over the groups in the report (each grouping is a volunteer)
        for (Reports.GroupingValue gV : groupingVal)
        {
            Boolean firstTimer = false;
            volunteer vol = new volunteer();
            System.debug('Key: ' + gV.getKey());
            vol.fullName = gv.getLabel();
            System.debug('Label: ' + vol.fullName);
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
            //total number of adventures for the participant
            //vol.totCamp = integer.valueOf(sumVal[0].getValue());
            system.debug('sumVal.size() = ' + sumVal.size());
            System.debug('SumVal[0] = ' + sumVal[0].getValue());
            //total of activity days for the month for the participant
            system.debug('sumVal[1] = ' + sumVal[1].getValue());
            //add the total of activity days for the Month for all the participants

            // Get the fields value for the grouping
            List<Reports.ReportDetailRow> detailRows = factDetails.getRows();
            //List<adventure> advs = new List<adventure>();
            Boolean firstAdventure = true;
        }
    }

    public class volunteer {
        public String fullName{get;set;}
        public String email{get;set;}
        public Decimal totHours {get;set;}
        public Integer totCamp {get;set;}
        public Date firstVolunteer {get;set;}
        public volunteer(){}
    }
}
