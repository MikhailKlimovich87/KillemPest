@isTest
private class ServiceAppointmentTriggerHandlerTest {
    @isTest
    static void sendServiceReportsEmailsTest() {
        User u = TestDataFactory.createKillemPestUser();
        System.runAs(u) {
            // Set up test data
            // Account testAccount = new Account(Name = 'Test Account');
            // insert testAccount;

            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@test.com'
                // AccountId = testAccount.Id
            );
            insert testContact;

            Date today = Date.today();

            WorkOrder testWorkOrder = new WorkOrder(
                // AccountId = testAccount.Id,
                ContactId = testContact.Id,
                Additional_Emails__c = 'additional3@test.com;additional4@test.com',
                StartDate = today,
                EndDate = today.addDays(1)
            );
            insert testWorkOrder;

            ServiceAppointment serviceAppointment = new ServiceAppointment(
                ParentRecordId = testWorkOrder.Id,
                Status = 'In Progress'
            );
            insert serviceAppointment;

            // Link the ContentDocument to the ServiceReport record
            ServiceReport sr = new ServiceReport(
                ParentId = serviceAppointment.Id,
                DocumentBody = Blob.valueOf('Test Report Body'),
                DocumentName = 'Test Report',
                DocumentContentType = 'text/calendar'
            );
            insert sr;

            Test.startTest();
            // Set up test data for ServiceAppointment
            serviceAppointment.Status = 'Completed';
            update serviceAppointment;
            Test.stopTest();

            // Verify that the email was sent
            List<EmailMessage> emailMessages = [
                SELECT Id, ToAddress, HasAttachment
                FROM EmailMessage
                WITH USER_MODE
            ];
            Assert.areEqual(1, emailMessages.size(), 'One email should be sent');
            EmailMessage emailMessage = emailMessages[0];

            Assert.isTrue(emailMessage.ToAddress.contains(testContact.Email), 'No contact email');
            Assert.isTrue(emailMessage.HasAttachment, 'Email should have attachment');
        }
    }
}