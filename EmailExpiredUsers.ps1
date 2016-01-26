
# Author: Vadim Smal
# email: vadim.smal@gmail.com  
# Updated: 2/27/2012
# Verson: 1.0
#
# Based on a script by Robert Stacks http://randomtechminutia.wordpress.com/2011/11/18/powershell-script-to-notify-users-of-expired-or-about-to-expire-passwords-in-active-directory/
#
# Purpose:
# Powershell script to find out a list of users
# whose password is expiring within x number of days (as specified in $days_before_expiry).
# Email notification will be sent to them reminding them that they need to change their password.
#
# Requirements:
# Quest ActiveRoles cmdlets (http://www.quest.com/powershell/activeroles-server.aspx)
# Powershell 2.0 ~ may work in 1.0 but I haven't tested it.
#
# Script must be run as a user with Permission to view AD Attributes, Domain Admin for example.
## Author: 
# URL: RandomTechMinutia.wordpress.com
# Updated: 11/15/2011
# Verson: 1.0
#
#=====================================================================================================#
#Add Snapins
Add-PSSnapin "Quest.ActiveRoles.ADManagement" -ErrorAction SilentlyContinue

#Get todays date for use in the script
$date = Get-Date

#===========================#
#User Adjustable Variables  #
#===========================#

# How many Days Advanced Warning do you want to give?
$DaysOfNotice = 7 

#Generate a Admin report?
$ReportToAdmin = $true
#$ReportToAdmin = $false

#Alert User?
$AlertUser = $true
#$AlertUser = $false

#URL for self Service
$URLToSelfService = "https://mail.YOURDOMAIN.COM"  

#Mail Server Variables
$FromAddress = "TEST@YOURDOMAIN.COM"
$RelayMailServer = "mail.YOURDOMAIN.COM"
$AdminEmailAddress = "TEST@YOURDOMAIN.COM"

#Define Search Root
$searchRoot = 'OU=BUSINESS,DC=YOURDOMAIN,DC=COM'

# Define font and font size
$font = "<font>"



$users = Get-QADUser -SearchRoot $searchRoot -Enabled -PasswordNeverExpires:$false | where {($_.PasswordExpires -lt $date.AddDays($DaysOfNotice))}


#===========================#
#Main Script                #
#===========================#

