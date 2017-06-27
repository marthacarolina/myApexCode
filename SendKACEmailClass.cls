public class SendKACEmailClass {
    public SendKACEmailClass(ApexPages.StandardController stdController) {}

    @InvocableMethod
    public static void sendReminderEmails(){
        Date expiresSoon = Date.Today() + 64;
        Date todayDate = Date.Today();
        system.debug('expiresSoon = ' + expiresSoon);
        Date sentRecently = Date.Today() - 64;
        system.debug('sentRecently = ' + sentRecently);
        List<Contact> volunteersExp = [SELECT id, FirstName, LastName, email,
                                       CPR_Certificate_Expiration_Date__c,
                                       First_Aid_Certification_Expiration_Date__c,
                                       Fingerprint_Clearance_Expiration_Date__c, ownerId
                                       FROM Contact WHERE
                                       (CPR_Certificate_Expiration_Date__c < :expiresSoon OR
                                        First_Aid_Certification_Expiration_Date__c < :expiresSoon OR
                                        Fingerprint_Clearance_Expiration_Date__c < :expiresSoon)];
        list<id> cprexpsoon = new List<id>();
        list<id> cprexpired = new List<id>();
        list<id> faexpsoon = new List<id>();
        list<id> faexpired = new List<id>();
        list<id> fccexpsoon = new List<id>();
        list<id> fccexpired = new List<id>();
        for (Contact eachVol : volunteersExp)
        {
            system.debug('Contact = ' + eachVol.FirstName);
            list<Task> Activities = new list<Task>();
            Boolean CPRreminder = false;
            Boolean FirstAidreminder = false;
            Boolean FingerprintCCreminder = false;
            Boolean CPRexpiredNotice = false;
            Boolean FAexpiredNotice = false;
            Boolean FCCexpiredNotice = false;
            Activities = [SELECT id, Whatid, Whoid, ActivityDate, Subject, Status
                          FROM Task
                          WHERE WhoId = :eachVol.id AND Status = 'Completed'
                          ORDER BY ActivityDate DESC NULLS LAST];
            If (Activities.size() > 0)
            {
                system.debug('activities query has activities');
                for (Task Act : Activities)
                {
                    system.debug('activity is ' + Act.Subject);
                    if (Act.Subject.contains('Friendly reminder'))
                    {
                        system.debug('Entered the Friendly Reminder IF');
                        system.debug('sentRecently = ' + sentRecently);
                        system.debug('Act.ActivityDate = ' + Act.ActivityDate);
                        if (! Act.Subject.contains('EXPIRED'))
                        {
                            if (Act.ActivityDate > sentRecently)
                            {
                                if (Act.Subject.contains('CPR'))
                                {CPRreminder = True;}
                                if (Act.Subject.contains('FirstAid'))
                                {FirstAidreminder = True;}
                                if (Act.Subject.contains('Fingerprint'))
                                {FingerprintCCreminder = True;}
                            }
                        }
                        Else
                        {
                            if (Act.Subject.contains('EXPIRED') &&
                                Act.ActivityDate.daysBetween(todayDate) < 730)
                            {
                                system.debug('the subject contains EXPIRED');
                                if (ACT.Subject.contains('CPR'))
                                {CPRexpiredNotice = True;}
                                if (ACT.Subject.contains('First Aid'))
                                {FAexpiredNotice = True;}
                                if (ACT.Subject.contains('Fingerprint'))
                                {FCCexpiredNotice = True;}
                            }
                        }
                    }
                }
            }

            if (eachVol.CPR_Certificate_Expiration_Date__c < todayDate)
            {
                system.debug('I am in the CPR if when exp date < today');
                system.debug('eachVol.CPR_Certificate_Expiration_Date = ' + eachVol.CPR_Certificate_Expiration_Date__c);
                if (!CPRexpiredNotice)
                {cprexpired.add(eachVol.id);}
            }
            else
            {
                if (eachVol.CPR_Certificate_Expiration_Date__c < expiresSoon
                    && !CPRreminder)
                {cprexpsoon.add(eachVol.id);}
            }
            if (eachVol.First_Aid_Certification_Expiration_Date__c < todayDate)
            {
                if (!FAexpiredNotice)
                {
                    faexpired.add(eachVol.id);
                }
            }
            else
            {
                if (eachVol.First_Aid_Certification_Expiration_Date__c < expiresSoon
                    && !FirstAidreminder)
                {faexpsoon.add(eachVol.id);}
            }
            if (eachVol.Fingerprint_Clearance_Expiration_Date__c < todayDate)
            {
                if (!FCCexpiredNotice)
                {fccexpired.add(eachVol.id);}
            }
            else
            {
                if (eachVol.Fingerprint_Clearance_Expiration_Date__c < expiresSoon &&
                    !FingerprintCCreminder)
                {fccexpsoon.add(eachVol.id);}
            }
        }
        if (!cprexpsoon.isEmpty()) 
        {SendKACEmailClass.sendEmail('CPR_exp',cprexpsoon);}
        if (!cprexpired.isEmpty())
        {SendKACEmailClass.sendEmail('CPRalreadyExp',cprexpired);}
        if (!faexpsoon.isEmpty())
        { SendKACEmailClass.sendEmail('FirstAid_exp',faexpsoon);}
        if (!faexpired.isEmpty())
        {SendKACEmailClass.sendEmail('FirstAidAlreadyExp',faexpired);}
        if (!fccexpsoon.isEmpty())
        {SendKACEmailClass.sendEmail('FingerprintCC_exp',fccexpsoon);}
        if (!fccexpired.isEmpty())
        {SendKACEmailClass.sendEmail('FCCalreadyExpired',fccexpired);}
    }

    public static void sendEmail(String templateName, List<id> recipients)
    {
        Messaging.MassEmailMessage message = new Messaging.MassEmailMessage();
        message.setTemplateId([select Id from EmailTemplate where Name = :templateName].Id);
        message.setTargetObjectIds(recipients);
        Messaging.sendEmail(new Messaging.Email[] {message}, false);
    }

}
