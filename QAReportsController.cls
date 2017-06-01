public class QAReportsController {
    String month = '';
    Integer nMonth = 0;
    public List<participantInfo> participants{get;set;}
    List<participantInfo> staff{get;set;}

    public QAReportsController()
    {
        String[] theMonths = new String[]{'January', 'February', 'March', 'April', 'May', 'June',
            				'July', 'August', 'September','October','November', 'December'};
        integer n = date.today().month() - 1 ;
        n = n>1? n - 1 : 12;
    }

    public PageReference test() {
        return null;
    }

    public String getMonth()
    {
        return month;
    }

    public void setMonth(String month)
    {
        if (month.contains('c-'))
            nMonth = date.today().month() + integer.valueOf(month.right(2));
        else nMonth = integer.valueOf(month);
        this.month = month;
        system.debug('month = '+month+ ' nMonth = '+nMonth);
    }

    public List<SelectOption> getItems ()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('c-0','This Month'));
        options.add(new SelectOption('c-1','Last Month'));
        options.add(new SelectOption('c-2','2 Months Ago'));
        options.add(new SelectOption('c-3','3 Months Ago'));
        options.add(new SelectOption('1','January'));
        options.add(new SelectOption('2', 'February'));
        options.add(new SelectOption('3', 'March'));
        options.add(new SelectOption('4','April'));
        options.add(new SelectOption('5','May'));
        options.add(new SelectOption('6','June'));
        options.add(new SelectOption('7','July'));
        options.add(new SelectOption('8','August'));
        options.add(new SelectOption('9','September'));
        options.add(new SelectOption('10','October'));
        options.add(new SelectOption('11','November'));
        options.add(new SelectOption('12','December'));
        return options;
    }

	public PageReference MontlyQA()
    {
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
		filter1.setValue('2017-05-01');
        filter2.setValue('2017-05-31');
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
        staff = new List<participantInfo>();
        Integer serialParticipants = 0;
        for (Reports.GroupingValue gV : groupingVal)
        {
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
            System.debug('Summary Value (total activity days): ' + participant.totActDays);

            // Get the fields value for the grouping
            List<Reports.ReportDetailRow> detailRows = factDetails.getRows();
            List<adventure> advs = new List<adventure>();
            for (Reports.ReportDetailRow dr : detailRows)
            {
            	List<Reports.ReportDataCell> dataCells = dr.getDataCells();
                adventure adv = new adventure();
            	adv.Name = dataCells[0].getLabel();
                adv.sdate = dataCells[1].getLabel();
                adv.ActivityDays = integer.valueOf(dataCells[2].getValue());
                adv.Attended = boolean.valueOf(dataCells[3].getValue());
                adv.Staff = boolean.valueOf(dataCells[4].getValue());
                advs.add(adv);
                system.debug('adventure row: Campaign '+adv.Name+' date '+adv.sdate+' actDays '+adv.ActivityDays+
                            ' attended '+adv.Attended+ ' Staff '+adv.Staff);
            	//System.debug(detailRow.getDataCells()[0].getLabel());
            }
            participant.adventures = advs;
            if (participant.totCamp > 1 && participant.totActDays > 0 && ! participant.adventures[0].Staff)
              serialParticipants++;
            if (advs[0].Staff) staff.add(participant);
            else participants.add(participant);
        }
        prepareLinesForPrinting();
        PageReference pdfPage = new PageReference('/apex/QAMonthlyPDF_VF');
		return null;
    }

    //splits the quote lines into an approximate number of rows that can be
    //displayed per page
    private void prepareLinesForPrinting()
    {
	    List<participantInfo[]> pageBrokenLines = new List<participantInfo[]>();

	    participantInfo[] pageOfLines = new participantInfo[]{};
	    Integer counter = 0;
		Integer FIRST_BREAK = 20;
        Integer SUBSEQ_BREAKS = 25;
	    boolean firstBreakFound = false;
        boolean setSubSeqBreak = false;
        Integer breakPoint = FIRST_BREAK;

	    for(participantInfo pi: participants)
	    {
           integer lines = pi.totCamp + 1;
	       if(counter + lines <= breakPoint)
	       {
	       		pageOfLines.add(pi);
	            counter = counter + lines;
	       }
 	       if(counter >= breakPoint)
 	       {
 	            if (!firstBreakFound)
 	            {
 	            	firstBreakFound = true;
                 	setSubSeqBreak  = true;
 	            }
 	            counter = 0;
 	            pageBrokenLines.add(pageOfLines);
 	            pageOfLines.clear();
 	       }
	       if(setSubSeqBreak)
           {
                breakPoint = SUBSEQ_BREAKS;
                setSubSeqBreak = false;
           }
	    }
	    //if we have finished looping and have some quotes left let's assign them
	    if(!pageOfLines.isEmpty())
            pageBrokenLines.add(pageOfLines);
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
        public List<adventure> adventures;
        public participantInfo(){}
    }

}
