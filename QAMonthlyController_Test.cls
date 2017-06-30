@isTest
public class QAMonthlyController_Test {
    @isTest(SeeAllData='true')
    public static void QAmVolTest(){
        //instantiate page
        PageReference QAmonthlyReport = page.QAMonthlyPdfVF;
        test.setCurrentPage(QAmonthlyReport);
        ApexPages.currentPage().getParameters().put('m', '5');
        ApexPages.currentPage().getParameters().put('y', '2017');
        QAMonthlyController controller = new QAMonthlyController();
        controller.MonthlyQA();
        system.assertEquals('2017-05-01', controller.beginRange);
    }
}
