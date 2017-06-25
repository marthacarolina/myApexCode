@isTest
public class QAMonthlyVol_Test {
    @isTest(SeeAllData='true')
    public static void QAmVolTest(){
        //instantiate page
        PageReference QAmVolReport = page.QAmonthlyVolVF;
        test.setCurrentPage(QAmVolReport);
        ApexPages.currentPage().getParameters().put('m', '5');
        ApexPages.currentPage().getParameters().put('y', '2017');
        QAMonthlyVol controller = new QAMonthlyVol();
        controller.printMonthlyVol();
        system.assertEquals('2017-05-01', controller.beginRange);
    }
}
