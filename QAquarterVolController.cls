public class QAquarterVolController{
    public List<volunteer> volunteers{get;set;}
    public Integer totNewVolunteers{get;set;}
    public String quarter {get;set;}
    public Fee__c forDate{get;set;}
    public decimal qTot_Vol_Hours {get;set;}
    public Integer tot_Volunteers {get;set;}

    public void QAquarterVolController() {
        totNewVolunteers = 0;
    }

    public void QAquarterly()
    {
        totNewVolunteers = 0;
        tot_Volunteers = 0;
        qTot_Vol_Hours = 0;
        forDate = new Fee__c(Effective_Date__c = date.today());
        String[] beginDates = new String[] {'-01-01', '-04-01', '-07-01', '-10-01'};
            String[] endDates = new String[] {'-03-31', '-06-30', '-09-30', '-12-31'};
                //get the parameters q - quarter and y - year
                String qStr = ApexPages.currentPage().getParameters().get('q');
        Integer qNum = integer.valueOf(qStr);
        String[] quarters = new String[]{'1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter'};
            quarter = quarters[qNum - 1];
        system.debug('qNum = ' + qNum);
        String year = ApexPages.currentPage().getParameters().get('y');
        //set up the date for the begining and ending of the range
        String beginRange = year + beginDates[qNum - 1];
        date beginQuarter = date.valueOf(beginRange);
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
        Reports.ReportFilter filter1 = rm.getReportFilters()[0];
        Reports.ReportFilter filter2 = rm.getReportFilters()[1];
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
            tot_Volunteers++;
            volunteer vol = new volunteer();
            System.debug('Key: ' + gV.getKey());
            vol.fullName = gv.getLabel();
            System.debug('volunteer name: ' + vol.fullName);
            // Construct a fact map key, using the grouping key value
            String factMapKey = gV.getKey() + '!T';
            system.debug('factMapKey for grouping = ' + factMapKey);
            factMapKeys.add(factMapKey);

            // Get the fact map for this grouping from the report results
            Reports.ReportFactWithDetails factDetails =
                (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);

            // Get the summary amounts from the fact map it should be
            // Total Hours, Total Volunteers, Total records
            List<Reports.SummaryValue> sumVal = factDetails.getAggregates();
            system.debug('sumVal.size() = ' + sumVal.size());
            vol.totHours = (decimal) sumVal[0].getValue();
            qTot_Vol_Hours = qTot_Vol_Hours + vol.totHours;
            vol.totCamp = integer.valueOf(sumVal[2].getValue());
            // Get the fields value for the grouping
            List<Reports.ReportDetailRow> detailRows = factDetails.getRows();
            List<volCamp> advs = new List<volCamp>();
            vol.firstTime = false;
            system.debug('detailRows.size() ' + detailRows.size());
            //iterate through the rows (campaigns)
            for (Reports.ReportDetailRow row : detailRows)
            {   //get the information from each of the columns in the report
                List<Reports.ReportDataCell> dataCells = row.getDataCells();
                volCamp adv = new volCamp();
                adv.cName = dataCells[1].getLabel();
                adv.jName = dataCells[2].getLabel();
                adv.status = dataCells[3].getLabel();
                adv.startDate = dataCells[4].getLabel();
                String hrs = dataCells[5].getLabel();
                adv.hours = Decimal.valueOf(hrs);
                if (vol.firstVolunteer == null) vol.firstVolunteer = date.valueOf(dataCells[8].getValue());
                advs.add(adv);
            }
            if (vol.firstVolunteer >= beginQuarter)
            {
                vol.firstTime = true;
                totNewVolunteers++;
            }
            vol.Adventures = advs;
            volunteers.add(vol);
        }
    }

    public class volCamp {
      public String cName {get;set;}
      public String jName {get;set;}
      public String startDate {get;set;}
      public String status {get;set;}
      public Decimal hours {get;set;}
    }

    public class volunteer {
        public String fullName{get;set;}
        public String email{get;set;}
        public Decimal totHours {get;set;}
        public Integer totCamp {get;set;}
        public Boolean firstTime {get;set;}
        public Date firstVolunteer {get;set;}
        public List<volCamp> Adventures {get;set;}
        public volunteer(){}
    }
}
