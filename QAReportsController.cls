public class QAReportsController {
    Public String month{get;set;}
    @TestVisible Integer nMonth = 0;
    Public String yearMonth {get;set;}
    Public String quarter;
    @TestVisible Integer nquarter = 0;
    Public String yearQuarter {get;set;}
    Public String year{get;set;}
    @TestVisible Integer nyear;
    Public String monthSel;
    @TestVisible String[] theMonths;

    public QAReportsController()
    {
        theMonths = new String[]{'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'};
        String a = getMonthSel();   // initializes the month and year
        quarter = currentQuarter(); // initializes the value for quarter
        year = string.valueOf(date.today().year());
    }

    public PageReference printMonthly() {
        //this method calls the Monthly Participant QA PDF report
        String pdfURL = '/apex/QAMonthlyPdfVF?m='+nMonth+'&y='+yearMonth;
        return new PageReference(pdfURL);
    }

    public PageReference printMonthlyStaff() {
        //this method calls the Monthly Staff Involvement QA PDF Report
        String pdfURL = '/apex/QAMonthlyStaffVF?m='+nMonth+'&y='+yearMonth;
        return new PageReference(pdfURL);
    }

    public PageReference pMonthlyVol() {
        //this method calls the Monthly Volunteer QA PDF report
        String pdfURL = '/apex/QAmonthlyVolVF?m='+nMonth+'&y='+yearMonth+'&q=N';
        return new PageReference(pdfURL);
    }
    
    public PageReference pQuarterlyVol()
    {
        //this method calls the Quarterly Volunteer QA PDF report
        String pdfURL = '/apex/QAmonthlyVolVF?q='+nquarter+'&y='+yearQuarter+'&m=N';
        return new PageReference(pdfURL);
    }

    public PageReference pQuarterlyDonor(){
        //this method calls the Quarterly Donor QA PDF report
        String pdfURL = '/apex/QAquarterlyDonorVF?q='+nquarter+'&y='+yearQuarter;
        return new PageReference(pdfURL);
    }

    public PageReference pAnnualDonor(){
        //this method calls the Annual Donor QA PDF report
        String pdfURL = '/apex/QAannualDonorVF?y='+year+'&f=false';
        return new PageReference(pdfURL);
    }

    public PageReference exelAnnualDonor(){
        //this method calls the Annual Donor QA CSV report
        String pdfURL = '/apex/QAannualDonorExel?y='+year+'&f=true';
        return new PageReference(pdfURL);
    }

    public String currentQuarter(){
        //this method returns the string with the current quarter for the URL
        Decimal d = date.today().month() / 3 ;
        d = d.round(System.RoundingMode.CEILING);
        Integer i = integer.valueOf(d);
        yearQuarter = string.valueOf(date.today().year());
        return string.valueOf(i);
    }

    public String getMonthSel()
    {
        //this method returns the number of the month selected by the user
        if (month == null)
        {
            nMonth = date.today().month();
            integer y = date.today().year();
            y = nMonth < 1 ? y-1 : y;
            yearMonth = ''+y;
            nMonth = nMonth<1 ? 12 - nMonth : nMonth;
            month = ''+nMonth;
        }
        return month;
    }

    public void setMonthSel(String monthSel)
    {
        if (monthSel.contains('c-'))
        {
            nMonth = date.today().month() + integer.valueOf(monthSel.right(2));
            integer y = date.today().year();
            y = nMonth < 1 ? y-1 : y;
            yearMonth = ''+y;
            nMonth = nMonth<1 ? 12 - nMonth : nMonth;
        }
        else nMonth = integer.valueOf(monthSel);
        this.month = theMonths[nMonth-1];
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

    public String getQuarter()
    {
      return quarter;
    }

    public void setQuarter(String quarter)
    {
        if (quarter.contains('c-'))
        {
            Decimal d = date.today().month() / 3 ;
            d = d.round(System.RoundingMode.CEILING);
            nQuarter = integer.valueOf(d) + integer.valueOf(quarter.right(2));
            if (nQuarter < 0)
            {
                nQuarter = 3;
                integer nYear = date.today().year() - 1;
                yearQuarter = '' + string.valueOf(nYear);
            }
        }
        else 
        {
            nQuarter = integer.valueOf(quarter) - 1;
        }
        this.quarter = quarter;
    }

    public List<SelectOption> getQuarterItems ()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('c-0','This Quarter'));
        options.add(new SelectOption('c-1','Last Quarter'));
        options.add(new SelectOption('1','1st Quarter'));
        options.add(new SelectOption('2','2nd Quarter'));
        options.add(new SelectOption('3','3rd Quarter'));
        options.add(new SelectOption('4','4th Quarter'));
        return options;
    }

    public List<SelectOption> getYearItems()
    {
        List<SelectOption> options = new List<SelectOption>();
        Integer currYear = date.today().year();
        for (Integer y = 2017; y < currYear + 1; y++ )
            options.add(new SelectOption(''+y, ''+y));
        return options;
    }
}