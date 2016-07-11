
This Readme Document provides an end-to-end information on the installation and operations of the BI project.
-------------------------------------------------------------------------------------------------------------


***************************************************************************************************
					PART I - INSTALLATION STEPS
***************************************************************************************************

-------------------------------
Prerequisites:-
-------------------------------
	a) SQL Server 2014 or above
	b) SQL Data tools to run SSIS packages
	c) Microsoft Excel to view PowerPivot reports.
	d) Power BI Desktop Client Application to view Power BI dashboard.

-------------------------------
Steps to install:-
-------------------------------
	1) Set up Online Sales data (OLTP source)
		- Go to the "\Installation\Deployment_Scripts" folder and Run the script "1. OnlineSalesSourceDB".
		- This script will create an "OnlineSales" DB in your SQL server along with the required tables and data.
		
	2) Set up Store Sales data (Flat File source)
		- Go to the "\Installation\Deployment_Scripts" folder.
		- Copy the Source folder(along with the source file) and paste it in "C:\" in your local desktop.
		- The final path of your source file should be C:\Source\StoreSales.txt

	3) Set up Staging Tables
		- Go to the "\Installation\Deployment_Scripts" folder
		- Run "2. Create Database EDW" script to create the EDW database which will host the Staging tables too.
		- Run "3. Create Staging Tables" scripts to create staging table under the schema "Staging".
	
`	4) Set up Data warehouse
		- Go to the "\Installation\Deployment_Scripts" folder
		- Run "4. Create DW Tables and Views" to create DW facts and dimension tables and views.
		- Run "5. Store Procedures" to create store procedures that will transform the data from Staging to DW tables.

	5) SSIS packages
		- The SSIS packages are placed under "\Installation\SSIS packages".
		- They are prescribed to run only on local server(same server as SQL server).

	6) Reports
		- All Reports are placed under the "\Reports" folder.
		- Both Reports should connect to the local EDW server and pull the data from View "vwFactOnlineSales".
			- Excel Report: "Report.xlsx" 
        	        - Power BI Dashboard: "Gadget-Mart_BI_Dashboard".


**********************************************************************************
					PART II - OPERATIONS
**********************************************************************************

NOTE: The above installation steps will load ALSO LOAD THE DATA into all the backed tables and reports and are READY TO USE. 


Following steps will be performed to refresh the data from Source-->Staging-->DW-Facts&Dimensions-->Reports

	1) Source to Staging:
		a) Run the SSIS Package: "Online_To_Staging.dtsx"  to load the Online Sales data into Staging.
		   Source: "OnlineSales" Database in local server 
		   Destination: "EDW" Database in local server(under "Staging" Schema) 

          	b) Run the SSIS Package: "Store_To_Staging.dtsx"  to load the Online Sales data into Staging.
		   Source: Source file in local server under path "C:\Source\StoreSales.txt"
		   Destination: "EDW" Database in local server

	2) Staging to DW:
		- Run the SSIS Package: "EDW-Load-Facts_Dimensions.dtsx" to refresh the Facts and Dimensions.
		  Source: EDW DB, Staging Tables.
		  Destination: EDW DB, Facts and Dimensions

	3) Refresh the Reports:
		- All Reports point to the view "vwFactOnlineSales" in EDW Database.


**********************************************************************************************************************
--------------------------------------END-----------------------------------------------------------------------------
**********************************************************************************************************************

