public class QAReportsController {
    Public String month{get;set;}
    Integer nMonth = 0;
    Public String quarter = '';
    Integer nquarter = 0;
    Public String year{get;set;}
    Integer nyear;
    Public String monthSel;
    String[] theMonths;

    public QAReportsController()
    {
        theMonths = new String[]{'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September','October','November', 'December'};
                integer n = date.today().month() - 1 ;
        n = n>1? n - 1 : 12;
        String[] theQuarters = new String[]{'1st Quarter','2nd Quarter','3rd Quarter','4th Quarter'};
            String[] theYears = new String[]{};
                for (Integer y=2017; y<date.today().year()+1; y++)
            {
                String sy = ''+y;
                theYears.add(sy);
            }
        year = ''+date.today().year();
    }

    public PageReference printMonthly() {
        String pdfURL = '/apex/QAMonthlyPdfVF?m='+nMonth+'&y='+year;
        return new PageReference(pdfURL);
    }

    public PageReference printMonthlyStaff() {
        String pdfURL = '/apex/QAMonthlyStaffVF?m='+nMonth+'&y='+year;
        return new PageReference(pdfURL);
    }

    public PageReference pMonthlyVol() {
        String pdfURL = '/apex/QAmonthlyVolVF?m='+nMonth+'&y='+year;
        return new PageReference(pdfURL);
    }

    public PageReference pQuarterlyDonor(){
        String pdfURL = '/apex/QAquarterlyDonorVF?q='+nquarter+'&y='+year;
        return new PageReference(pdfURL);
    }

    public PageReference pAnnualDonor(){
        String pdfURL = '/apex/QAannualDonorVF?y='+year;
        return new PageReference(pdfURL);
    }

    public String getMonthSel()
    {
        if (month == null)
        {
            nMonth = date.today().month();
            integer y = date.today().year();
            y = nMonth < 1 ? y-1 : y;
            year = ''+y;
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
            year = ''+y;
            nMonth = nMonth<1 ? 12 - nMonth : nMonth;
        }
        else nMonth = integer.valueOf(monthSel);
        this.month = theMonths[nMonth-1];
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

    public String getQuarter()
    {
        if (quarter == null)
        {
            integer n = date.today().month();
            integer y = date.today().year();
            //find the current quarter
            Decimal d = n / 3 ;
            d = d.round(System.RoundingMode.CEILING);
            nQuarter = integer.valueOf(d);
            nYear = nQuarter>1 ? y : y-1;
            nQuarter = nQuarter>1 ? nQuarter - 1: 4;
            quarter = ''+nQuarter;
            year = ''+nYear;
        }
        return quarter;
    }

    public void setQuarter(String quarter)
    {
        if (quarter.contains('c-'))
        {
            Decimal d = date.today().month() / 3 ;
            d = d.round(System.RoundingMode.CEILING);
            nQuarter = integer.valueOf(d) + integer.valueOf(quarter.right(2));
        }
        else nQuarter = integer.valueOf(quarter);
        this.quarter = quarter;
        system.debug('quarter = '+quarter+ ' nQuarter = '+nQuarter);
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
