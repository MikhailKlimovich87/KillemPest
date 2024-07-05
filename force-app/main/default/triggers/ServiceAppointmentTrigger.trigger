trigger ServiceAppointmentTrigger on ServiceAppointment(after update) {
    ServiceAppointmentTriggerHandler.sendServiceReportsEmails(Trigger.newMap, Trigger.oldMap);
}