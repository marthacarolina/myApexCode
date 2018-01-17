public class QAAnnualController extends QAReports {
    public List<donor> donors {get; set;}
    public string totalDonations {get; set;}
    public string totalPerAnnum {get;set;}
    public integer totalFirsts {get; set;}
    public integer totalDonors {get; set;}
    public string IsCsv {get; set;}
    public List<PageDonor> pageBrokenDonorLines {get; set;}
    //controls how many quote line items are displayed on page 1
    private Integer first_break = 40;
    //controls how many quote line items are displayed on subsequent pages
    private Integer subseq_breaks = 60;


    public void QAAnnualController(){}

    public void AnnualQA(){
        totalFirsts = 0;
        donors = AnnualDonations();
        prepareDonorLinesForPrinting();
    }

    public List<donor> AnnualDonations(){
        List<donor> allDonors = new List<donor>();
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
        Reports.Dimension dim = results.getGroupingsDown();
        List<Reports.GroupingValue> groupingVal = dim.getGroupings();
        // the number of groupings is the number of donors
        totalDonors = groupingVal.size();
        Integer tots = 0;
        for (Reports.GroupingValue gV : groupingVal)
        {
            String accountName = gv.getLabel();
            String factMapKey = gV.getKey() + '!T';
            Reports.ReportFactWithDetails factDetails =
                (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
            List<Reports.ReportDetailRow> detailRows = factDetails.getRows();
            List<Reports.ReportDataCell> firstRowCells = detailRows[0].getDataCells();
            //get the donor information from the first row of each grouping
            donor oneDonor = new donor();
            oneDonor.name = (string) firstRowCells[2].getValue();
            if (oneDonor.name == null) oneDonor.name = accountName;
            oneDonor.street = (string) firstRowCells[4].getLabel();
            oneDonor.city = (string) firstRowCells[5].getLabel();
            oneDonor.state = (string) firstRowCells[6].getLabel();
            oneDonor.zipcode = (string) firstRowCells[7].getLabel();
            oneDonor.phone = (string) firstRowCells[8].getLabel();
            oneDonor.email = (string) firstRowCells[9].getLabel();
            oneDonor.firstGift = (date) firstRowCells[10].getValue();
            if (oneDonor.firstGift >= date.valueOf(year+'-01-01') &&
               oneDonor.firstGift <= date.valueOf(year+'-12-31'))
            {
                totalFirsts = totalFirsts + 1;
            }
            //get the total donations for this account
            List<Reports.SummaryValue> sumVal = factDetails.getAggregates();
            oneDonor.totalDonation = (string) sumVal[0].getLabel();
            if (IsCsv == 'true' && oneDonor.totalDonation.contains(',')) {
                oneDonor.totalDonation = oneDonor.totalDonation.remove(',');
            }
            allDonors.add(oneDonor);
        }
        Reports.ReportFactWithDetails totals = (Reports.ReportFactWithDetails) results.getFactMap().get('T!T');
        List<Reports.SummaryValue> totVal = totals.getAggregates();
        totalPerAnnum = (string) totVal[0].getLabel();
        return allDonors;
    }

    //splits the quote lines into an approximate number of rows that can be
    //displayed per page
    private void prepareDonorLinesForPrinting()
    {
        //controls how many quote line items are displayed on page 1
        Integer first_break = 45;
        //controls how many quote line items are displayed on subsequent pages
        Integer subseq_breaks = 60;
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
