/**
 * @developer Vladimir Chekel (vladimir.chekel@succraft.com)
 */
public with sharing class ServiceAppointmentTriggerHandler {
    private static final EmailTemplate SERVICE_REPORT_TEMPLATE {
        get {
            if (SERVICE_REPORT_TEMPLATE == null) {
                List<EmailTemplate> emailTemplates = [
                    SELECT Id
                    FROM EmailTemplate
                    WHERE DeveloperName = 'Service_Report'
                    WITH USER_MODE
                    LIMIT 1
                ];

                if (!emailTemplates.isEmpty()) {
                    SERVICE_REPORT_TEMPLATE = emailTemplates[0];
                }
            }
            return SERVICE_REPORT_TEMPLATE;
        }
        private set;
    }

    private static final OrgWideEmailAddress DEFAULT_ORG_WIDE_EMAIL_ADDRESS {
        get {
            if (DEFAULT_ORG_WIDE_EMAIL_ADDRESS == null) {
                List<OrgWideEmailAddress> orgWideEmailAddresses = [
                    SELECT Id, Address
                    FROM OrgWideEmailAddress
                    WHERE DisplayName = 'Killem Pest'
                    WITH USER_MODE
                    LIMIT 1
                ];

                if (!orgWideEmailAddresses.isEmpty()) {
                    DEFAULT_ORG_WIDE_EMAIL_ADDRESS = orgWideEmailAddresses[0];
                }
            }
            return DEFAULT_ORG_WIDE_EMAIL_ADDRESS;
        }
        private set;
    }

    public static void sendServiceReportsEmails(
        Map<Id, ServiceAppointment> newMap,
        Map<Id, ServiceAppointment> oldMap
    ) {
        Map<Id, Id> saToContactIdMap = new Map<Id, Id>();
        Map<Id, List<String>> saToAdditionalEmailsMap = new Map<Id, List<String>>();
        Map<Id, Id> woIdToSaIdMap = new Map<Id, Id>();
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();

        for (ServiceAppointment sa : newMap.values()) {
            if (sa.Status == 'Completed' && oldMap.get(sa.Id).Status != 'Completed' && sa.ParentRecordId != null) {
                woIdToSaIdMap.put(sa.ParentRecordId, sa.Id);
                serviceAppointments.add(sa);
            }
        }

        if (!serviceAppointments.isEmpty()) {
            for (WorkOrder wo : [
                SELECT Id, ContactId, Contact.Email, Additional_Emails__c
                FROM WorkOrder
                WHERE Id IN :woIdToSaIdMap.keySet()
                WITH USER_MODE
            ]) {
                if (String.isNotBlank(wo?.Contact?.Email)) {
                    saToContactIdMap.put(woIdToSaIdMap.get(wo.Id), wo.ContactId);
                }

                List<String> additionalEmails = new List<String>();

                if (String.isNotBlank(wo.Additional_Emails__c) && !extractEmails(wo.Additional_Emails__c).isEmpty()) {
                    additionalEmails.addAll(extractEmails(wo.Additional_Emails__c));
                }

                if (!additionalEmails.isEmpty()) {
                    saToAdditionalEmailsMap.put(woIdToSaIdMap.get(wo.Id), additionalEmails);
                }
            }

            Set<Id> serviceAppointmentIds = new Set<Id>();
            serviceAppointmentIds.addAll(saToContactIdMap.keySet());
            serviceAppointmentIds.addAll(saToAdditionalEmailsMap.keySet());

            Map<Id, List<Id>> saIdToServiceReportIdsMap = new Map<Id, List<Id>>();

            for (ServiceReport serviceReport : [
                SELECT Id, ContentVersionDocumentId, ParentId
                FROM ServiceReport
                WHERE ParentId IN :serviceAppointmentIds
                WITH USER_MODE
                ORDER BY CreatedDate DESC
            ]) {
                if (!saIdToServiceReportIdsMap.containsKey(serviceReport.ParentId)) {
                    saIdToServiceReportIdsMap.put(serviceReport.ParentId, new List<Id>());
                }

                saIdToServiceReportIdsMap.get(serviceReport.ParentId).add(serviceReport.ContentVersionDocumentId);
            }

            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

            for (ServiceAppointment sa : serviceAppointments) {
                if (
                    !saIdToServiceReportIdsMap.containsKey(sa.Id) ||
                    saIdToServiceReportIdsMap.get(sa.Id) == null ||
                    saIdToServiceReportIdsMap.get(sa.Id).isEmpty()
                ) {
                    continue;
                }

                final Id contactId = saToContactIdMap.get(sa.Id);

                emailMessages.add(
                    generateSingleEmailMessage(
                        contactId,
                        saToAdditionalEmailsMap.get(sa.Id),
                        saIdToServiceReportIdsMap.get(sa.Id)
                    )
                );
            }

            if (!emailMessages.isEmpty()) {
                Messaging.sendEmail(emailMessages, false);
            }
        }
    }

    private static Messaging.SingleEmailMessage generateSingleEmailMessage(
        final Id contactId,
        List<String> toAddresses,
        List<Id> entityAttachments
    ) {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();

        emailMessage.setTemplateId(SERVICE_REPORT_TEMPLATE.Id);
        emailMessage.setOrgWideEmailAddressId(DEFAULT_ORG_WIDE_EMAIL_ADDRESS.Id);

        if (contactId != null) {
            // for contact is better to use method bellow to ignore Send Email Governor Limits
            emailMessage.setTargetObjectId(contactId);
        }

        if (toAddresses != null && !toAddresses.isEmpty()) {
            emailMessage.setToAddresses(toAddresses);
        }

        if (entityAttachments != null && !entityAttachments.isEmpty()) {
            // should also use to ignore Governor Limits
            emailMessage.setEntityAttachments(entityAttachments);
        }

        return emailMessage;
    }

    // Method to extract email addresses from a string using regex
    private static List<String> extractEmails(final String input) {
        List<String> emails = new List<String>();

        // Define the regex pattern to match email addresses
        String emailRegex = '\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b';

        // Create a pattern object
        Pattern pattern = Pattern.compile(emailRegex);

        // Create a matcher object
        Matcher matcher = pattern.matcher(input);

        // Find all matches and add them to the list
        while (matcher.find()) {
            emails.add(matcher.group());
        }

        return emails;
    }
}