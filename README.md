# Azure Sample - Combine VM Availability Alert and Resource Graph based VM Health Status with Logic App Action

## Summary

Use LogicApp as an Alert action and decide whether to send a notification (e.g. e-mail) or not based on additional information (Azure Resource Health information in this case) when VM Availability metrics threshold is reached.

## Steps


![alt text](image.png)

1) Azure VM Availability (preview) Metric used to define Azure Alert

![alt text](image-4.png)

1.1) Alert Definition - Conditions

![alt text](image-5.png)

1.2) Azure Alerts showing VM Availability alert triggered


![alt text](image-1.png)


2) Azure Resource Graph query used to retrieve Azure VM resource health information

![alt text](image-6.png)

3) Logic App with the workflow to:
   
- Receive alert
- Query Azure Resource Graph API to retrieve Resource Health information
- Decide based on the status whether to send e-mail notification or ignore the alert

> [!NOTE]
> Logic App Workflow code is available in the [logicapp.json](logicapp.json)

![alt text](image-2.png)

1) Logic App with the workflow - Condition 

IF "VirtualMachineDeallocationInitiated" (means a user has requested VM to be stopped) then ignore the Alert

![alt text](image-3.png)

![alt text](image-7.png)

## References

- https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-logic-apps?tabs=send-email