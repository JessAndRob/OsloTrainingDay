# The DBA in a hybrid environment
- Location: Microsoft Norway, 71 Dronning Eufemias gate 0194 Gamle Oslo Norway
- Date: Friday, September 1, 9 am to 5 pm CEST

## Agenda:

- ### 8:45-9:00 - Check-in & Networking
    - Arrive, register, grab a coffee and get ready for a full day of learning.
- ### 9:00-9:15 - Welcome & Introduction - Rob
    - Overview of the day's agenda and key objectives.
- ### 9:15-10:30 - Session 1: Introduction to Hybrid SQL Server Environments - Both of us
    - Get an overview of managing databases in a hybrid setup.
    
TODO: 
- PaaS pizza slide for IaaS - PaaS - SaaS 

#### where do you give up control ?
 - What is now missing? - OS API - SQL auth - Instance level settings - xp_cmdshell
 - where are the difficulties
 - Kendras blog post about Index maintenance on MI
 - Learning networking - Understanding communicationand authentication - AD vs AAD (or entrails or whatever it is called now)
 - Tools - SSMS ADS VS CODE sqlcmd THE PORTAL dum dumdum

difference in roles between azure infras abd data pros - being able to change stuff in portal - its good but also .....

What are the good things

upgrade immediately
scale in a moment
DR without all the pain (well)
backups and maintenance automated
Iac


 - ### 10:30-10:45 - Coffee Break
 - ### 10:45-12:00 - Session 2: Automating Tasks Using PowerShell and Community Modules - Jess
    - Learn to automate everyday tasks using PowerShell and modules like dbatools, dbachecks, and ImportExcel.
    - jess's csv user list to new thing (azure/ad whatever we decided - some task ) 
        - "every Monday you get a list of users and have to ....."

    > Slide 3 – PowerShell for SQL Server  
    How PowerShell interacts with SQL Server.  
    Demonstrate a basic SQL Server task using PowerShell.  
    I really like this idea because I always try and say that the best way to learn PowerShell s to use it for # tasks you know how to do in SSMS. So we could do stuff like  
        -  Find recovery model for a database..  with PowerShell and then compare to SSMS..  
        - Get a list of tables from on-prem dB and Azure db (or something that can be same for n-prem and cloudy)   
        - Failed jobs   
        - Ask the audience what task they can do in SSMS that we should replicate with PowerShell  
    (Also use this to demo workflow of get-command/find-dbacommand and then work through the task)  
        - Next steps – combining same results for multiple databases/servers/environments.. why you’d do it in PowerShell.
    >  Invoke-DbaAzSQLTips against our Azure SQL
and also hybrid dbatools scripts examples


- ### 12:00-13:00 - Lunch

- ### 13:00-14:15 - Session 3: Leveraging Infrastructure as Code for Your Hybrid SQL Server Estate - Rob
 - Understand the basics of Infrastructure as Code and its application in managing SQL Server databases.
 - demo create, update - destroy from CLI then talk about CI/CD - Rob 

- ### 14:15-15:30 - Session 4: Harnessing GitHub Actions and Azure Functions to Automate Workflows - Jess
    - Explore how to use GitHub Actions and Azure Functions for automated and integrated workflows.
    - https://twitter.com/david_obrien/status/1682025323976876034?s=20 good idea for use of functions

- ### 15:30-15:45 - Coffee Break

- ### 15:45-17:00 - Session 5: Case Studies and Practical Scenarios - both of us - Jess for DMM scenario 
    - Review real-world scenarios and case studies on managing hybrid environments. This session will also provide a chance to apply the day's learnings.

- ### 17:00-17:15 - Wrap Up & Closing Remarks (Jess Pomfret & Rob Sewell)
    - Recap of key takeaways from the day and final Q&A.


>Please note: The day's schedule includes breaks to refresh, refuel and network with fellow attendees and trainers. Attendees will also receive all demo scripts used during the training sessions.

