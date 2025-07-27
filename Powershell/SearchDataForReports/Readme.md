1.LocalTSJreport.ps1
2.SerchServersData.ps1
3.WorksAND.ps1
4.WinTickets.py

1. LocalTSJreport.ps1 - this script create local report JSON file.
- you need to send this file local to your computers/servers
- create some task with this file for work e.t. task scheduler
2. SerchServersData.ps1 - this script search data from JSON files, from all computers/servers, write all this Data to DB and remove file
- create some task with this file for work e.t. task scheduler (ONLY POWERSHELL 7)
3. WorksAND.ps1 - specific data from JIRA about tasks, write all this Data to DB
- create some task with this file for work e.t. task scheduler
4. WinTickets.py - for synch data between DB, get data about tasks from jira and send to BD for reports
- create some task with this file for work e.t. task scheduler or cron or unix