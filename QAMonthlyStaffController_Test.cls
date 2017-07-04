//Make campaigns
List<Campaign> campaigns = new List<Campaign>();
List<RecordType> rt = [select id, Name from RecordType
                                        WHERE Name = 'Adventure' OR
                                        Name = 'Fundraising' OR
                                        Name = 'Volunteer Campaign'
                                        Order By Name];
id cRecType = rt[0].id; //adventure
String ctype = 'Camping';
for (Integer x = 0 ; x < 10 ; x++)
{
  if (x > 5) cRecType = rt[1].id;
  if (x > 3) ctype = 'Hiking';
  if (x > 6) ctype = 'Outreach';
  if (x > 8) ctype = 'Fundraising';
  Campaign camp = new Campaign(Name = 'Camp ' + x,
                              StartDate = date.newInstance(2017,1,1 + x),
                              EndDate = date.newInstance(2017, 1, 1+x),
                              RecordTypeId = cRecType,
                              Type = ctype);
  campaigns.add(camp);
}

insert campaigns;

List<Campaign> insertedCamps = [select id, Name, Related_Campaign__c From Campaign];
List<id> volIds = new List<id>();
for (Campaign c : insertedCamps)
{
  if (c.Related_Campaign__c != null && ! c.Name.contains('Volunteer'))
  {
    volIds.add(c.Related_Campaign__c);
  }
}

//insert contacts
List<Contact> contacts = new List<Contact>();
for (Integer x=0; x<20; x++)
{
  Contact cont = new Contact(FirstName = 'Test' + x,
                              LastName = 'Test ' + x);
  contacts.add(cont);
}
insert contacts;
// Insert Campaign Members
Integer y = 0;
List<CampaignMember> members = new List<CampaignMember>();
for (Campaign c : insertedCamps)
{
  String stat = 'Attended';
  If (c.RecordTypeId == rt[1].id)
    stat = 'Staff';
  else if (c.RecordTypeId == rt[2].id)
          stat = 'Completed';
  for (Integer x=0; x < 3; x++)
  {
    CampaignMember cm = new CampaignMember(ContactId = contacts[x + (3*y)].id
                                          Status = stat,
                                          CampaignId = c.id);
    members.add(cm);
  }
  y++;
}