if ($ReportToAdmin -eq $true)
{
	#Headings used in the Admin Alert
	$Title="<h2><u>Password Expiration Status and Alert Report</h2></u><h4>Generated on " + $date + "</h4>"
	$Title_ExpiredNoEmail="<h3><u>Users Have Expired Passwords And No Primary SMTP to Notify Them</h3></u>"
	$Title_AboutToExpireNoEmail="<h3><u>Users Password's Is About To Expire That Have No Primary SMTP Address</h3></u>"
	$Title2="<br><br><h2><u><font color= red>No Admin Action Required - Email Sent to User</h2></u></font>"
	$Title_Expired="<h3><u>Users With Expired Passwords</h3></u>"
	$Title_AboutToExpire="<h3><u>Users Password's About To Expire</h3></u>"
	$Title_NoExpireDate="<h3><u>Users with no Expiration Date</u></h3>"
}
#For loop to report
foreach ($user in $users)
{

	 if ($user.PasswordExpires -eq $null)
	 {
	 	$UsersList_WithNoExpiration += $user.Name + " (<font color=blue>" + $user.LogonName + "</font>) does not seem to have a Expiration Date on their account.<br>"
	 }
	 Elseif ($user.PasswordExpires -ne $null)
	 {
 		#Calculate remaining days till Password Expires
 		$DaysLeft = (($user.PasswordExpires - $date).Days)

 		#Days till password expires
 		$DaysLeftTillExpire = [Math]::Abs($DaysLeft)

			#If password has expired
 			If ($DaysLeft -le 0)
			{
				#If the users don't have a primary SMTP address we'll report the problem in the Admin report
				if (($user.Email -eq $null) -and ($user.UserMustChangePassword -ne $true) -and ($ReportToAdmin -eq $true))
				{
			  	#Add it to admin list to report on it
			  	$UserList_ExpiredNoEmail += $user.name + " (<font color=blue>" + $user.LogonName + "</font>) password has expired " + $DaysLeftTillExpire + " day(s) ago</font>.  <br><br>"
				}

				#Else they have an email address and we'll add this to the admin report 
				elseif (($user.Email -ne $null) -and ($user.UserMustChangePassword -eq $true) -and ($AlertUser -eq $True))
				{
			  		if ($ReportToAdmin -eq $true)
					{
						#Add it to a list
			  			$UserList_ExpiredHasEmail += $user.name + " (<font color=blue>" + $user.LogonName + "</font>) password has expired " + $DaysLeftTillExpire + " day(s) ago</font>. <br><br>"
		  			}
				}
			}
 		 	elseif ($DaysLeft -ge 0)
			{
				#If Password is about to expire but the user doesn't have a primary address report that in the Admin report
				if (($user.Email -eq $null) -and ($user.UserMustChangePassword -ne $true) -and ($ReportToAdmin -eq $true))
				{
		  		#Add it to admin list
		  		$UserList_AboutToExpireNoEmail += $user.name + " (<font color=blue>" + $user.LogonName + "</font>) password is about to expire and has " + $DaysLeftTillExpire + " day(s) left</font>.  <br><br>"
				}
				# If there is an email address assigned to the AD Account send them a email and also report it in the admin report
				elseif (($user.Email -ne $null) -and ($user.UserMustChangePassword -ne $true) -and ($AlertUser -eq $True) )
				{
					if ($ReportToAdmin -eq $true)
					{
						#Add it to admin Report list
		    			$UserList_AboutToExpire += $user.name + "  <font color=blue>(" + $user.LogonName + "</font>) password is about to expire and has " + $DaysLeftTillExpire + " day(s) left</font>. <br><br>"
					}

					#Setup email to be sent to user
					$ToAddress = $user.Email
					$Subject = "Notice: Your Corporate Password is about to expire."
					$body = " "
					$body = $font
					$body += "Greetings, <br><br>"
					$body += "This is a auto-generated email to remind you that your password for account - <font color=red>" + $user.LogonName + "</font> - will expire in </font color = red>" + $DaysLeftTillExpire +" Day(s). <br><br>"
					$body += "To prevent furthur future logon problems, you can log on into " + $URLToSelfService + " "
					$body += "and reset the password yourself, else you are welcome to contact the Service Desk by Phone for assistance at 800-GET-HELP."
					$body += "<br><br><br><br>"
					$body += "<b>PLEASE DO NOT RESPOND TO THIS EMAIL, CALL THE HELP DESK AT 888.293.4238.</b> <br><br>"
            		$body += "<h5>Auto-Generated Message On: " + $date + ".</h5>"
	            	$body += "</font>"

#	   				Send-MailMessage -smtpServer $RelayMailServer -from $FromAddress -to $user.Email -subject $Subject -BodyAsHtml  -body $body
					
					#testing email
					$userEmail = 'TEST@YOURDOMAIN.COM'
					
	   				Send-MailMessage -smtpServer $RelayMailServer -from $FromAddress -to $userEmail -subject $Subject -BodyAsHtml  -body $body 

				}
			}
	}
} # End foreach ($user in $users)

if ($ReportToAdmin -eq $true)
{
 If ($UserList_AboutToExpire -eq $null)  {$UserList_AboutToExpire = "No Users to Report"}
 If ($UserList_AboutToExpireNoEmail -eq $null){ $UserList_AboutToExpireNoEmail = "No Users to Report"}
 if ($UserList_ExpiredHasEmail -eq $null) {$UserList_ExpiredHasEmail = "No Users to Report"}
 if ($UserList_ExpiredNoEmail -eq $null) {$UserList_ExpiredNoEmail = "No Users to Report"}
 if ($UsersList_WithNoExpiration -eq $null) {$UsersList_WithNoExpiration = "No Users to Report"}

 #Email Report to Admin
 $Subject="Password Expiration Status for " + $date + "."
 $AdminReport = $font + $Title + $Title_ExpiredNoEmail + $UserList_ExpiredNoEmail + $Title_AboutToExpireNoEmail + $UserList_AboutToExpireNoEmail + $Title_AboutToExpire + $UserList_AboutToExpire + $Title_Expired + $UserList_ExpiredHasEmail + $Title_NoExpireDate + $UsersList_WithNoExpiration + "</font>"
 Send-MailMessage -smtpServer $RelayMailServer -from $FromAddress -to $AdminEmailAddress -subject $Subject -BodyAsHtml -body $AdminReport
}

