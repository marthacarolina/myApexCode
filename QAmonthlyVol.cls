public class QAMonthlyVol extends QAReports {
  //this class is the controller for the VF page that prints the monthly QA report for Volunteers
    public List<volunteer> volunteers{get;set;}
    public integer totNewVolunteers{get;set;}
    public integer tot_Volunteers{get;set;}
    public Decimal mTot_Vol_Hours{get;set;}

    public void QAMonthlyVol(){}

    public void printMonthlyVol(){

        getMonthYear();
        system.debug('extension month = ' + month);
        system.debug('extension year = ' + year);
        system.debug('extension beginRange = ' + beginRange);
        system.debug('extension endRange = ' + endRange);
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
        mTot_Vol_Hours = 0;
        totNewVolunteers = 0;
        tot_Volunteers = 0;
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
            mTot_Vol_Hours = mTot_Vol_Hours + vol.totHours;
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
            if (vol.firstVolunteer >= beginRangeDate)
            {
                vol.firstTime = true;
                totNewVolunteers++;
            }
            vol.Adventures = advs;
            volunteers.add(vol);
        }
    }

}
