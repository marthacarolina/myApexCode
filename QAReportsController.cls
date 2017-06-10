public class QAReportsController {
    //this is the controller for the Visualforce page QAreportsVF
    Public String month{get;set;}
    Integer year;
    Integer nMonth = 0;
    String[] theMonths;
    Public String MonthSel;

    public QAReportsController()
    {
        theMonths = new String[]{'January', 'February', 'March', 'April', 'May', 'June',
            				'July', 'August', 'September','October','November', 'December'};
        nMonth = date.today().month();
        month = theMonths[nMonth-1];
        year = date.today().year();
    }

    public PageReference printMonthly() {
        String pdfURL = '/apex/QAMonthlyPdfVF?m='+nMonth+'&y='+year;
        return new PageReference(pdfURL);
    }

    public String getMonthSel()
    {
        return month;
    }

    public void setMonthSel(String monthSel)
    {
        if (monthSel.contains('c-'))
        {
            nMonth = date.today().month() + integer.valueOf(monthSel.right(2));
            year = nMonth < 1 ? year-1 : year;
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

}
