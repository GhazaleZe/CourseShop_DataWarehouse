use DataWarehouse
go
create table [S_Dim_User]
(
	[user_id] INT PRIMARY KEY,
	first_name NVARCHAR(70),
	last_name NVARCHAR(70),
	phone_number VARCHAR(25),
	email_address NVARCHAR(355),
	is_email_verified BIT,
	description_verified NVARCHAR(70),
	credit int,
	datetime_signed_up DATETIME,
	username NVARCHAR(150),
	gender NVARCHAR(10) ,
	date_of_birth DATE,
)

CREATE or alter PROCEDURE S_First_Time_Fill_User_Dim
AS
BEGIN
	truncate table [S_Dim_User];
	insert into DataWarehouse.dbo.[S_Dim_User] ([user_id], first_name,last_name, phone_number ,email_address,is_email_verified,description_verified,
	datetime_signed_up,username,gender,date_of_birth) select [user_id], first_name,last_name, phone_number ,email_address,is_email_verified,
	(CASE
		WHEN   staging_area.dbo.[User].is_email_verified = 1 THEN 'Email is Verified'
		WHEN  staging_area.dbo.[User].is_email_verified = 0 THEN 'Email is not Verified'
	End),datetime_signed_up, username,gender,convert(date,date_of_birth) from staging_area.dbo.[User];
END
GO

exec S_First_Time_Fill_User_Dim

select * from [S_Dim_User]

CREATE or alter PROCEDURE S_Fill_User_Dim
AS
BEGIN
	declare @last_date_ware DATETIME;
	declare @last_date_source DATETIME;
	set @last_date_ware = (select max(DataWarehouse.dbo.S_Dim_User.datetime_signed_up) from DataWarehouse.dbo.S_Dim_User);
	set @last_date_source = (select max(staging_area.dbo.[User].datetime_signed_up) from staging_area.dbo.[User]);

	if (@last_date_ware<@last_date_source)
	begin
		insert into DataWarehouse.dbo.[S_Dim_User] ([user_id], first_name,last_name, phone_number ,email_address,is_email_verified,description_verified,
		datetime_signed_up, username,gender,date_of_birth) select [user_id], first_name,last_name, phone_number ,email_address,is_email_verified,
		(CASE
			WHEN   staging_area.dbo.[User].is_email_verified = 1 THEN 'Email is Verified'
			WHEN  staging_area.dbo.[User].is_email_verified = 0 THEN 'Email is not Verified'
		End),
		datetime_signed_up, username,gender,convert(date,date_of_birth) from staging_area.dbo.[User] where staging_area.dbo.[User].datetime_signed_up > @last_date_ware;
	end

	
END
GO

exec S_Fill_User_Dim

CREATE Or Alter Function S_Make_TimeKey (
@passdate DATETIME
)
returns nvarchar(255)
BEGIN
	declare @time_key nvarchar(255);
	if DATEPART(MONTH,@passdate) < 10 and 	DATEPART(DAY,@passdate) <10
	begin
		set @time_key = concat(concat(convert(nvarchar,(DATEPART(Year,@passdate))), concat(0,convert(nvarchar,(DATEPART(Month,@passdate))))),concat(0,convert(nvarchar,(DATEPART(Day,@passdate)))))
	end
	else if DATEPART(MONTH,@passdate) > 9 and 	DATEPART(DAY,@passdate) <10
	begin
		set @time_key = concat(concat(convert(nvarchar,(DATEPART(Year,@passdate))), convert(nvarchar,(DATEPART(Month,@passdate)))),concat(0,convert(nvarchar,(DATEPART(Day,@passdate)))))
	end

	else if DATEPART(MONTH,@passdate) < 10 and 	DATEPART(DAY,@passdate) > 9
	begin
		set @time_key = concat(concat(convert(nvarchar,(DATEPART(Year,@passdate))), concat(0,convert(nvarchar,(DATEPART(Month,@passdate))))),convert(nvarchar,(DATEPART(Day,@passdate))))
	end

	else if DATEPART(MONTH,@passdate) > 9 and 	DATEPART(DAY,@passdate) > 9
	begin
		set @time_key = concat(concat(convert(nvarchar,(DATEPART(Year,@passdate))), convert(nvarchar,(DATEPART(Month,@passdate)))),convert(nvarchar,(DATEPART(Day,@passdate))))
	end
	return @time_key
END
GO

declare @t Datetime;
 set @t = (select top 1 FullDateAlternateKey from dbo.S_Dim_Date);
select dbo.S_Make_TimeKey (@t)  
