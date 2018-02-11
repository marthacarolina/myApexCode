@isTest
public class QAquarterVolController_Test {
    @isTest(SeeAllData='true')
    public static void QAqVC(){
        //instantiate page
        PageReference QAqReport = page.QAquarterlyVolVF;
        test.setCurrentPage(QAqReport);
        ApexPages.currentPage().getParameters().put('q', '0');
        ApexPages.currentPage().getParameters().put('y', '2017');
        QAquarterVolController controller = new QAquarterVolController();
        controller.QAquarterly();
        system.assertEquals('2017-01-01', controller.beginRange);
    }
}