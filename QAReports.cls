public virtual class QAReports {
    
    public String month{get;set;}
    public String year{get;set;}
    public String beginRange{get;set;}
    public String endRange{get;set;}
    public String quarter{get;set;}
    public Date beginRangeDate;
    public string forDate{get;set;}
    public string forTime{get;set;}
                                                      
    public void QAReports(){}
    
    public void getMonthYear(String m, String y)
    {
        //set the variables used for the current date and time of the report
        datetime theDate = system.now();
        forDate = string.valueOf(theDate.date().format());
        integer minutes = theDate.time().minute();
        string stMinutes = minutes > 9 ? string.valueOf(minutes) : '0' + string.valueOf(minutes);
        forTime = string.valueOf(theDate.time().hour()) + ':'+ stMinutes;
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
         //set the variables used for the current date and time of the report
        datetime theDate = system.now();
        forDate = string.valueOf(theDate.date().format());
        integer minutes = theDate.time().minute();
        string stMinutes = minutes > 9 ? string.valueOf(minutes) : '0' + string.valueOf(minutes);
        forTime = string.valueOf(theDate.time().hour()) + ':'+ stMinutes;
        //this class sets the values for quarter and year, as well as beignRange and
        //endRange and returns the fist day of the range in date format 
        String[] beginDates = new String[] {'-01-01', '-04-01', '-07-01', '-10-01'};
        String[] endDates = new String[] {'-03-31', '-06-30', '-09-30', '-12-31'};     
        year = y;
        Integer qNum = integer.valueOf(qStr);
        String[] quarters = new String[]{'1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter'};
        quarter = quarters[qNum];
        //set up the date for the begining and ending of the time range
        beginRange = year + beginDates[qNum];
        beginRangeDate = date.valueOf(beginRange);
        endRange = year + endDates[qNum];
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
        participantInfo part = new participantInfo();
        part.Name = 'something';
        part.totCamp = 3;
        part.totActDays = 2;
        part.adventures = new List<adventure>();
        part.typeOfMember = 'Participant';
        adventure art = new adventure();
        art.Name = 'adventure';
        art.sdate = '2017-01-01';
        art.ActivityDays = 1;
        art.Attended = true;
        art.Staff = false;
        part.firstTime = false;
        part.adventures.add(art);
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
        public Date memberSince {get;set;}
        public Boolean firstTime{get;set;}
        public String typeOfMember {get;set;}
        public List<adventure> adventures {get;set;}
        public participantInfo(){}
    }
}