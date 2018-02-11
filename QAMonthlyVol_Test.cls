@isTest
public class QAMonthlyVol_Test {
    @isTest(SeeAllData='true')
    public static void QAmVolTest(){
        //instantiate page
        PageReference QAmVolReport = page.QAmonthlyVolVF;
        test.setCurrentPage(QAmVolReport);
        ApexPages.currentPage().getParameters().put('q', 'N');        
        ApexPages.currentPage().getParameters().put('m', '1');
        ApexPages.currentPage().getParameters().put('y', '2018');
        QAMonthlyVol controller = new QAMonthlyVol();
        controller.printMonthlyVol();
        system.assertEquals('2018-01-01', controller.beginRange);
        ApexPages.currentPage().getParameters().put('q', '0');        
        ApexPages.currentPage().getParameters().put('m', 'N');
        ApexPages.currentPage().getParameters().put('y', '2018');
        controller = new QAMonthlyVol();
        controller.printMonthlyVol();
        system.assertEquals('2018-01-01', controller.beginRange);        
    }
}