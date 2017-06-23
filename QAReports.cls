public virtual class QAReports {
    //this is a superclass that will be extended by each report controller. This contains the common methods
    //needed in all reports
    public String month{get;set;}
    public String year{get;set;}
    public String beginRange{get;set;}
    public String endRange{get;set;}
    public String quarter{get;set;}
    public Date beginRangeDate;
    public Fee__c forDate{get;set;}

    public void QAReports(){}

    public void getMonthYear()
    {
        //I am using the Fee__c object only to format today's date for the report footer
        forDate = new Fee__c(Effective_Date__c = date.today());
        List<String> theMonths = new String[]{'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September','October','November', 'December'};
        String monthNum = ApexPages.currentPage().getParameters().get('m');
        month = theMonths[integer.valueOf(monthNum) - 1];
        if (monthNum.length() == 1) monthNum = '0'+ monthNum;
        year = ApexPages.currentPage().getParameters().get('y');
        beginRange = year+'-'+ monthNum + '-01';
        Integer endOfMonth = date.daysInMonth(integer.valueOf(year), integer.valueOf(monthNum));
        endRange = year + '-' + monthNum + '-' + endOfMonth;
        beginRangeDate = date.valueOf(beginRange);
    }

    public void getQuarterYear()
    {
        //this class sets the values for quarter and year, as well as beignRange and
        //endRange and returns the fist day of the range in date format
        String[] beginDates = new String[] {'-01-01', '-04-01', '-07-01', '-10-01'};
        String[] endDates = new String[] {'-03-31', '-06-30', '-09-30', '-12-31'};
        //get the parameters q - quarter and y - year
        String qStr = ApexPages.currentPage().getParameters().get('q');
        Integer qNum = integer.valueOf(qStr);
        String[] quarters = new String[]{'1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter'};
        quarter = quarters[qNum - 1];
        String year = ApexPages.currentPage().getParameters().get('y');
        //set up the date for the begining and ending of the range
        beginRange = year + beginDates[qNum - 1];
        beginRangeDate = date.valueOf(beginRange);
        endRange = year + endDates[qNum - 1];
        //I am using the Fee__c object only to format today's date for the report footer
        forDate = new Fee__c(Effective_Date__c = date.today());
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
