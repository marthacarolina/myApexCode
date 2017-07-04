public class SendKACEmailClass {

    public SendKACEmailClass(ApexPages.StandardController stdController) {}

    @InvocableMethod
        public static void sendReminderEmails(){
        Date expiresSoon = Date.Today() + 92;
        Date todayDate = Date.Today();
        Date sentRecently = Date.Today() - 30;
        Date twoyearsago = Date.Today() - 730;
        List<String> subjectList = new String[]{'Email: Friendly reminder: Your CPR certification on file with Daring Adventures will expire soon',
                                                'Email: Friendly reminder: Your CPR certification on file with Daring Adventures has EXPIRED',
                                                'Email: Friendly reminder: Your FirstAid certification on file with Daring Adventures will expire soon',
                                                'Email: Friendly reminder: Your First Aid certification on file with Daring Adventures has EXPIRED',
                                                'Email: Friendly reminder: Your Fingerprint Clearance Card on file with Daring Adventures will expire soon',
                                                'Email: Friendly reminder: Your Fingerprint Clearance Card on file with Daring Adventures has EXPIRED'};
        List<Contact> volunteersExp = [SELECT id, FirstName, LastName, email,
                                       CPR_Certificate_Expiration_Date__c,
                                       First_Aid_Certification_Expiration_Date__c,
                                       Fingerprint_Clearance_Expiration_Date__c,
                                       Volunteer_Orientation__c, ownerId
                                       FROM Contact WHERE
                                       (CPR_Certificate_Expiration_Date__c < :expiresSoon OR
                                        First_Aid_Certification_Expiration_Date__c < :expiresSoon OR
                                        Fingerprint_Clearance_Expiration_Date__c < :expiresSoon) AND
                                        Volunteer_Orientation__c != null];
        Map<id, Contact> volMap = new Map<id, Contact>(volunteersExp);
        List<Task> activitiesForAll = [SELECT id, Whatid, Whoid, ActivityDate, Subject, Status
                      FROM Task
                      WHERE WhoId IN :volMap.keySet() AND
                      Status = 'Completed' AND
                      Subject IN :subjectList AND
                      ActivityDate > :twoyearsago
                      ORDER BY WhoId];
        list<id> cprexpsoon = new List<id>();
        list<id> cprexpired = new List<id>();
        list<id> faexpsoon = new List<id>();
        list<id> faexpired = new List<id>();
        list<id> fccexpsoon = new List<id>();
        list<id> fccexpired = new List<id>();
        for (Contact eachVol : volunteersExp)
        {
            //system.debug('Contact = ' + eachVol.FirstName);
            list<Task> Activities = new list<Task>();
            for (Task actRecord : activitiesForAll)
            {
              if (actRecord.whoId == eachVol.id)
              Activities.add(actRecord);
            }
            Boolean CPRreminder = false;
            Boolean FirstAidreminder = false;
            Boolean FingerprintCCreminder = false;
            Boolean CPRexpiredNotice = false;
            Boolean FAexpiredNotice = false;
            Boolean FCCexpiredNotice = false;
            If (Activities.size() > 0)
            {
                for (Task Act : Activities)
                {
                    if (Act.Subject.contains('Friendly reminder'))
                    {
                        //system.debug('Entered the Friendly Reminder IF');
                        //system.debug('sentRecently = ' + sentRecently);
                        //system.debug('Act.ActivityDate = ' + Act.ActivityDate);
                        if (! Act.Subject.contains('EXPIRED'))
                        {
                            if (Act.ActivityDate > sentRecently)
                            {
                                if (Act.Subject.contains('CPR'))
                                {CPRreminder = True;
                                system.debug('CPR reminder');}
                                if (Act.Subject.contains('FirstAid'))
                                {FirstAidreminder = True;
                                system.debug('first aid reminder');}
                                if (Act.Subject.contains('Fingerprint'))
                                {FingerprintCCreminder = True;
                                system.debug('Fcc reminder');}
                            }
                        }
                        Else
                        {
                            if (Act.Subject.contains('EXPIRED') &&
                                ((Act.ActivityDate > todayDate - 730  &&
                                  Act.ActivityDate < todayDate - 92) ||
                                Act.ActivityDate > sentRecently))
                            {
                                system.debug('the subject contains EXPIRED');
                                if (ACT.Subject.contains('CPR'))
                                {CPRexpiredNotice = True;
                                system.debug('cpr expired notice');}
                                if (ACT.Subject.contains('First Aid'))
                                {FAexpiredNotice = True;
                                system.debug('FA expired notice');}
                                if (ACT.Subject.contains('Fingerprint'))
                                {FCCexpiredNotice = True;
                                system.debug('FCC expired notice');}
                            }
                        }
                    }
                }
            }

            if (eachVol.CPR_Certificate_Expiration_Date__c < todayDate)
            {
                if (!CPRexpiredNotice)
                {cprexpired.add(eachVol.id);
                system.debug('added to cpr expired');
                }
            }
            else
            {
                if (eachVol.CPR_Certificate_Expiration_Date__c < expiresSoon
                    && !CPRreminder)
                {cprexpsoon.add(eachVol.id);
                system.debug('added to cpr expires soon list');}
            }
            if (eachVol.First_Aid_Certification_Expiration_Date__c < todayDate)
            {
                if (!FAexpiredNotice)
                {
                    faexpired.add(eachVol.id);
                    system.debug('added to first aid expired');
                }
            }
            else
            {
                if (eachVol.First_Aid_Certification_Expiration_Date__c < expiresSoon
                    && !FirstAidreminder)
                {faexpsoon.add(eachVol.id);
                system.debug('added to first aid expires soon');}
            }
            if (eachVol.Fingerprint_Clearance_Expiration_Date__c < todayDate)
            {
                if (!FCCexpiredNotice)
                {fccexpired.add(eachVol.id);
                 system.debug('added to fingerprint cc expired');
                }
            }
            else
            {
                if (eachVol.Fingerprint_Clearance_Expiration_Date__c < expiresSoon &&
                    !FingerprintCCreminder)
                {fccexpsoon.add(eachVol.id);
                system.debug('added to fingerprint cc expires soon');}
            }
        }
        List<Messaging.SingleEmailMessage> messages =
            new List<Messaging.SingleEmailMessage>();

        if (!cprexpsoon.isEmpty())
        {
            messages.addAll(SendKACEmailClass.sendEmail('CPR_exp',cprexpsoon));
        }
        if (!cprexpired.isEmpty())
        {
            messages.addAll(SendKACEmailClass.sendEmail('CPRalreadyExp',cprexpired));
        }
        if (!faexpsoon.isEmpty())
        {
            messages.addAll(SendKACEmailClass.sendEmail('FirstAid_exp',faexpsoon));
        }
        if (!faexpired.isEmpty())
        {
            messages.addAll(SendKACEmailClass.sendEmail('FirstAidAlreadyExp',faexpired));
        }
        if (!fccexpsoon.isEmpty())
        {
            messages.addAll(SendKACEmailClass.sendEmail('FingerprintCC_exp',fccexpsoon));
        }
        if (!fccexpired.isEmpty())
        {
            messages.addAll(SendKACEmailClass.sendEmail('FCCalreadyExpired',fccexpired));
        }
        Messaging.sendEmail(messages);
    }

    public static List<Messaging.SingleEmailMessage> sendEmail(String templateName, List<id> recipients)
    {
        List<String> bccAddys = new List<String>();
        bccAddys.add('brenna@daring-adventures.org');
        bccAddys.add('sarah@daring-adventures.org');
        id templateId = [select Id from EmailTemplate where Name = :templateName].id;
        List<Messaging.SingleEmailMessage> messList =
            new List<Messaging.SingleEmailMessage>();
        for (id rId : recipients)
        {
          Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
          message.setBccAddresses(bccAddys);
          message.setTargetObjectId(rId);
          message.setTemplateId(templateId);
          messList.add(message);
        }
        return messList;
    }

}
