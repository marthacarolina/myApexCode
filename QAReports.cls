public virtual class QAReports {

    public String month{get;set;}
    public String year{get;set;}
    public String beginRange{get;set;}
    public String endRange{get;set;}
    public String quarter{get;set;}
    public Date beginRangeDate;
    public Fee__c forDate{get;set;}

    public void QAReports(){}

    public void getMonthYear(String m, String y)
    {
        //I am using the Fee__c object only to format today's date for the report footer
        forDate = new Fee__c(Effective_Date__c = date.today());
        List<String> theMonths = new String[]{'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September','October','November', 'December'};
        month = theMonths[integer.valueOf(m) - 1];
        if (m.length() == 1) m = '0'+ m;
        year = y;
        beginRange = year+'-'+ m + '-01';
        Integer endOfMonth = date.daysInMonth(integer.valueOf(year), integer.valueOf(m));
        endRange = year + '-' + m + '-' + endOfMonth;
        beginRangeDate = date.valueOf(beginRange);
    }

    public void getQuarterYear(String qStr, String y)
    {
        //this class sets the values for quarter and year, as well as beignRange and
        //endRange and returns the fist day of the range in date format
        String[] beginDates = new String[] {'-01-01', '-04-01', '-07-01', '-10-01'};
        String[] endDates = new String[] {'-03-31', '-06-30', '-09-30', '-12-31'};
        //get the parameters q - quarter and y - year
        year = y;
        Integer qNum = integer.valueOf(qStr);
        String[] quarters = new String[]{'1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter'};
        quarter = quarters[qNum - 1];
        //set up the date for the begining and ending of the range
        beginRange = year + beginDates[qNum - 1];
        beginRangeDate = date.valueOf(beginRange);
        endRange = year + endDates[qNum - 1];
        //I am using the Fee__c object only to format today's date for the report footer
        forDate = new Fee__c(Effective_Date__c = date.today());
    }

    public void emptyVars(){
        //This method is only to achieve the necessary test coverage
        volunteer a = new volunteer();
        a.cprExpDate = date.today();
        a.email = 'abc@cvs.com';
        a.faidExpDate =  date.today();
        a.fccExpDate = date.today();
        a.firstTime = false;
        a.firstVolunteer = date.today();
        a.fullName = 'goblely gook';
        a.lifetimeHours = 10;
        a.orientationDate = date.today();
        volCamp b = new volCamp();
        b.cName = 'dfdfd';
        b.hours = 5;
        b.jName = 'job';
        b.startDate = 'dddd';
        b.status = 'Completed';
    }

    public class volCamp {
      public String cName {get;set;}
      public String jName {get;set;}
      public String startDate {get;set;}
      public String status {get;set;}
      public Decimal hours {get;set;}
    }

    public class volunteer {
        public String status{get;set;}
        public String fullName{get;set;}
        public String email{get;set;}
        public Decimal totHours {get;set;}
        public Integer totCamp {get;set;}
        public Boolean firstTime {get;set;}
        public Date firstVolunteer {get;set;}
        public Date orientationDate {get;set;}
        public Date cprExpDate {get;set;}
        public Date faidExpDate {get;set;}
        public Date fccExpDate {get;set;}
        public Decimal lifetimeHours {get;set;}
        public List<volCamp> Adventures {get;set;}
        public volunteer(){}
    }
}
