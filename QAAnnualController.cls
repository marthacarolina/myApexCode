public class QAAnnualController extends QAReports {
    public List<donor> donors {get; set;}
    public integer totalDonations {get; set;} //total number of donations during time period
    public string totalPerAnnum {get;set;} // total amount of donations during time period
    public integer totalFirsts {get; set;} //total of first time donors during time period
    public integer totalDonors {get; set;} //total number of individual/household donors during time period
    public string IsCsv {get; set;} //true when the output is an exel file
    public List<PageDonor> pageBrokenDonorLines {get; set;}  //List of report pages      
    
   
    public void QAAnnualController(){}
    
    
    //this method is called from the QAannualDonorVF and the QAannualDonorExel 
    //visualforce pages
    public void AnnualQA(){
        //get the year from the parameters (in the URL)
        year = ApexPages.currentPage().getParameters().get('y');
        IsCsv = ApexPages.currentPage().getParameters().get('f');
        getMonthYear('01', year);
        endRange = year + '-12-31';        
        //call the report and populate the allDonors list with the information for
        //each household or account "Donations by Account"
        List <Report> reportList = [SELECT Id,DeveloperName FROM Report where
                                    DeveloperName = 'QA_Donors_Annual'];
        String reportId = (String)reportList.get(0).get('Id');
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
        Reports.ReportMetadata rm = describe.getReportMetadata();
        Reports.ReportFilter filter1 = rm.getReportFilters()[1];
        Reports.ReportFilter filter2 = rm.getReportFilters()[2];
        filter1.setValue(beginRange);
        filter2.setValue(endRange);
        // Run the report - syncronously
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, rm, true);
        donors = DonationsList(results, true);
        prepareDonorLinesForPrinting();
    }

    public void QuarterlyDonors()
    {

        String[] beginDates = new String[] {'-01-01', '-04-01', '-07-01', '-10-01'};
            String[] endDates = new String[] {'-03-31', '-06-30', '-09-30', '-12-31'};
                //get the parameters q - quarter and y - year
                String qStr = ApexPages.currentPage().getParameters().get('q');
        Integer qNum = integer.valueOf(qStr);
        String[] quarters = new String[]{'1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter'};
            quarter = quarters[qNum - 1];
        String year = ApexPages.currentPage().getParameters().get('y');
        //set up the date for the begining and ending of the range
        String beginRange = year + beginDates[qNum - 1];
        date beginQuarter = date.valueOf(beginRange);
        String endRange = year + endDates[qNum - 1];
        //call the report and populate the allDonors list with the information for
        //each household or account "Donations by Account"
        List <Report> reportList = [SELECT Id,DeveloperName FROM Report where
                                    DeveloperName = 'QA_Donors_Annual'];
        String reportId = (String)reportList.get(0).get('Id');
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
        Reports.ReportMetadata rm = describe.getReportMetadata();
        Reports.ReportFilter filter1 = rm.getReportFilters()[1];
        Reports.ReportFilter filter2 = rm.getReportFilters()[2];
        filter1.setValue(beginRange);
        filter2.setValue(endRange);
        // Run the report - syncronously
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, rm, true);
        donors = DonationsList(results, false);
        prepareDonorLinesForPrinting();        
    }

    //refactor this method to do either monthly or annual reports
    
    //once the report has been run with the appropriate filters this method parses the information
    public List<donor> DonationsList(Reports.ReportResults results, boolean oneYear)
    {        
        totalFirsts = 0;
        List<donor> allDonors = new List<donor>();
        List<donor> firstDonors = new List<donor>();
        Reports.Dimension dim = results.getGroupingsDown();
        List<Reports.GroupingValue> groupingVal = dim.getGroupings();
        // the number of groupings is the number of donors
        totalDonors = groupingVal.size();
        totalDonations = 0;
        Integer tots = 0;
        for (Reports.GroupingValue gV : groupingVal)
        {
            String accountName = gv.getLabel();
            String factMapKey = gV.getKey() + '!T';
            Reports.ReportFactWithDetails factDetails =
                (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
            //detailRows holds all the rows within the group. In this case all the donations
            //made by one donor during the time period.
            List<Reports.ReportDetailRow> detailRows = factDetails.getRows(); 
            totalDonations = totalDonations + detailRows.size();
            List<Reports.ReportDataCell> firstRowCells = detailRows[0].getDataCells();
            //get the donor information from the first row of each grouping
            donor oneDonor = new donor();
            donor newDonor = new donor();
            oneDonor.name = (string) firstRowCells[2].getValue();
            if (oneDonor.name == null) oneDonor.name = accountName;
            if (IsCsv == 'true' && oneDonor.name.contains(',')) {
                oneDonor.name = oneDonor.name.remove(',');
            }
            oneDonor.street = (string) firstRowCells[4].getLabel();
            oneDonor.city = (string) firstRowCells[5].getLabel();
            oneDonor.state = (string) firstRowCells[6].getLabel();
            oneDonor.zipcode = (string) firstRowCells[7].getLabel();
            oneDonor.phone = (string) firstRowCells[8].getLabel();
            oneDonor.email = (string) firstRowCells[9].getLabel();
            oneDonor.firstGift = (date) firstRowCells[10].getValue();
            if (oneDonor.firstGift >= date.valueOf(beginRange) &&  
               oneDonor.firstGift <= date.valueOf(endRange))     
            {
                totalFirsts = totalFirsts + 1;
                newDonor = oneDonor;
            }
            //get the total donations for this account
            List<Reports.SummaryValue> sumVal = factDetails.getAggregates();
            oneDonor.totalDonation = (string) sumVal[0].getLabel();

            if (IsCsv == 'true' && oneDonor.totalDonation.contains(',')) 
            {
                oneDonor.totalDonation = oneDonor.totalDonation.remove(',');
            }
            if (newDonor.name != '') 
            {
                newDonor.totalDonation = oneDonor.totalDonation;
                firstDonors.add(newDonor);
            }
            allDonors.add(oneDonor);
        }
        Reports.ReportFactWithDetails totals = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
        List<Reports.SummaryValue> totVal = totals.getAggregates();
        totalPerAnnum = (string) totVal[0].getLabel();
        if (oneYear) return allDonors;
        else return firstDonors;
    }

   
    //splits the donors into an approximate number of lines that can be 
    //displayed per page
    private void prepareDonorLinesForPrinting()
    {
        //controls how many lines are displayed on page 1
        Integer first_break = 45;
        //controls how many lines are displayed on subsequent pages
        Integer subseq_breaks = 50;
        pageBrokenDonorLines = new List<PageDonor>();
        
        PageDonor pageOfDonors = new PageDonor();
        Integer counter = 0;
        
        boolean firstBreakFound = false;
        boolean setSubSeqBreak = false;        
        Integer breakPoint = first_break;
        
        for(donor d : donors)
        {
            if(counter <= breakPoint)
            {
                pageOfDonors.ListOfDonors.add(d);

                counter++;
            }
            if(counter == breakPoint)
            {
                if (!firstBreakFound) 
                {
                    firstBreakFound = true;
                    setSubSeqBreak  = true;
                }
                counter = 0;
                pageBrokenDonorLines.add(pageOfDonors);
                pageOfDonors = new PageDonor();
            }
            if(setSubSeqBreak) 
            {
                breakPoint = subseq_breaks;
                setSubSeqBreak = false;
            }
        }
        //if we have finished looping and have some quotes left let's assign them
        if(!pageOfDonors.ListOfDonors	.isEmpty())
            pageBrokenDonorLines.add(pageOfDonors);
    }
    
    public class PageDonor{
        public List<donor> listOfDonors {get; set;}
        public PageDonor() {
            this.listOfDonors = new List<donor>();
        }
    }
    
    public class donor {
        public string name {get; set;}
        public string street {get; set;}
        public string city {get; set;}
        public string state {get; set;}
        public string zipcode {get; set;}
        public string totalDonation {get; set;}
        public string phone {get; set;}
        public string email {get; set;}
        public date firstGift {get; set;}
        public donor (){}
    }
}