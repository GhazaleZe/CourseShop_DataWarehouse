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

go
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

go
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

go
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

create table S_Dim_Course
(
	course_key INT IDENTITY(1,1) PRIMARY KEY,
	course_id INT,
	title NVARCHAR(255),
	[description] NVARCHAR(MAX),
	price INT DEFAULT 0 NOT NULL,
	course_type NVARCHAR(255),
	course_level NVARCHAR(255),
	pre_req NVARCHAR(1000),
	[language] NVARCHAR(255),
	files_size INT DEFAULT 0 NOT NULL,
	how_to_download NVARCHAR(1000),
	contact_way NVARCHAR(1000),
	completion_percentage DECIMAL(5,2) DEFAULT 0,
	length_in_calendar_time NVARCHAR(255),
	[start_date] DATETIME,
	datetime_content_update DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
	datetime_created DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
	price_start_date DATETIME,
	price_end_date DATETIME,
	current_flag INT,
)


------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

go
CREATE or Alter PROCEDURE S_First_Time_Fill_Course_Dim
AS
BEGIN
	delete from DataWarehouse.dbo.S_Dim_Course
	insert into DataWarehouse.dbo.S_Dim_Course (course_id, title, [description], price, course_type, course_level, pre_req,	[language],
	files_size, how_to_download, contact_way, completion_percentage, length_in_calendar_time, [start_date], datetime_content_update, 
	datetime_created, price_start_date, price_end_date, current_flag)
	select course_id, title, [description], price, course_type, course_level, pre_req, [language],
	files_size, how_to_download, contact_way, completion_percentage,
	length_in_calendar_time, [start_date], datetime_content_update, datetime_created, '01/01/1950', NULL, 1
	from staging_area.dbo.OnlineCourse;
END
GO


exec S_First_Time_Fill_Course_Dim


------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------


go
CREATE or Alter PROCEDURE S_Fill_Course_Dim
AS
BEGIN		
		drop table if exists temp2
		create table temp2 (
			course_id INT,
			title NVARCHAR(255),
			[description] NVARCHAR(MAX),
			price INT DEFAULT 0 NOT NULL,
			course_type NVARCHAR(255),
			course_level NVARCHAR(255),
			pre_req NVARCHAR(1000),
			[language] NVARCHAR(255),
			files_size INT DEFAULT 0 NOT NULL,
			how_to_download NVARCHAR(1000),
			contact_way NVARCHAR(1000),
			completion_percentage DECIMAL(5,2) DEFAULT 0,
			length_in_calendar_time NVARCHAR(255),
			[start_date] DATETIME,
			datetime_content_update DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
			datetime_created DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
		);

		with temp1(course_id, title, [description], price, course_type, course_level, pre_req,	[language],
		files_size, how_to_download, contact_way, completion_percentage, length_in_calendar_time, [start_date], datetime_content_update, 
		datetime_created) as
		(select course_id, title, [description], price, course_type, course_level, pre_req,	[language],
		files_size, how_to_download, contact_way, completion_percentage, length_in_calendar_time, [start_date], datetime_content_update, 
		datetime_created
		from staging_area.dbo.OnlineCourse
		)
		
		insert into temp2 
		select temp1.course_id, temp1.title, temp1.[description], temp1.price, temp1.course_type, temp1.course_level, temp1.pre_req, temp1.[language],
		temp1.files_size, temp1.how_to_download, temp1.contact_way, temp1.completion_percentage, temp1.length_in_calendar_time, temp1.[start_date],
		temp1.datetime_content_update, temp1.datetime_created
		from temp1 join DataWarehouse.dbo.S_Dim_Course
		on temp1.course_id= DataWarehouse.dbo.S_Dim_Course.course_id and DataWarehouse.dbo.S_Dim_Course.current_flag=1
		where temp1.price <> DataWarehouse.dbo.S_Dim_Course.price;
		
		update DataWarehouse.dbo.S_Dim_Course
		set current_flag=0 , price_end_date=GETDATE()
		from DataWarehouse.dbo.S_Dim_Course join temp2 on (temp2.course_id= DataWarehouse.dbo.S_Dim_Course.course_id and DataWarehouse.dbo.S_Dim_Course.current_flag=1)
		
		insert into DataWarehouse.dbo.S_Dim_Course (course_id, title, [description], price, course_type, course_level, pre_req,	[language],
		files_size, how_to_download, contact_way, completion_percentage, length_in_calendar_time, [start_date], datetime_content_update, 
		datetime_created, price_start_date, price_end_date, current_flag)		
		select course_id, title, [description], price, course_type, course_level, pre_req,	[language],
		files_size, how_to_download, contact_way, completion_percentage, length_in_calendar_time, [start_date], datetime_content_update, 
		datetime_created ,GETDATE(), Null, 1
		from temp2
		drop table temp2
END
GO
exec S_Fill_Course_Dim


create table C_Dim_CourseTopic
(
	sub_topic_id INT PRIMARY KEY,
	topic_id INT,
	course_id INT,
	sub_topic_priority INT,
	topic_priority INT,
	sub_topic_title NVARCHAR(255),
    topic_title NVARCHAR(255),
	course_title NVARCHAR(255),
)


------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

go
CREATE or Alter PROCEDURE C_First_Time_Fill_CourseTopic_Dim
AS
BEGIN
	delete from DataWarehouse.dbo.C_Dim_CourseTopic;
	insert into DataWarehouse.dbo.C_Dim_CourseTopic (sub_topic_id, topic_id, course_id, sub_topic_priority, 
	topic_priority, sub_topic_title, topic_title, course_title)
	select SubTopic.sub_topic_id, SubTopic.topic_id, Topic.course_id, SubTopic.priority as sub_topic_priority, 
	Topic.priority as topic_priority, SubTopic.title as sub_topic_title, Topic.title as topic_title, OnlineCourse.title as course_title
	from (staging_area.dbo.SubTopic join staging_area.dbo.Topic on (SubTopic.topic_id=Topic.topic_id)) 
	join staging_area.dbo.OnlineCourse on (OnlineCourse.course_id=Topic.course_id)
	
END
GO


exec C_First_Time_Fill_CourseTopic_Dim

select * from DataWarehouse.dbo.C_Dim_CourseTopic




------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------


go
CREATE or Alter PROCEDURE C_Fill_CourseTopic_Dim
AS
BEGIN		
		drop table if exists temp2
		create table temp2 (
			sub_topic_id INT,
			topic_id INT,
			course_id INT,
			sub_topic_priority INT,
			topic_priority INT,
			sub_topic_title NVARCHAR(255),
			topic_title NVARCHAR(255),
			course_title NVARCHAR(255),
		);
		

	    drop table if exists temp3
		create table temp3 (
			sub_topic_id INT,
			topic_id INT,
			course_id INT,
			sub_topic_priority INT,
			topic_priority INT,
			sub_topic_title NVARCHAR(255),
			topic_title NVARCHAR(255),
			course_title NVARCHAR(255),
		);

		with temp1(sub_topic_id, topic_id, course_id, sub_topic_priority, topic_priority, sub_topic_title, topic_title,	course_title)
		as
		(select SubTopic.sub_topic_id, SubTopic.topic_id, Topic.course_id, SubTopic.priority as sub_topic_priority, 
		Topic.priority as topic_priority, SubTopic.title as sub_topic_title, Topic.title as topic_title, OnlineCourse.title as course_title
		from (staging_area.dbo.SubTopic join staging_area.dbo.Topic on (SubTopic.topic_id=Topic.topic_id)) 
		join staging_area.dbo.OnlineCourse on (OnlineCourse.course_id=Topic.course_id)
		)
		-- select * from temp1
		
		insert into temp2 
		select temp1.sub_topic_id, temp1.topic_id, temp1.course_id, temp1.sub_topic_priority, temp1.topic_priority, temp1.sub_topic_title, temp1.topic_title, temp1.course_title
		from temp1 right join DataWarehouse.dbo.C_Dim_CourseTopic
		on temp1.sub_topic_id= DataWarehouse.dbo.C_Dim_CourseTopic.sub_topic_id
		where temp1.sub_topic_priority <> DataWarehouse.dbo.C_Dim_CourseTopic.sub_topic_priority;
		-- select * from temp2

		with temp1(sub_topic_id, topic_id, course_id, sub_topic_priority, topic_priority, sub_topic_title, topic_title,	course_title)
		as
		(select SubTopic.sub_topic_id, SubTopic.topic_id, Topic.course_id, SubTopic.priority as sub_topic_priority, 
		Topic.priority as topic_priority, SubTopic.title as sub_topic_title, Topic.title as topic_title, OnlineCourse.title as course_title
		from (staging_area.dbo.SubTopic join staging_area.dbo.Topic on (SubTopic.topic_id=Topic.topic_id)) 
		join staging_area.dbo.OnlineCourse on (OnlineCourse.course_id=Topic.course_id)
		)
		insert into temp3
		select temp1.sub_topic_id, temp1.topic_id, temp1.course_id, temp1.sub_topic_priority, temp1.topic_priority, temp1.sub_topic_title, temp1.topic_title, temp1.course_title
		from temp1 left join DataWarehouse.dbo.C_Dim_CourseTopic
		on temp1.sub_topic_id= DataWarehouse.dbo.C_Dim_CourseTopic.sub_topic_id
		where DataWarehouse.dbo.C_Dim_CourseTopic.sub_topic_priority is Null;


		
		update DataWarehouse.dbo.C_Dim_CourseTopic
		set sub_topic_priority=temp2.sub_topic_priority
		from DataWarehouse.dbo.C_Dim_CourseTopic join temp2 on (temp2.sub_topic_id= DataWarehouse.dbo.C_Dim_CourseTopic.sub_topic_id)
		
		insert into DataWarehouse.dbo.C_Dim_CourseTopic (sub_topic_id, topic_id, course_id, sub_topic_priority, topic_priority, sub_topic_title, topic_title,	course_title)		
		select sub_topic_id, topic_id, course_id, sub_topic_priority, topic_priority, sub_topic_title, topic_title,	course_title
		from temp3
		drop table temp2
		drop table temp3
END
GO
exec C_Fill_CourseTopic_Dim


create table HR_Dim_Instructor
(
	inst_id INT PRIMARY KEY,
	first_name NVARCHAR(70),
	last_name NVARCHAR(70),
	email_address NVARCHAR(355),
	is_email_verified BIT DEFAULT 0,
	short_description NVARCHAR(MAX),
	[description] NVARCHAR(MAX),
	datetime_signed_up DATETIME DEFAULT CURRENT_TIMESTAMP,
	original_phone_num VARCHAR(25),
	effective_date DATETIME,
	current_phone_num VARCHAR(25)
)

create table HR_Dim_Instructor_temp1
(
	inst_id INT PRIMARY KEY,
	first_name NVARCHAR(70),
	last_name NVARCHAR(70),
	email_address NVARCHAR(355),
	is_email_verified BIT DEFAULT 0,
	short_description NVARCHAR(MAX),
	[description] NVARCHAR(MAX),
	datetime_signed_up DATETIME DEFAULT CURRENT_TIMESTAMP,
	original_phone_num VARCHAR(25),
	effective_date DATETIME,
	current_phone_num VARCHAR(25)
)
GO

create table HR_Dim_Instructor_temp2
(
	inst_id INT PRIMARY KEY,
	first_name NVARCHAR(70),
	last_name NVARCHAR(70),
	email_address NVARCHAR(355),
	is_email_verified BIT DEFAULT 0,
	short_description NVARCHAR(MAX),
	[description] NVARCHAR(MAX),
	datetime_signed_up DATETIME DEFAULT CURRENT_TIMESTAMP,
	original_phone_num VARCHAR(25),
	effective_date DATETIME,
	current_phone_num VARCHAR(25)
)
GO



CREATE OR ALTER PROCEDURE HR_First_Time_Fill_Dim_Instructor @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table DataWarehouse.dbo.HR_Dim_Instructor
	insert into DataWarehouse.dbo.HR_Dim_Instructor (inst_id, first_name, last_name, email_address, is_email_verified, short_description,
	[description], datetime_signed_up, original_phone_num, effective_date, current_phone_num)
	select inst_id, first_name, last_name, email_address, is_email_verified, short_description, [description],datetime_signed_up,
	NULL, NULL, phone_number
	from Staging_area.dbo.Instructor
END
GO

EXEC HR_First_Time_Fill_Dim_Instructor
select * from DataWarehouse.dbo.HR_Dim_Instructor

go
CREATE OR ALTER PROCEDURE HR_Fill_Dim_Instructor_SCD3 @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	if (not exists(select * from DataWarehouse.dbo.HR_Dim_Instructor))
	begin
		insert into DataWarehouse.dbo.HR_Dim_Instructor (inst_id, first_name, last_name, email_address, is_email_verified, short_description,
		[description], datetime_signed_up, original_phone_num, effective_date, current_phone_num)
		select inst_id, first_name, last_name, email_address, is_email_verified, short_description, [description],datetime_signed_up,
		NULL, NULL, phone_number
		from Staging_area.dbo.Instructor
	end
	else
	begin
		truncate table DataWarehouse.dbo.HR_Dim_Instructor_temp1
		truncate table DataWarehouse.dbo.HR_Dim_Instructor_temp2

		insert into DataWarehouse.dbo.HR_Dim_Instructor_temp1 (inst_id, first_name, last_name, email_address, is_email_verified, short_description,
		[description], datetime_signed_up, original_phone_num, effective_date, current_phone_num)
		select inst_id, first_name, last_name, email_address, is_email_verified, short_description,
		[description], datetime_signed_up, original_phone_num, effective_date, current_phone_num
		from DataWarehouse.dbo.HR_Dim_Instructor


		truncate table DataWarehouse.dbo.HR_Dim_Instructor

		insert into DataWarehouse.dbo.HR_Dim_Instructor_temp2 (inst_id, first_name, last_name, email_address, is_email_verified, short_description,
		[description], datetime_signed_up, original_phone_num, effective_date, current_phone_num)
		select 
		si.inst_id,
		si.first_name,
		si.last_name,
		si.email_address,
		si.is_email_verified,
		si.short_description,
		si.[description],
		si.datetime_signed_up,
		case 
			when si.phone_number <> dit.current_phone_num then dit.current_phone_num
			else dit.original_phone_num end,
		case
			when si.phone_number <> dit.current_phone_num then CONVERT (date, CURRENT_TIMESTAMP)
			else dit.effective_date end,
		si.phone_number
		from Staging_area.dbo.Instructor si left join DataWarehouse.dbo.HR_Dim_Instructor_temp1 dit on (si.inst_id = dit.inst_id)


		insert into DataWarehouse.dbo.HR_Dim_Instructor (inst_id, first_name, last_name, email_address, is_email_verified, short_description,
		[description], datetime_signed_up, original_phone_num, effective_date, current_phone_num)
		select inst_id, first_name, last_name, email_address, is_email_verified, short_description,
		[description], datetime_signed_up, original_phone_num, effective_date, current_phone_num
		from DataWarehouse.dbo.HR_Dim_Instructor_temp2

		truncate table DataWarehouse.dbo.HR_Dim_Instructor_temp1
		truncate table DataWarehouse.dbo.HR_Dim_Instructor_temp2
	end
END
GO

exec HR_Fill_Dim_Instructor_SCD3
select * from dbo.HR_Dim_Instructor



create table HR_Dim_Staff
(
    staff_id INT,
    first_name NVARCHAR(70),
    last_name NVARCHAR(70),
    date_of_birth DATETIME,
    email_address NVARCHAR(355),
    is_email_verified BIT,
    description_is_email_verified NVARCHAR(200),
    phone_number VARCHAR(25),
    datetime_joined DATETIME,
    gender NVARCHAR(10),
    short_description NVARCHAR(500),
    username NVARCHAR(150),
    job_title NVARCHAR(400),
    job_description NVARCHAR(1000),
)

go
CREATE or alter PROCEDURE HR_First_Time_Fill_Dim_Staff
AS
BEGIN

    TRUNCATE TABLE DataWarehouse.dbo.HR_Dim_Staff;

    insert into DataWarehouse.dbo.HR_Dim_Staff
    select s.staff_id, s.first_name, s.last_name, s.date_of_birth, s.email_address, s.is_email_verified, (
    CASE
		WHEN s.is_email_verified = 1 THEN 'Email is Verified'
		WHEN s.is_email_verified = 0 THEN 'Email is not Verified'
	End
), s.phone_number, s.datetime_joined, s.gender, s.short_description, s.username, j.job_title, j.job_description
    from staging_area.dbo.Staff s join staging_area.dbo.Job j
        on s.job_id = j.job_id

END

EXEC HR_First_Time_Fill_Dim_Staff

select *
from DataWarehouse.dbo.HR_Dim_Staff



go
CREATE or alter PROCEDURE HR_Fill_Dim_Staff
AS
BEGIN

    declare @source_last_date DATETIME;
    declare @dim_last_date DATETIME;

    set @dim_last_date = (select max(DataWarehouse.dbo.HR_Dim_Staff.datetime_joined)
    from DataWarehouse.dbo.HR_Dim_Staff);

    insert into DataWarehouse.dbo.HR_Dim_Staff
    select staff_id, first_name, last_name, date_of_birth, email_address, is_email_verified,
        (
            CASE
                WHEN s.is_email_verified = 1 THEN 'Email is Verified'
                WHEN s.is_email_verified = 0 THEN 'Email is not Verified'
            End
        ),
        phone_number, datetime_joined, gender, short_description, username, job_title, job_description
    from staging_area.dbo.Staff s join staging_area.dbo.Job j
        on s.job_id = j.job_id
    where s.datetime_joined > @dim_last_date

END

go
insert into Staging_area.dbo.Staff
values
    ('zz', 'GG', '2000-10-17', 'gg@GG.com', 1, '09118888888', '2019-01-20', '2020-01-16', 41000, 'male', 'gg staff description', 'ggGG', 3, '12347', 'afsjoiewjfawoeifjsd')


EXEC HR_Fill_Dim_Staff 

select *
from DataWarehouse.dbo.HR_Dim_Staff



go
create table HR_Dim_TicketCategory
(
	ticket_category_id INT PRIMARY KEY,
	ticket_cat_title NVARCHAR(250),
	[description] NVARCHAR(MAX)
);



go
CREATE OR ALTER PROCEDURE HR_First_Time_Fill_Dim_TicketCategory @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table DataWarehouse.dbo.HR_Dim_TicketCategory

	insert into DataWarehouse.dbo.HR_Dim_TicketCategory (ticket_category_id, ticket_cat_title, [description])
	select ticket_category_id, title, [description]
	from Staging_area.dbo.TicketCategory
END
GO

EXEC HR_First_Time_Fill_Dim_TicketCategory
select * from DataWarehouse.dbo.HR_Dim_TicketCategory
GO


CREATE OR ALTER PROCEDURE HR_Fill_Dim_TicketCategory @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table DataWarehouse.dbo.HR_Dim_TicketCategory

	insert into DataWarehouse.dbo.HR_Dim_TicketCategory (ticket_category_id, ticket_cat_title, [description])
	select ticket_category_id, title, [description]
	from Staging_area.dbo.TicketCategory
END
GO

EXEC HR_Fill_Dim_TicketCategory
select * from DataWarehouse.dbo.HR_Dim_TicketCategory
GO


select * from DataWarehouse.dbo.S_Dim_Date




-- Course_Education Mart


create table C_Fact_CourseBuying
(
    [user_id] int,
    course_id int,
    course_key int,
    time_key nvarchar(100),
    new_price money,
    current_price money
);

go
CREATE or Alter PROCEDURE C_First_Time_Fill_CourseBuying_Fact
@start_date_input date,
@end_date_input date
AS
BEGIN

    truncate table DataWarehouse.dbo.C_Fact_CourseBuying;

    declare @current_datetime Datetime;
    declare @current_date Date;
    declare @today Date;
    set @current_datetime = @start_date_input;
    set @today = @end_date_input
    set @current_date = convert(date, @current_datetime);

	while @current_date <= @today
        begin

            insert into DataWarehouse.dbo.C_Fact_CourseBuying
            select  uoc.[user_id],
                    uoc.course_id,
                    (
                        select course_key
                        from DataWarehouse.dbo.S_Dim_Course dc
                        where dc.course_id = uoc.course_id and dc.current_flag = 1
                    ) as course_key,
                    (
                        select DataWarehouse.dbo.S_Make_TimeKey (uoc.datetime_user_enrolled)
                    ) as time_key,
                    (
                        select newPrice
                        from Staging_area.dbo.UserOnlineCourse t
                        inner join Staging_area.dbo.OffPrice op
                        on t.used_off_price_id = op.off_price_id
                        where t.course_id = uoc.course_id
                        and t.[user_id] = uoc.user_id
                    ) as new_price,
                    actual_paid as current_price
                from Staging_area.dbo.UserOnlineCourse uoc
				where Convert(date, @current_date) = uoc.datetime_user_enrolled;
                        
            select @current_date = dateadd(day, 1, @current_date);
		end
        
END


exec C_First_Time_Fill_CourseBuying_Fact '2020-01-01', '2020-01-03'
select * from DataWarehouse.dbo.C_Fact_CourseBuying

go
CREATE or Alter PROCEDURE C_Fill_CourseBuying_Fact
@start_date_input date,
@end_date_input date
AS
BEGIN
    
    declare @current_datetime Datetime;
    declare @current_date Date;
    declare @today Date;
    set @current_datetime = @start_date_input;
    set @today = @end_date_input
    set @current_date = convert(date, @current_datetime);

    -- insert new data
    while @current_date <= @today
        begin
            insert into DataWarehouse.dbo.C_Fact_CourseBuying
            select  uoc.[user_id],
                    uoc.course_id,
                    (
                        select course_key
                        from DataWarehouse.dbo.S_Dim_Course dc
                        where dc.course_id = uoc.course_id and dc.current_flag = 1
                    ) as course_key,
                    (
                        DataWarehouse.dbo.S_Make_TimeKey (uoc.datetime_user_enrolled)
                    ) as time_key,
                    (
                        select newPrice
                        from Staging_area.dbo.UserOnlineCourse t
                        inner join Staging_area.dbo.OffPrice op
                        on t.used_off_price_id = op.off_price_id
                        where t.course_id = uoc.course_id
                        and t.[user_id] = uoc.user_id
                    ) as new_price,
                    uoc.actual_paid as current_price
                from Staging_area.dbo.UserOnlineCourse uoc
				where Convert(date, @current_date) = uoc.datetime_user_enrolled;
                         
            select @current_date = dateadd(day, 1, @current_date);
		end

END
GO


exec C_Fill_CourseBuying_Fact '2020-12-17', '2020-12-25'



create table C_Fact_CourseBuying_Daily
(
	course_id INT,
	course_key INT,
	number_of_enrollments INT,
	paid_amount Money, 
	discount_amount Money,
	time_key nvarchar(100),
)

go
CREATE or Alter PROCEDURE C_First_Time_Fill_CourseBuying_Daily_Fact @first_day_v Date,@today Date 
AS
BEGIN

	truncate table C_Fact_CourseBuying_Daily;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin

			drop table if exists C_Fact_CourseBuying_Temp
			create table C_Fact_CourseBuying_Temp
			(
				[user_id] INT,
				course_id INT,
				course_key INT,
				new_price Money, 
				current_price Money,
				time_key nvarchar(100),
			)
			insert into DataWarehouse.dbo.C_Fact_CourseBuying_Temp([user_id], course_id, course_key, new_price, current_price, time_key) 
			select [user_id], course_id, course_key, new_price, current_price, time_key
			from DataWarehouse.dbo.C_Fact_CourseBuying
			where (select FullDateAlternateKey from DataWarehouse.dbo.S_Dim_Date where DataWarehouse.dbo.C_Fact_CourseBuying.time_key=DataWarehouse.dbo.S_Dim_Date.TimeKey)=@passing;
			
			with t(course_id, course_key, number_of_enrollments, paid_amount, discount_amount)
			as(
			select course_key, course_id, COUNT([user_id]), SUM(ISNULL(new_price, 0)), SUM(ISNULL(current_price-new_price, 0))
			from DataWarehouse.dbo.C_Fact_CourseBuying_Temp
			group by course_key, course_id)

			insert into  C_Fact_CourseBuying_Daily(course_id, course_key, number_of_enrollments, paid_amount, discount_amount, time_key) 
			select course_id, course_key, number_of_enrollments, paid_amount, discount_amount, DataWarehouse.dbo.S_Make_TimeKey(@passing)
			from t

			drop table C_Fact_CourseBuying_Temp

		end
		
		set @passing=dateadd(day,1,@passing);
	end
	
END
GO

exec C_First_Time_Fill_CourseBuying_Daily_Fact @first_day_v = '2020-01-01', @today='2020-01-03';

select * from DataWarehouse.dbo.C_Fact_CourseBuying_Daily


go
CREATE or Alter PROCEDURE C_Fill_CourseBuying_Daily_Fact @first_day_v Date,@today Date 
AS
BEGIN

	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin

			drop table if exists C_Fact_CourseBuying_Temp
			create table C_Fact_CourseBuying_Temp
			(
				[user_id] INT,
				course_id INT,
				course_key INT,
				new_price Money, 
				current_price Money,
				time_key nvarchar(100),
			)
			insert into DataWarehouse.dbo.C_Fact_CourseBuying_Temp([user_id], course_id, course_key, new_price, current_price, time_key) 
			select [user_id], course_id, course_key, new_price, current_price, time_key
			from DataWarehouse.dbo.C_Fact_CourseBuying
			where (select FullDateAlternateKey from DataWarehouse.dbo.S_Dim_Date where DataWarehouse.dbo.C_Fact_CourseBuying.time_key=DataWarehouse.dbo.S_Dim_Date.TimeKey)=@passing;
			
			with t(course_id, course_key, number_of_enrollments, paid_amount, discount_amount)
			as(
			select course_key, course_id, COUNT(user_id), SUM(ISNULL(new_price, 0)), SUM(ISNULL(current_price-new_price, 0))
			from DataWarehouse.dbo.C_Fact_CourseBuying_Temp
			group by course_key, course_id)

			insert into  C_Fact_CourseBuying_Daily(course_id, course_key, number_of_enrollments, paid_amount, discount_amount, time_key) 
			select course_id, course_key, number_of_enrollments, paid_amount, discount_amount, DataWarehouse.dbo.S_Make_TimeKey(@passing)
			from t

			drop table C_Fact_CourseBuying_Temp

		end
		
		set @passing=dateadd(day,1,@passing);
	end
	
END
GO

exec C_Fill_CourseBuying_Daily_Fact @first_day_v = '2020-01-05', @today='2020-01-07';



create table C_Fact_CourseBuying_ACC
(
	course_id INT,
	course_key INT,
	number_of_enrollments INT,
	paid_amount Money, 
	discount_amount Money,
)


go
CREATE or Alter PROCEDURE C_First_Time_Fill_CourseBuying_ACC_Fact @first_day_v Date,@today Date 
AS
BEGIN

	truncate table C_Fact_CourseBuying_ACC;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin

			drop table if exists C_Fact_CourseBuying_Temp
			create table C_Fact_CourseBuying_Temp
			(
				[user_id] INT,
				course_id INT,
				course_key INT,
				new_price Money, 
				current_price Money,
				time_key nvarchar(100),
			)
			drop table if exists C_Fact_CourseBuying_ACC_Temp
			create table C_Fact_CourseBuying_ACC_Temp
			(
				course_id INT,
				course_key INT,
				number_of_enrollments INT,
				paid_amount Money, 
				discount_amount Money,
			)

			insert into DataWarehouse.dbo.C_Fact_CourseBuying_Temp([user_id], course_id, course_key, new_price, current_price, time_key) 
			select [user_id], course_id, course_key, new_price, current_price, time_key
			from DataWarehouse.dbo.C_Fact_CourseBuying
			where (select FullDateAlternateKey from DataWarehouse.dbo.S_Dim_Date where DataWarehouse.dbo.C_Fact_CourseBuying.time_key=DataWarehouse.dbo.S_Dim_Date.TimeKey)=@passing;
			
			with t(course_id, course_key, number_of_enrollments, paid_amount, discount_amount)
			as(
			select course_key, course_id, COUNT(user_id), SUM(ISNULL(new_price, 0)), SUM(ISNULL(current_price-new_price, 0))
			from DataWarehouse.dbo.C_Fact_CourseBuying_Temp
			group by course_key, course_id)

			insert into C_Fact_CourseBuying_ACC_Temp(course_id, course_key, number_of_enrollments, paid_amount, discount_amount) 
			select t.course_id, t.course_key, ISNULL(C_Fact_CourseBuying_ACC.number_of_enrollments, 0)+t.number_of_enrollments
			,ISNULL(C_Fact_CourseBuying_ACC.paid_amount, 0)+t.paid_amount,ISNULL(C_Fact_CourseBuying_ACC.discount_amount, 0)+t.discount_amount
			from t left join C_Fact_CourseBuying_ACC
			ON t.course_key= DataWarehouse.dbo.C_Fact_CourseBuying_ACC.course_key;

			insert into C_Fact_CourseBuying_ACC(course_id, course_key, number_of_enrollments, paid_amount, discount_amount) 
			select course_id, course_key, number_of_enrollments, paid_amount, discount_amount 
			from C_Fact_CourseBuying_ACC_Temp
			where course_key Not IN (select C_Fact_CourseBuying_ACC.course_key from DataWarehouse.dbo.C_Fact_CourseBuying_ACC);

			update C_Fact_CourseBuying_ACC
			set C_Fact_CourseBuying_ACC.number_of_enrollments=C_Fact_CourseBuying_ACC_Temp.number_of_enrollments,
			C_Fact_CourseBuying_ACC.paid_amount=C_Fact_CourseBuying_ACC_Temp.paid_amount,
			C_Fact_CourseBuying_ACC.discount_amount=C_Fact_CourseBuying_ACC_Temp.discount_amount
			from C_Fact_CourseBuying_ACC_Temp
			where C_Fact_CourseBuying_ACC.course_key IN (select C_Fact_CourseBuying_ACC_Temp.course_key from DataWarehouse.dbo.C_Fact_CourseBuying_ACC_Temp)
			and C_Fact_CourseBuying_ACC.course_key=C_Fact_CourseBuying_ACC_Temp.course_key;

			drop table C_Fact_CourseBuying_Temp
			drop table C_Fact_CourseBuying_ACC_Temp

		end
		
		set @passing=dateadd(day,1,@passing);
	end
	
END
GO

exec C_First_Time_Fill_CourseBuying_ACC_Fact @first_day_v = '2020-01-01', @today='2020-01-03';

select * from DataWarehouse.dbo.C_Fact_CourseBuying_ACC


go
CREATE or Alter PROCEDURE C_Fill_CourseBuying_ACC_Fact @first_day_v Date,@today Date 
AS
BEGIN

	-- truncate table C_Fact_CourseBuying_ACC;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin

			drop table if exists C_Fact_CourseBuying_Temp
			create table C_Fact_CourseBuying_Temp
			(
				[user_id] INT,
				course_id INT,
				course_key INT,
				new_price Money, 
				current_price Money,
				time_key nvarchar(100),
			)
			drop table if exists C_Fact_CourseBuying_ACC_Temp
			create table C_Fact_CourseBuying_ACC_Temp
			(
				course_id INT,
				course_key INT,
				number_of_enrollments INT,
				paid_amount Money, 
				discount_amount Money,
			)

			insert into DataWarehouse.dbo.C_Fact_CourseBuying_Temp([user_id], course_id, course_key, new_price, current_price, time_key) 
			select [user_id], course_id, course_key, new_price, current_price, time_key
			from DataWarehouse.dbo.C_Fact_CourseBuying
			where (select FullDateAlternateKey from DataWarehouse.dbo.S_Dim_Date where DataWarehouse.dbo.C_Fact_CourseBuying.time_key=DataWarehouse.dbo.S_Dim_Date.TimeKey)=@passing;
			
			with t(course_id, course_key, number_of_enrollments, paid_amount, discount_amount)
			as(
			select course_key, course_id, COUNT([user_id]), SUM(ISNULL(new_price, 0)), SUM(ISNULL(current_price-new_price, 0))
			from DataWarehouse.dbo.C_Fact_CourseBuying_Temp
			group by course_key, course_id)

			insert into C_Fact_CourseBuying_ACC_Temp(course_id, course_key, number_of_enrollments, paid_amount, discount_amount) 
			select t.course_id, t.course_key, ISNULL(C_Fact_CourseBuying_ACC.number_of_enrollments, 0)+t.number_of_enrollments
			,ISNULL(C_Fact_CourseBuying_ACC.paid_amount, 0)+t.paid_amount,ISNULL(C_Fact_CourseBuying_ACC.discount_amount, 0)+t.discount_amount
			from t left join C_Fact_CourseBuying_ACC
			ON t.course_key= DataWarehouse.dbo.C_Fact_CourseBuying_ACC.course_key;

			insert into C_Fact_CourseBuying_ACC(course_id, course_key, number_of_enrollments, paid_amount, discount_amount) 
			select course_id, course_key, number_of_enrollments, paid_amount, discount_amount 
			from C_Fact_CourseBuying_ACC_Temp
			where course_key Not IN (select C_Fact_CourseBuying_ACC.course_key from DataWarehouse.dbo.C_Fact_CourseBuying_ACC);

			update C_Fact_CourseBuying_ACC
			set C_Fact_CourseBuying_ACC.number_of_enrollments=C_Fact_CourseBuying_ACC_Temp.number_of_enrollments,
			C_Fact_CourseBuying_ACC.paid_amount=C_Fact_CourseBuying_ACC_Temp.paid_amount,
			C_Fact_CourseBuying_ACC.discount_amount=C_Fact_CourseBuying_ACC_Temp.discount_amount
			from C_Fact_CourseBuying_ACC_Temp
			where C_Fact_CourseBuying_ACC.course_key IN (select C_Fact_CourseBuying_ACC_Temp.course_key from DataWarehouse.dbo.C_Fact_CourseBuying_ACC_Temp)
			and C_Fact_CourseBuying_ACC.course_key=C_Fact_CourseBuying_ACC_Temp.course_key;

			drop table C_Fact_CourseBuying_Temp
			drop table C_Fact_CourseBuying_ACC_Temp

		end
		
		set @passing=dateadd(day,1,@passing);
	end
	
END
GO

exec C_Fill_CourseBuying_ACC_Fact @first_day_v = '2020-01-11', @today='2020-01-13';


create table C_Fact_CourseDownloading
(
	[user_id] INT,
	sub_topic_id INT,
	time_key nvarchar(100),
)


go
CREATE or Alter PROCEDURE C_First_Time_Fill_CourseDownloading_Fact @first_day_v Date,@today Date 
AS
BEGIN

	truncate table C_Fact_CourseDownloading;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			insert into DataWarehouse.dbo.C_Fact_CourseDownloading([user_id],sub_topic_id, time_key) 
			select staging_area.dbo.Downloaded.[user_id] ,staging_area.dbo.Downloaded.sub_topic_id , 
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.Downloaded.datetime_of_download))
			from staging_area.dbo.Downloaded
			where convert(date,staging_area.dbo.Downloaded.datetime_of_download)= @passing;
		end
		
		set @passing=dateadd(day,1,@passing);
	end
	
END
GO

exec C_First_Time_Fill_CourseDownloading_Fact @first_day_v = '2020-01-01', @today='2020-01-03';

select * from DataWarehouse.dbo.C_Fact_CourseDownloading



go
CREATE or Alter PROCEDURE C_Fill_CourseDownloading_Fact @first_day_v Date,@today Date 
AS
BEGIN

	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			insert into DataWarehouse.dbo.C_Fact_CourseDownloading([user_id],sub_topic_id, time_key) 
			select staging_area.dbo.Downloaded.[user_id] ,staging_area.dbo.Downloaded.sub_topic_id , 
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.Downloaded.datetime_of_download))
			from staging_area.dbo.Downloaded
			where convert(date,staging_area.dbo.Downloaded.datetime_of_download)= @passing;
		end
		
		set @passing=dateadd(day,1,@passing);
	end
	
END
GO

exec C_Fill_CourseDownloading_Fact @first_day_v = '2020-01-11', @today='2020-01-13';


create table C_Fact_CourseDownloading_Daily
(
	sub_topic_id INT,
	number_of_downloads INT,
	time_key nvarchar(100),
)

go
CREATE or Alter PROCEDURE C_First_Time_Fill_CourseDownloading_Daily_Fact @first_day_v Date,@today Date 
AS
BEGIN

	truncate table C_Fact_CourseDownloading_Daily;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin

			drop table if exists C_Fact_CourseDownloading_Temp
			create table C_Fact_CourseDownloading_Temp
			(
				[user_id] INT,
				sub_topic_id INT,
				time_key nvarchar(100),
			)
			insert into DataWarehouse.dbo.C_Fact_CourseDownloading_Temp([user_id], sub_topic_id, time_key) 
			select [user_id], sub_topic_id, time_key 
			from DataWarehouse.dbo.C_Fact_CourseDownloading
			where (select FullDateAlternateKey from DataWarehouse.dbo.S_Dim_Date where DataWarehouse.dbo.C_Fact_CourseDownloading.time_key=DataWarehouse.dbo.S_Dim_Date.TimeKey)=@passing;
			
			with t(sub_topic_id, number_of_downloads)
			as(
			select sub_topic_id, COUNT(ISNULL(0,[user_id]))
			from DataWarehouse.dbo.C_Fact_CourseDownloading_Temp
			group by sub_topic_id)

			insert into  C_Fact_CourseDownloading_Daily(sub_topic_id, number_of_downloads, time_key) 
			select sub_topic_id, number_of_downloads, DataWarehouse.dbo.S_Make_TimeKey(@passing)
			from t

			drop table C_Fact_CourseDownloading_Temp

		end
		
		set @passing=dateadd(day,1,@passing);
	end
	
END
GO

exec C_First_Time_Fill_CourseDownloading_Daily_Fact @first_day_v = '2020-01-01', @today='2020-01-03';

select * from DataWarehouse.dbo.C_Fact_CourseDownloading_Daily



go
CREATE or Alter PROCEDURE C_Fill_CourseDownloading_Daily_Fact @first_day_v Date,@today Date 
AS
BEGIN

	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin

			drop table if exists C_Fact_CourseDownloading_Temp
			create table C_Fact_CourseDownloading_Temp
			(
				[user_id] INT,
				sub_topic_id INT,
				time_key nvarchar(100),
			)
			insert into DataWarehouse.dbo.C_Fact_CourseDownloading_Temp([user_id], sub_topic_id, time_key) 
			select [user_id], sub_topic_id, time_key 
			from DataWarehouse.dbo.C_Fact_CourseDownloading
			where (select FullDateAlternateKey from DataWarehouse.dbo.S_Dim_Date where DataWarehouse.dbo.C_Fact_CourseDownloading.time_key=DataWarehouse.dbo.S_Dim_Date.TimeKey)=@passing;
			
			with t(sub_topic_id, number_of_downloads)
			as(
			select sub_topic_id, COUNT(ISNULL(0,user_id))
			from DataWarehouse.dbo.C_Fact_CourseDownloading_Temp
			group by sub_topic_id)

			insert into  C_Fact_CourseDownloading_Daily(sub_topic_id, number_of_downloads, time_key) 
			select sub_topic_id, number_of_downloads, DataWarehouse.dbo.S_Make_TimeKey(@passing)
			from t

			drop table C_Fact_CourseDownloading_Temp

		end
		
		set @passing=dateadd(day,1,@passing);
	end
	
END
GO

exec C_Fill_CourseDownloading_Daily_Fact @first_day_v = '2020-01-11', @today='2020-01-13';


-- User_Behavior Mart

create table U_Fact_UserRating
(
	[user_id] int,
	course_key int,
	course_id int,
	time_key nvarchar(100),
	rating decimal(3, 2),


);

create table U_user_rating_temp
(
	[user_id] int,
	course_key int,
	course_id int,
	time_key nvarchar(100),
	rating decimal(3, 2)

);



create table U_UsersMart_log
(
	log_key INT IDENTITY(1,1) PRIMARY KEY,
	number_of_rows int,
	time_when Date,
	full_time Datetime,
	fact_name nvarchar(50),
	[action] nvarchar(50)
);

create table U_Fact_Comments(
	[user_id] int,
	course_key int,
	course_id int,
	time_key nvarchar(100),
	comment_id int,
	comment_text nvarchar(MAX)
);

create table U_Fact_Comments_Temp(
	[user_id] int,
	course_key int,
	course_id int,
	time_key nvarchar(100),
	comment_id int,
	comment_text nvarchar(MAX)
);

create table U_Fact_CommentRating(
	[commenter_user_id] int,
	[voter_user_id] int,
	course_key int,
	course_id int,
	time_key nvarchar(100),
	comment_id int,
	was_it_helpful Bit,
	description_WasItHelpful nvarchar(30)
);

create table U_Fact_CommentRating_Temp(
	[commenter_user_id] int,
	[voter_user_id] int,
	course_key int,
	course_id int,
	time_key nvarchar(100),
	comment_id int,
	datetime_created datetime,
	was_it_helpful Bit,
	description_WasItHelpful nvarchar(30)
);


create table U_Fact_CommentRating_Temp2(
	[commenter_user_id] int,
	[voter_user_id] int,
	course_key int,
	course_id int,
	time_key nvarchar(100),
	comment_id int,
	was_it_helpful Bit,
	description_WasItHelpful nvarchar(30)
);

create table U_Fact_InfluentialUsers_Acc (
	commenter_user_id int,
	sum_of_comments int,
	sum_of_Feedbacks int,
	sum_of_WasItHelpful int
)

create table U_Fact_InfluentialUsers_Acc_Temp (
	commenter_user_id int,
	sum_of_comments int,
	sum_of_Feedbacks int,
	sum_of_WasItHelpful int
)

create table U_Fact_InfluentialUsers_Acc_Temp2 (
	commenter_user_id int,
	sum_of_comments int,
	sum_of_Feedbacks int,
	sum_of_WasItHelpful int
)

go
CREATE or Alter PROCEDURE U_First_Time_Fill_User_rating_fact  @first_day_v Date,@today Date 
as
begin
	truncate table U_Fact_UserRating;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			insert into DataWarehouse.dbo.U_user_rating_temp([user_id],course_id,course_key,time_key,rating) 
			select staging_area.dbo.UserOnlineCourse.[user_id] ,staging_area.dbo.UserOnlineCourse.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.UserOnlineCourse.course_id ),
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.UserOnlineCourse.datetime_of_rating)), staging_area.dbo.UserOnlineCourse.rating_num
			from staging_area.dbo.UserOnlineCourse
			where convert(date,staging_area.dbo.UserOnlineCourse.datetime_of_rating)= @passing;

			insert into DataWarehouse.dbo.U_Fact_UserRating([user_id],course_id,course_key,time_key,rating) 
			select [user_id],course_id,course_key,time_key,rating from DataWarehouse.dbo.U_user_rating_temp;

			if (select COUNT(*) from DataWarehouse.dbo.U_user_rating_temp ) > 0
			begin
				insert into DataWarehouse.dbo.U_UsersMart_log (number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.U_user_rating_temp ),@passing,GETDATE(),'U_Fact_UserRating','insert first time');
			end
			truncate table U_user_rating_temp;
			set @passing=dateadd(day,1,@passing);
			
			

		end
	end
end


exec U_First_Time_Fill_User_rating_fact @first_day_v = '2020-10-01', @today='2020-12-25';

select * from U_UsersMart_log;
select * from U_Fact_UserRating

go
CREATE or Alter PROCEDURE U_First_Time_Fill_U_Fact_Comments @first_day_v Date,@today Date 
as
begin
	truncate table U_Fact_Comments;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			insert into DataWarehouse.dbo.U_Fact_Comments_Temp([user_id],course_id,course_key,time_key,comment_id,comment_text) 
			select staging_area.dbo.Comment.[user_id] ,staging_area.dbo.Comment.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.Comment.course_id  and current_flag=1),
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.Comment.datetime_created)), staging_area.dbo.Comment.comment_id, staging_area.dbo.Comment.comment_text
			from staging_area.dbo.Comment
			where convert(date,staging_area.dbo.Comment.datetime_created)= @passing;

			insert into DataWarehouse.dbo. U_Fact_Comments([user_id],course_id,course_key,time_key,comment_id,comment_text) 
			select [user_id],course_id,course_key,time_key,comment_id,comment_text from DataWarehouse.dbo.U_Fact_Comments_Temp;

			if (select COUNT(*) from DataWarehouse.dbo.U_Fact_Comments_Temp ) > 0
			begin
				insert into DataWarehouse.dbo.U_UsersMart_log (number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.U_Fact_Comments_Temp),@passing,GETDATE(),'U_Fact_Comments','insert first time');
			end
			truncate table U_Fact_Comments_Temp;
			set @passing=dateadd(day,1,@passing);
			
			

		end
	end
end 


exec  U_First_Time_Fill_U_Fact_Comments @first_day_v = '1995-01-01', @today='2020-10-10';

select * from U_Fact_Comments
select * from U_Fact_Comments_Temp


go
CREATE or Alter PROCEDURE U_First_Time_Fill_U_Fact_CommentRating @first_day_v Date,@today Date 
as
begin
	truncate table U_Fact_CommentRating;
	truncate table U_Fact_CommentRating_Temp;
	truncate table U_Fact_CommentRating_Temp2;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	insert into DataWarehouse.dbo.U_Fact_CommentRating_Temp(commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,datetime_created,was_it_helpful ,description_WasItHelpful) 
			select staging_area.dbo.Comment.[user_id] ,staging_area.dbo.CommentVote.voter_user_id,staging_area.dbo.Comment.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.Comment.course_id  and current_flag=1),
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.CommentVote.datetime_created)), staging_area.dbo.CommentVote.comment_id,staging_area.dbo.CommentVote.datetime_created,staging_area.dbo.CommentVote.was_it_helpful, 
			case
				when was_it_helpful = 1 then 'Helpful'
				when was_it_helpful = 0 then 'Not Helpful'
			end
			from staging_area.dbo.Comment inner join staging_area.dbo.CommentVote on staging_area.dbo.Comment.comment_id = staging_area.dbo.CommentVote.comment_id;
	while @today >= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			
			insert into DataWarehouse.dbo.U_Fact_CommentRating_Temp2(commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful) 
			select commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful from DataWarehouse.dbo.U_Fact_CommentRating_Temp
			where convert(date,DataWarehouse.dbo.U_Fact_CommentRating_Temp.datetime_created) = @passing;
			insert into DataWarehouse.dbo. U_Fact_CommentRating(commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful) 
			select commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful from DataWarehouse.dbo.U_Fact_CommentRating_Temp2;

			if (select COUNT(*) from DataWarehouse.dbo.U_Fact_CommentRating_Temp2 ) > 0
			begin
				insert into DataWarehouse.dbo.U_UsersMart_log (number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.U_Fact_CommentRating_Temp2),@passing,GETDATE(),'U_Fact_CommentRating','insert first time');
			end
			
			truncate table U_Fact_CommentRating_Temp2;
			set @passing=dateadd(day,1,@passing);
			

		end
	end
	truncate table U_Fact_CommentRating_Temp;
end 

exec  U_First_Time_Fill_U_Fact_CommentRating  @first_day_v = '2020-11-01', @today='2020-11-11';

select * from U_Fact_CommentRating;

go
CREATE or Alter PROCEDURE U_First_Time_Fill_Fact_InfluentialUsers_Acc @first_day_v Date,@today Date 
as
begin
	truncate table U_Fact_InfluentialUsers_Acc;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			--insert a day from Rating
			insert into DataWarehouse.dbo.U_Fact_CommentRating_Temp2(commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful) 
			select commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful 
			from DataWarehouse.dbo.U_Fact_CommentRating
			where (select FullDateAlternateKey from DataWarehouse.dbo.S_Dim_Date where DataWarehouse.dbo.U_Fact_CommentRating.time_key=DataWarehouse.dbo.S_Dim_Date.TimeKey)=@passing;
			--add this day to previous days
			 
			with t(commenter_user_id,sum_of_comments,sum_of_Feedbacks,sum_of_WasItHelpful)
			as(
			select commenter_user_id,COUNT(ISNULL(commenter_user_id,0)),COUNT(ISNULL(was_it_helpful,0)),COUNT(CASE was_it_helpful When 1 THEN 1 ELSE Null END)
			from DataWarehouse.dbo.U_Fact_CommentRating_Temp2
			group by commenter_user_id)
			insert into  U_Fact_InfluentialUsers_Acc_Temp(commenter_user_id,sum_of_comments,sum_of_Feedbacks,sum_of_WasItHelpful) 
			select t.commenter_user_id,ISNULL(U_Fact_InfluentialUsers_Acc.sum_of_comments,0)+t.sum_of_comments
			,ISNULL(U_Fact_InfluentialUsers_Acc.sum_of_Feedbacks,0)+t.sum_of_comments,ISNULL(U_Fact_InfluentialUsers_Acc.sum_of_WasItHelpful,0)+t.sum_of_WasItHelpful
			from t left join U_Fact_InfluentialUsers_Acc 
			ON t.commenter_user_id= DataWarehouse.dbo.U_Fact_InfluentialUsers_Acc.commenter_user_id;

	
			insert into U_Fact_InfluentialUsers_Acc(commenter_user_id,sum_of_comments,sum_of_Feedbacks,sum_of_WasItHelpful) 
			select commenter_user_id,sum_of_comments,sum_of_Feedbacks,sum_of_WasItHelpful 
			from U_Fact_InfluentialUsers_Acc_Temp
			where commenter_user_id Not IN (select U_Fact_InfluentialUsers_Acc.commenter_user_id from DataWarehouse.dbo.U_Fact_InfluentialUsers_Acc);

			update U_Fact_InfluentialUsers_Acc
			set U_Fact_InfluentialUsers_Acc.sum_of_comments=U_Fact_InfluentialUsers_Acc_Temp.sum_of_comments,
			U_Fact_InfluentialUsers_Acc.sum_of_Feedbacks=U_Fact_InfluentialUsers_Acc_Temp.sum_of_Feedbacks,
			U_Fact_InfluentialUsers_Acc.sum_of_WasItHelpful=U_Fact_InfluentialUsers_Acc_Temp.sum_of_WasItHelpful
			from U_Fact_InfluentialUsers_Acc_Temp
			where U_Fact_InfluentialUsers_Acc.commenter_user_id IN (select U_Fact_InfluentialUsers_Acc_Temp.commenter_user_id from DataWarehouse.dbo.U_Fact_InfluentialUsers_Acc_Temp)
			and U_Fact_InfluentialUsers_Acc.commenter_user_id=U_Fact_InfluentialUsers_Acc_Temp.commenter_user_id;
		

			if (select COUNT(*) from U_Fact_InfluentialUsers_Acc_Temp ) > 0
			begin
				insert into DataWarehouse.dbo.U_UsersMart_log (number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from U_Fact_InfluentialUsers_Acc_Temp),@passing,GETDATE(),'U_Fact_InfluentialUsers_Acc','insert first time');
			end
			truncate table U_Fact_InfluentialUsers_Acc_Temp;
			truncate table DataWarehouse.dbo.U_Fact_CommentRating_Temp2;
			set @passing=dateadd(day,1,@passing);	

		end
	end
end 

exec  U_First_Time_Fill_Fact_InfluentialUsers_Acc  @first_day_v = '2020-11-01', @today='2020-11-11';
select * from U_Fact_InfluentialUsers_Acc;

go
CREATE or Alter PROCEDURE U_Fill_User_rating_fact  @first_day_v Date,@today Date 
as
begin
	declare @passing Date;
	declare @timekey nvarchar(255);
	while (@today> @passing)
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @today))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			insert into DataWarehouse.dbo.U_user_rating_temp([user_id],course_id,course_key,time_key,rating) 
			select staging_area.dbo.UserOnlineCourse.[user_id] ,staging_area.dbo.UserOnlineCourse.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.UserOnlineCourse.course_id),
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.UserOnlineCourse.datetime_of_rating)) , staging_area.dbo.UserOnlineCourse.rating_num
			from staging_area.dbo.UserOnlineCourse
			where convert(date,staging_area.dbo.UserOnlineCourse.datetime_of_rating)= @passing;

			insert into DataWarehouse.dbo.U_Fact_UserRating([user_id],course_id,course_key,time_key,rating) 
			select [user_id],course_id,course_key,time_key,rating from DataWarehouse.dbo.U_user_rating_temp;

			if (select COUNT(*) from DataWarehouse.dbo.U_user_rating_temp ) > 0
			begin
				insert into DataWarehouse.dbo.U_UsersMart_log (number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.U_user_rating_temp ),convert (date,@passing),GETDATE(),'U_Fact_UserRating','insert');
			end
			truncate table U_user_rating_temp;
			set @passing=dateadd(day,1,@passing);
			
			

		end
	end
end

exec U_Fill_User_rating_fact @first_day_v = '2020-12-16', @today='2020-12-20';
select * from DataWarehouse.dbo.U_Fact_UserRating

go
CREATE or Alter PROCEDURE U_Fill_U_Fact_Comments @first_day_v Date,@today Date 
as
begin
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			insert into DataWarehouse.dbo.U_Fact_Comments_Temp([user_id],course_id,course_key,time_key,comment_id,comment_text) 
			select staging_area.dbo.Comment.[user_id] ,staging_area.dbo.Comment.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.Comment.course_id  and current_flag=1),
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.Comment.datetime_created)), staging_area.dbo.Comment.comment_id, staging_area.dbo.Comment.comment_text
			from staging_area.dbo.Comment
			where convert(date,staging_area.dbo.Comment.datetime_created)= @passing;

			insert into DataWarehouse.dbo. U_Fact_Comments([user_id],course_id,course_key,time_key,comment_id,comment_text) 
			select [user_id],course_id,course_key,time_key,comment_id,comment_text from DataWarehouse.dbo.U_Fact_Comments_Temp;

			if (select COUNT(*) from DataWarehouse.dbo.U_Fact_Comments_Temp ) > 0
			begin
				insert into DataWarehouse.dbo.U_UsersMart_log (number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.U_Fact_Comments_Temp),@passing,GETDATE(),'U_Fact_Comments','insert');
			end
			truncate table U_Fact_Comments_Temp;
			set @passing=dateadd(day,1,@passing);
			
			

		end
	end
end 


exec  U_Fill_U_Fact_Comments @first_day_v = '2020-10-11', @today='2021-01-31';

select * from U_Fact_Comments

select * from U_UsersMart_log;


go
CREATE or Alter PROCEDURE U_Fill_U_Fact_CommentRating @first_day_v Date,@today Date 
as
begin
	truncate table U_Fact_CommentRating_Temp;
	truncate table U_Fact_CommentRating_Temp2;
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	insert into DataWarehouse.dbo.U_Fact_CommentRating_Temp(commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,datetime_created,was_it_helpful ,description_WasItHelpful) 
			select staging_area.dbo.Comment.[user_id] ,staging_area.dbo.CommentVote.voter_user_id,staging_area.dbo.Comment.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.Comment.course_id  and current_flag=1),
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.CommentVote.datetime_created)), staging_area.dbo.CommentVote.comment_id,staging_area.dbo.CommentVote.datetime_created,staging_area.dbo.CommentVote.was_it_helpful, 
			case
				when was_it_helpful = 1 then 'Helpful'
				when was_it_helpful = 0 then 'Not Helpful'
			end
			from staging_area.dbo.Comment inner join staging_area.dbo.CommentVote on staging_area.dbo.Comment.comment_id = staging_area.dbo.CommentVote.comment_id;
	while @today >= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			
			insert into DataWarehouse.dbo.U_Fact_CommentRating_Temp2(commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful) 
			select commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful from DataWarehouse.dbo.U_Fact_CommentRating_Temp
			where convert(date,DataWarehouse.dbo.U_Fact_CommentRating_Temp.datetime_created) = @passing;
			insert into DataWarehouse.dbo. U_Fact_CommentRating(commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful) 
			select commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful from DataWarehouse.dbo.U_Fact_CommentRating_Temp2;

			if (select COUNT(*) from DataWarehouse.dbo.U_Fact_CommentRating_Temp2 ) > 0
			begin
				insert into DataWarehouse.dbo.U_UsersMart_log (number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.U_Fact_CommentRating_Temp2),@passing,GETDATE(),'U_Fact_CommentRating','insert');
			end
			
			truncate table U_Fact_CommentRating_Temp2;
			set @passing=dateadd(day,1,@passing);
			

		end
	end
	truncate table U_Fact_CommentRating_Temp;
end 
exec  U_Fill_U_Fact_CommentRating  @first_day_v = '2020-11-12', @today='2021-01-31';


go
CREATE or Alter PROCEDURE U_Fill_Fact_InfluentialUsers_Acc @first_day_v Date,@today Date 
as
begin
	declare @passing Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	while @today>= @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			--insert a day from Rating
			insert into DataWarehouse.dbo.U_Fact_CommentRating_Temp2(commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful) 
			select commenter_user_id,voter_user_id,course_id,course_key,time_key,comment_id,was_it_helpful ,description_WasItHelpful 
			from DataWarehouse.dbo.U_Fact_CommentRating
			where (select FullDateAlternateKey from DataWarehouse.dbo.S_Dim_Date where DataWarehouse.dbo.U_Fact_CommentRating.time_key=DataWarehouse.dbo.S_Dim_Date.TimeKey)=@passing;
			--add this day to previous days
			 
			with t(commenter_user_id,sum_of_comments,sum_of_Feedbacks,sum_of_WasItHelpful)
			as(
			select commenter_user_id,COUNT(commenter_user_id),COUNT(was_it_helpful),COUNT(CASE was_it_helpful When 1 THEN 1 ELSE Null END)
			from DataWarehouse.dbo.U_Fact_CommentRating_Temp2
			group by commenter_user_id)
			insert into  U_Fact_InfluentialUsers_Acc_Temp(commenter_user_id,sum_of_comments,sum_of_Feedbacks,sum_of_WasItHelpful) 
			select t.commenter_user_id,ISNULL(U_Fact_InfluentialUsers_Acc.sum_of_comments,0)+t.sum_of_comments
			,ISNULL(U_Fact_InfluentialUsers_Acc.sum_of_Feedbacks,0)+t.sum_of_comments,ISNULL(U_Fact_InfluentialUsers_Acc.sum_of_WasItHelpful,0)+t.sum_of_WasItHelpful
			from t left join U_Fact_InfluentialUsers_Acc 
			ON t.commenter_user_id= DataWarehouse.dbo.U_Fact_InfluentialUsers_Acc.commenter_user_id;

				insert into U_Fact_InfluentialUsers_Acc(commenter_user_id,sum_of_comments,sum_of_Feedbacks,sum_of_WasItHelpful) 
			select commenter_user_id,sum_of_comments,sum_of_Feedbacks,sum_of_WasItHelpful 
			from U_Fact_InfluentialUsers_Acc_Temp
			where commenter_user_id Not IN (select U_Fact_InfluentialUsers_Acc.commenter_user_id from DataWarehouse.dbo.U_Fact_InfluentialUsers_Acc);

			update U_Fact_InfluentialUsers_Acc
			set U_Fact_InfluentialUsers_Acc.sum_of_comments=U_Fact_InfluentialUsers_Acc_Temp.sum_of_comments,
			U_Fact_InfluentialUsers_Acc.sum_of_Feedbacks=U_Fact_InfluentialUsers_Acc_Temp.sum_of_Feedbacks,
			U_Fact_InfluentialUsers_Acc.sum_of_WasItHelpful=U_Fact_InfluentialUsers_Acc_Temp.sum_of_WasItHelpful
			from U_Fact_InfluentialUsers_Acc_Temp
			where U_Fact_InfluentialUsers_Acc.commenter_user_id IN (select U_Fact_InfluentialUsers_Acc_Temp.commenter_user_id from DataWarehouse.dbo.U_Fact_InfluentialUsers_Acc_Temp)
			and U_Fact_InfluentialUsers_Acc.commenter_user_id=U_Fact_InfluentialUsers_Acc_Temp.commenter_user_id;

			

			if (select COUNT(*) from U_Fact_InfluentialUsers_Acc_Temp ) > 0
			begin
				insert into DataWarehouse.dbo.U_UsersMart_log (number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from U_Fact_InfluentialUsers_Acc_Temp),@passing,GETDATE(),'U_Fact_InfluentialUsers_Acc','insert');
			end
			truncate table U_Fact_InfluentialUsers_Acc_Temp;
			truncate table DataWarehouse.dbo.U_Fact_CommentRating_Temp2;
			set @passing=dateadd(day,1,@passing);	

		end
	end
end 

exec  U_Fill_Fact_InfluentialUsers_Acc  @first_day_v = '2020-11-12', @today='2021-01-31';

 select * from U_Fact_InfluentialUsers_Acc;


 
create table U_Fact_PassedCourses
(
    [user_id] INT,
    course_id INT,
    course_key INT,
    grade Decimal(5,2),
    time_key nvarchar(255)
)


go
CREATE OR Alter PROCEDURE U_First_Time_Fill_PassedCourses_Fact_T
    @start_date_input date,
    @end_date_input date
AS
BEGIN
    TRUNCATE TABLE U_Fact_PassedCourses;

    declare @current_datetime Datetime;
    declare @current_date Date;
    declare @today Date;
    set @current_datetime = @start_date_input;
    set @today = @end_date_input
    set @current_date = convert(date, @current_datetime);

    WHILE @current_date <= @today
    BEGIN

        if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @current_date))
		begin
            set @current_date = dateadd(day, 1, @current_date);
        end

		else 
		begin
        
            insert into U_Fact_PassedCourses
            select 
                uoc.[user_id], 
                uoc.course_id, 
                (
                    select course_key
                    from DataWarehouse.dbo.S_Dim_Course sdc
                    where sdc.course_id = uoc.course_id and current_flag = 1
                ) course_key, 
                uoc.grade,
                (
                    select DataWarehouse.dbo.S_Make_TimeKey (uoc.datetime_of_grade)
                )
            from staging_area.dbo.UserOnlineCourse uoc
            where uoc.datetime_of_grade = @current_date

            set @current_date = dateadd(day, 1, @current_date);

        end
    END
END


EXEC U_First_Time_Fill_PassedCourses_Fact_T '2020-01-01', '2020-01-15'


select * from U_Fact_PassedCourses

go
CREATE OR Alter PROCEDURE U_Full_PassedCourses_Fact_T
    @start_date_input date,
    @end_date_input date
AS
BEGIN

    declare @current_datetime Datetime;
    declare @current_date Date;
    declare @today Date;
    set @current_datetime = @start_date_input;
    set @today = @end_date_input
    set @current_date = convert(date, @current_datetime);

    WHILE @current_date <= @today
    BEGIN

        if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @current_date))
		begin
            set @current_date = dateadd(day, 1, @current_date);
        end

		else 
		begin
        
            insert into U_Fact_PassedCourses
            select 
                uoc.[user_id], 
                uoc.course_id, 
                (
                    select course_key
                    from DataWarehouse.dbo.S_Dim_Course sdc
                    where sdc.course_id = uoc.course_id and current_flag = 1
                ) course_key, 
                uoc.grade,
                (
                    select DataWarehouse.dbo.S_Make_TimeKey (uoc.datetime_of_grade)
                )
            from staging_area.dbo.UserOnlineCourse uoc
            where uoc.datetime_of_grade = @current_date

            set @current_date = dateadd(day, 1, @current_date);

        end
    END
END

EXEC U_Full_PassedCourses_Fact_T '2020-01-16', '2020-01-24'

select * from U_Fact_PassedCourses




create table U_Fact_UserRate_Acc
(
    [user_id] INT,
    sum_of_courses INT,
    sum_of_passed_courses INT,
    average_rating Decimal(3,2),
    number_of_rating INT,
    max_rating Decimal(3,2)
)


create table U_Fact_UserRate_Acc_Temp1
(
    [user_id] INT,
    sum_of_courses INT,
    sum_of_passed_courses INT,
    average_rating Decimal(3,2),
    number_of_rating INT,
    max_rating Decimal(3,2)
)

create table U_Fact_UserRate_Acc_Temp_EachDay
(
    [user_id] INT,
    sum_of_courses INT,
    sum_of_passed_courses INT,
    average_rating Decimal(3,2),
    number_of_rating INT,
    max_rating Decimal(3,2),
    time_key nvarchar(255)
)

go
CREATE OR Alter PROCEDURE U_First_Time_Fill_UserRate_Fact_Acc
    @start_date_input date,
    @end_date_input date
AS
BEGIN

    TRUNCATE TABLE U_Fact_UserRate_Acc;
    TRUNCATE TABLE U_Fact_UserRate_Acc_Temp1;
	TRUNCATE TABLE U_Fact_UserRate_Acc_Temp_EachDay

    declare @current_datetime Datetime;
    declare @current_date Date;
    declare @today Date;
    set @current_datetime = @start_date_input;
    set @today = @end_date_input
    set @current_date = convert(date, @current_datetime);

    WHILE @current_date <= @today
    BEGIN

        if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @current_date))
		begin
            set @current_date = dateadd(day, 1, @current_date);
        end

		else 
		begin

            insert into U_Fact_UserRate_Acc_Temp_EachDay
            select 
                [user_id],
                (
                    select count(course_id)
                    from Staging_area.dbo.UserOnlineCourse uoc
                    where convert(date, uoc.datetime_user_enrolled) = @current_date
                        and uoc.[user_id] = ufur.[user_id]
                ) as sum_of_courses,
                (
                    select count(course_id)
                    from Staging_area.dbo.UserOnlineCourse uoc
                    where convert(date, uoc.datetime_of_grade) = @current_date
                        and uoc.[user_id] = ufur.[user_id]
                        and uoc.grade is not NULL
                ) as sum_of_passed_courses,
                avg(ufur.rating) as average_rating,
                count(ufur.course_id) as number_of_rating,
                max(ufur.rating) as max_rating,
                (select DataWarehouse.dbo.S_Make_TimeKey(@current_date))
            -- select [user_id], course_key, course_id, time_key, rating
            from DataWarehouse.dbo.U_Fact_UserRating ufur
            where ufur.time_key = (select DataWarehouse.dbo.S_Make_TimeKey(@current_date))
            group by [user_id]

            insert into U_Fact_UserRate_Acc_Temp_EachDay
            select [user_id], 0, 0, Null, 0, Null, @current_date
            from U_Fact_UserRate_Acc
            where [user_id] not in (select [user_id] from U_Fact_UserRate_Acc_Temp_EachDay)


            -- select * from U_Fact_UserRate_Acc_Temp_EachDay
            -- order by [user_id]
            -- -- where [user_id] = 5221

            insert into U_Fact_UserRate_Acc_Temp1
            select
                ufurated.[user_id],
                (ufurated.sum_of_courses + ISNULL(ufura.sum_of_courses, 0)) as sum_of_courses,
                (ufurated.sum_of_passed_courses + ISNULL(ufura.sum_of_passed_courses, 0)) as sum_of_passed_courses,
                (   ((ISNULL(ufurated.average_rating, 0) * ISNULL(ufurated.number_of_rating, 0))
                    + (ISNULL(ufura.average_rating, 0) * ISNULL(ufura.number_of_rating, 0)))
                    / (ISNULL(ufura.number_of_rating, 0) + ISNULL(ufurated.number_of_rating, 0)))
                    as average_rating,
                ufurated.number_of_rating + ISNULL(ufura.number_of_rating, 0),
                (SELECT MAX(num) FROM (VALUES (ufurated.max_rating), (ufura.max_rating)) AS TwoMax(num))
                -- ufurated.max_rating,
            from U_Fact_UserRate_Acc_Temp_EachDay ufurated
                left join U_Fact_UserRate_Acc ufura
                    on ufurated.[user_id] = ufura.[user_id];

            -- select * from U_Fact_UserRate_Acc_Temp1
            -- order by [user_id]
            -- -- where [user_id] = 5221

            TRUNCATE TABLE U_Fact_UserRate_Acc;

            insert into U_Fact_UserRate_Acc
            select tmp1.[user_id], tmp1.sum_of_courses, tmp1.sum_of_passed_courses, tmp1.average_rating, tmp1.number_of_rating, tmp1.max_rating
            from U_Fact_UserRate_Acc_Temp1 tmp1;

            -- select * from U_Fact_UserRate_Acc
            -- order by [user_id]

            truncate table U_Fact_UserRate_Acc_Temp_EachDay;
            truncate table U_Fact_UserRate_Acc_Temp1;
            -- print 1
            -- select * from DataWarehouse.dbo.S_Dim_Date

            set @current_date = dateadd(day, 1, @current_date);

        END
    END

END

EXEC U_First_Time_Fill_UserRate_Fact_Acc '2020-10-01', '2020-11-01' --'2020-12-18'

select * from DataWarehouse.dbo.U_Fact_UserRate_Acc


go
CREATE OR Alter PROCEDURE U_Fill_UserRate_Fact_Acc
    @start_date_input date,
    @end_date_input date
AS
BEGIN
    TRUNCATE TABLE U_Fact_UserRate_Acc_Temp1;
    TRUNCATE TABLE U_Fact_UserRate_Acc_Temp_EachDay;

    declare @current_datetime Datetime;
    declare @current_date Date;
    declare @today Date;
    set @current_datetime = @start_date_input;
    set @today = @end_date_input
    set @current_date = convert(date, @current_datetime);

    WHILE @current_date <= @today
    BEGIN
        if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @current_date))
		begin
            set @current_date = dateadd(day, 1, @current_date);
        end

		else 
		begin

            insert into U_Fact_UserRate_Acc_Temp_EachDay
            select 
                [user_id],
                (
                    select count(course_id)
                    from Staging_area.dbo.UserOnlineCourse uoc
                    where convert(date, uoc.datetime_user_enrolled) = @current_date
                        and uoc.[user_id] = ufur.[user_id]
                ) as sum_of_courses,
                (
                    select count(course_id)
                    from Staging_area.dbo.UserOnlineCourse uoc
                    where convert(date, uoc.datetime_of_grade) = @current_date
                        and uoc.[user_id] = ufur.[user_id]
                        and uoc.grade is not NULL
                ) as sum_of_passed_courses,
                avg(ufur.rating) as average_rating,
                count(ufur.course_id) as number_of_rating,
                max(ufur.rating) as max_rating,
                (select DataWarehouse.dbo.S_Make_TimeKey(@current_date))
            -- select [user_id], course_key, course_id, time_key, rating
            from DataWarehouse.dbo.U_Fact_UserRating ufur
            where ufur.time_key = (select DataWarehouse.dbo.S_Make_TimeKey(@current_date))
            group by [user_id]


            -- select * 
            -- from U_Fact_UserRate_Acc_Temp_EachDay
            -- order by [user_id]

            insert into U_Fact_UserRate_Acc_Temp_EachDay
            select [user_id], 0, 0, Null, 0, Null, @current_date
            from U_Fact_UserRate_Acc
            where [user_id] not in (select [user_id] from U_Fact_UserRate_Acc_Temp_EachDay)

            
            insert into U_Fact_UserRate_Acc_Temp1
            select
                ufurated.[user_id],
                (ufurated.sum_of_courses + ISNULL(ufura.sum_of_courses, 0)) as sum_of_courses,
                (ufurated.sum_of_passed_courses + ISNULL(ufura.sum_of_passed_courses, 0)) as sum_of_passed_courses,
                (   ((ISNULL(ufurated.average_rating, 0) * ISNULL(ufurated.number_of_rating, 0))
                    + (ISNULL(ufura.average_rating, 0) * ISNULL(ufura.number_of_rating, 0)))
                    / (ISNULL(ufura.number_of_rating, 0) + ISNULL(ufurated.number_of_rating, 0)))
                    as average_rating,
                ufurated.number_of_rating + ISNULL(ufura.number_of_rating, 0),
                (SELECT MAX(num) FROM (VALUES (ufurated.max_rating), (ufura.max_rating)) AS TwoMax(num))
                -- ufurated.max_rating,
            from U_Fact_UserRate_Acc_Temp_EachDay ufurated
                left join U_Fact_UserRate_Acc ufura
                    on ufurated.[user_id] = ufura.[user_id];


            TRUNCATE TABLE U_Fact_UserRate_Acc;

            insert into U_Fact_UserRate_Acc
            select tmp1.[user_id], tmp1.sum_of_courses, tmp1.sum_of_passed_courses, tmp1.average_rating, tmp1.number_of_rating, tmp1.max_rating
            from U_Fact_UserRate_Acc_Temp1 tmp1;


            truncate table U_Fact_UserRate_Acc_Temp_EachDay;
            truncate table U_Fact_UserRate_Acc_Temp1;

            set @current_date = dateadd(day, 1, @current_date);

        END
    END

END

EXEC U_Fill_UserRate_Fact_Acc '2020-11-02', '2020-12-21' --'2020-12-18'

select * from U_Fact_UserRate_Acc



-- Human_Resource Mart


create table HR_Fact_InstructorCourse_T
(
	inst_id INT,
	course_id INT,
	course_key INT,
	[user_id] INT,
	time_key NVARCHAR(100),
)


create table HR_Fact_InstructorCourse_T_temp
(
	inst_id INT,
	course_id INT,
	course_key INT,
	[user_id] INT,
	time_key NVARCHAR(100),
)


create table HR_Fact_InstructorCourse_T_log
(
	log_key INT IDENTITY(1,1) PRIMARY KEY,
	number_of_rows int,
	time_when Date,
	full_time Datetime,
	fact_name nvarchar(50),
	[action] nvarchar(50)
);



create table HR_Fact_InstructorCourse_ACC
(
	inst_id INT,
	totalParticipants INT,
	totalCourses INT
)


create table HR_Fact_InstructorCourse_ACC_temp
(
	inst_id INT,
	totalParticipants INT,
	totalCourses INT
)


create table HR_Fact_InstructorCourse_newRecords_temp
(
	inst_id INT,
	course_id INT,
	course_key INT,
	[user_id] INT,
	time_key NVARCHAR(100),
)


create table HR_Fact_InstructorCourse_ACC_log
(
	log_key INT IDENTITY(1,1) PRIMARY KEY,
	number_of_rows int,
	full_time Datetime,
	fact_name nvarchar(50),
	[action] nvarchar(50)
)







create table HR_Fact_InstructorRate_Daily
(
	inst_id INT,
	rate DECIMAL(3,2),
	time_key NVARCHAR(100)
)


create table HR_Fact_InstructorRate_Daily_temp
(
	inst_id INT,
	rate DECIMAL(3,2),
	time_key NVARCHAR(100)
)


create table HR_Fact_InstructorRate_Daily_log
(
	log_key INT IDENTITY(1,1) PRIMARY KEY,
	number_of_rows int,
	time_when Date,
	fact_name nvarchar(50),
	[action] nvarchar(50)
);








create table HR_Fact_StaffPayment_Yearly
(
	staff_id INT,
	maxEarned MONEY,
	avgEarned MONEY,
	totalEarned MONEY,
	time_key NVARCHAR(100)
)


create table HR_Fact_StaffPayment_Yearly_temp
(
	staff_id INT,
	maxEarned MONEY,
	avgEarned MONEY,
	totalEarned MONEY,
	time_key NVARCHAR(100)
)



create table HR_Fact_StaffPayment_Yearly_log
(
	log_key INT IDENTITY(1,1) PRIMARY KEY,
	number_of_rows int,
	time_when Date,
	full_time Datetime,
	fact_name nvarchar(50),
	[action] nvarchar(50)
);



create table HR_Fact_Tickets_Daily
(
	ticket_category_id INT,
	totalThreads INT,
	totalTickets INT,
	average_Rating_of_ClosedThreads DECIMAL(3,2),
	time_key NVARCHAR(100)
)



create table HR_Fact_Tickets_Daily_temp
(
	ticket_category_id INT,
	totalThreads INT,
	totalTickets INT,
	average_Rating_of_ClosedThreads DECIMAL(3,2),
	time_key NVARCHAR(100)
)


create table HR_Fact_Tickets_Daily_temp_ticket
(
	ticket_category_id INT,
	ticket_thread_id INT,
	ticket_id INT,
	rating DECIMAL(3,2),
	datetime_closed DATETIME,
	datetime_created DATETIME
)


create table HR_Fact_Tickets_Daily_log
(
	log_key INT IDENTITY(1,1) PRIMARY KEY,
	number_of_rows int,
	time_when Date,
	full_time Datetime,
	fact_name nvarchar(50),
	[action] nvarchar(50)
);



go
CREATE OR ALTER PROCEDURE HR_First_Time_Fill_Fact_InstructorCourse_T @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table HR_Fact_InstructorCourse_T;
	truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp;

	declare @local_from_date Date
	declare @local_to_date Date
	set @local_from_date = @from_date
	set @local_to_date = @to_date

	WHILE (@local_from_date <= @local_to_date)
	BEGIN
		insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp (inst_id, course_id, course_key, [user_id], time_key)
		select
		sci.inst_id,
		sci.course_id,
		(
			select course_key
			from DataWarehouse.dbo.S_Dim_Course sdc
			where sdc.course_id = suoc.course_id and sdc.current_flag = 1
		) as course_key,
		suoc.[user_id],
		(
			select DataWarehouse.dbo.S_Make_TimeKey (suoc.datetime_user_enrolled)
		) as time_key
		from Staging_area.dbo.UserOnlineCourse suoc inner join Staging_area.dbo.CourseInstructor sci on (suoc.course_id = sci.course_id)
		where CONVERT(date, suoc.datetime_user_enrolled) = @local_from_date;


		insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_T(inst_id, course_id, course_key, [user_id], time_key)
		select inst_id, course_id, course_key, [user_id], time_key 
		from DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp;


		if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp ) > 0
		BEGIN
			insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_T_log(number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp ), @local_from_date, GETDATE(), 'instructor_course','insert first time');
		END
		truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp;
		set @local_from_date = DATEADD(day,1,@local_from_date);
		
	END
END
GO

EXEC HR_First_Time_Fill_Fact_InstructorCourse_T '2019-12-01', '2020-01-01';

select * from DataWarehouse.dbo.HR_Fact_InstructorCourse_T
select * from DataWarehouse.dbo.HR_Fact_InstructorCourse_T_log



go
CREATE OR ALTER PROCEDURE HR_Fill_Fact_InstructorCourse_T @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp;
	
	declare @local_from_date Date
	declare @local_to_date Date
	set @local_from_date = @from_date
	set @local_to_date = @to_date

	WHILE (@local_from_date <= @local_to_date)
	BEGIN
		insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp (inst_id, course_id, course_key, [user_id], time_key)
		select
		sci.inst_id,
		sci.course_id,
		(
			select course_key
			from DataWarehouse.dbo.S_Dim_Course sdc
			where sdc.course_id = suoc.course_id and sdc.current_flag = 1
		) as course_key,
		suoc.[user_id],
		(
			select DataWarehouse.dbo.S_Make_TimeKey (suoc.datetime_user_enrolled)
		) as time_key
		from Staging_area.dbo.UserOnlineCourse suoc inner join Staging_area.dbo.CourseInstructor sci on (suoc.course_id = sci.course_id)
		where CONVERT(date, suoc.datetime_user_enrolled) = @local_from_date;


		insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_T(inst_id, course_id, course_key, [user_id], time_key)
		select inst_id, course_id, course_key, [user_id], time_key 
		from DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp;


		if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp ) > 0
		BEGIN
			insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_T_log(number_of_rows,time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp ), @local_from_date, GETDATE(), 'instructor_course','regular insert');
		END

		truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp;
		set @local_from_date = DATEADD(day,1,@local_from_date);
		
	END
END
GO

EXEC HR_Fill_Fact_InstructorCourse_T '2019-12-01', '2020-01-01';

select * from DataWarehouse.dbo.HR_Fact_InstructorCourse_T
select * from DataWarehouse.dbo.HR_Fact_InstructorCourse_T_log




go
CREATE OR ALTER PROCEDURE HR_First_Time_Fill_Fact_InstructorCourse_ACC @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table HR_Fact_InstructorCourse_ACC
	truncate table HR_Fact_InstructorCourse_newRecords_temp
	truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_temp


	insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp (inst_id, course_id, course_key, [user_id], time_key)
	select inst_id, course_id, course_key, [user_id], time_key
	from DataWarehouse.dbo.HR_Fact_InstructorCourse_T


	insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_temp (inst_id, totalParticipants, totalCourses)
	select
	hrid.inst_id,
	(
		select COUNT(temp.inst_id)
		from DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp temp
		where hrid.inst_id = temp.inst_id
	) as totalParticipants,
	(
		select count(temptemp.inst_id)
		from (
				select temp.inst_id, temp.course_id
				from DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp temp
				group by temp.inst_id, temp.course_id
			  ) as temptemp
		where hrid.inst_id = temptemp.inst_id
	) as totalCourses

	from DataWarehouse.dbo.HR_Dim_Instructor hrid


	insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC (inst_id, totalParticipants, totalCourses)
	select inst_id, totalParticipants, totalCourses
	from DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_temp


	if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp ) > 0
		BEGIN
			insert into HR_Fact_InstructorCourse_ACC_log(number_of_rows, full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp ), GETDATE(), 'instructor_course_ACC','first time num of processed');
		END


	truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_temp
	truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp

END
GO

EXEC DataWarehouse.dbo.HR_First_Time_Fill_Fact_InstructorCourse_ACC '2019-12-01', '2020-01-01'

select * from DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC order by inst_id
select * from DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_log




go
CREATE OR ALTER PROCEDURE HR_Fill_Fact_InstructorCourse_ACC @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN

	truncate table HR_Fact_InstructorCourse_newRecords_temp
	truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_temp


	insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp (inst_id, course_id, course_key, [user_id], time_key)
	select inst_id, course_id, course_key, [user_id], time_key
	from DataWarehouse.dbo.HR_Fact_InstructorCourse_T


	insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_temp (inst_id, totalParticipants, totalCourses)
	select
	hrid.inst_id,
	(
		select COUNT(temp.inst_id)
		from DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp temp
		where hrid.inst_id = temp.inst_id
	) as totalParticipants,
	(
		select count(temptemp.inst_id)
		from (
				select temp.inst_id, temp.course_id
				from DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp temp
				group by temp.inst_id, temp.course_id
			  ) as temptemp
		where hrid.inst_id = temptemp.inst_id
	) as totalCourses

	from DataWarehouse.dbo.HR_Dim_Instructor hrid


	truncate table HR_Fact_InstructorCourse_ACC

	insert into DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC (inst_id, totalParticipants, totalCourses)
	select inst_id, totalParticipants, totalCourses
	from DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_temp


	if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp ) > 0
		BEGIN
			insert into HR_Fact_InstructorCourse_ACC_log(number_of_rows, full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp ), GETDATE(), 'instructor_course_ACC','regular run - num of processed');
		END


	truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_temp
	truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_newRecords_temp

END
GO

EXEC DataWarehouse.dbo.HR_Fill_Fact_InstructorCourse_ACC '2019-12-01', '2020-01-01'

select * from DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC order by inst_id
select * from DataWarehouse.dbo.HR_Fact_InstructorCourse_ACC_log



go
CREATE OR ALTER PROCEDURE HR_First_Time_Fill_Fact_InstructorRate_Daily @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table DataWarehouse.dbo.HR_Fact_InstructorRate_Daily;
	truncate table DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp
	
	declare @local_from_date Date
	declare @local_to_date Date
	set @local_from_date = @from_date
	set @local_to_date = @to_date

	insert into DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp (inst_id, rate, time_key)
	select
	si.inst_id,
	si.rating,
	(
		select DataWarehouse.dbo.S_Make_TimeKey (convert(datetime,@local_to_date))
	) as time_key
	from Staging_area.dbo.Instructor si


	insert into DataWarehouse.dbo.HR_Fact_InstructorRate_Daily(inst_id, rate, time_key)
	select inst_id, rate, time_key
	from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp

	if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp ) > 0
	BEGIN
		insert into DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_log(number_of_rows, time_when, fact_name, [action] )
			values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp ), @local_to_date,'instructor_rate','insert first time');
	END
	truncate table DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp
		
END
GO

EXEC HR_First_Time_Fill_Fact_InstructorRate_Daily '2020-01-01', '2020-12-01';

select * from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily
select * from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_log






go
CREATE OR ALTER PROCEDURE HR_Fill_Fact_InstructorRate_Daily @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp
	
	declare @local_from_date Date
	declare @local_to_date Date
	set @local_from_date = @from_date
	set @local_to_date = @to_date

	insert into DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp (inst_id, rate, time_key)
	select
	si.inst_id,
	si.rating,
	(
		select DataWarehouse.dbo.S_Make_TimeKey (convert(datetime,@local_to_date))
	) as time_key
	from Staging_area.dbo.Instructor si


	insert into DataWarehouse.dbo.HR_Fact_InstructorRate_Daily(inst_id, rate, time_key)
	select inst_id, rate, time_key
	from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp

	if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp ) > 0
	BEGIN
		insert into DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_log(number_of_rows, time_when, fact_name, [action] )
			values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp ), @local_to_date,'instructor_rate','regular insert');
	END
	truncate table DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_temp
		
END
GO

EXEC HR_Fill_Fact_InstructorRate_Daily '2020-01-01', '2020-12-01';

select * from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily
select * from DataWarehouse.dbo.HR_Fact_InstructorRate_Daily_log




create table HR_Fact_StaffPayment_T
(
    staff_id INT,
    ammount Money,
    time_key NVARCHAR(255)
)


go
CREATE OR Alter PROCEDURE HR_First_Time_Fill_StaffPayment_Fact_T
    @start_date_input date,
    @end_date_input date
AS
BEGIN
    TRUNCATE TABLE HR_Fact_StaffPayment_T;

    declare @current_datetime Datetime;
    declare @current_date Date;
    declare @today Date;
    -- set @current_datetime = (select min(s.datetime_joined) from staging_area.dbo.Staff s);
    set @current_datetime = @start_date_input;
    -- set @today = convert(date, GETDATE());
    set @today = @end_date_input
    set @current_date = convert(date, @current_datetime);


    WHILE @current_date <= @today
    BEGIN

        if (not exists (select *
        from DataWarehouse.dbo.[S_Dim_Date]
        where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @current_date))
		begin
            set @current_date = dateadd(day, 1, @current_date);
        end

		else 
		begin

            insert into HR_Fact_StaffPayment_T
            select p.staff_id, p.amount,
                (select DataWarehouse.dbo.S_Make_TimeKey (p.date_of_payment))
            from staging_area.dbo.Payment p
            where convert(date, p.date_of_payment) = @current_date;

            set @current_date = dateadd(day, 1, @current_date);

        end
    END
END
-- select * from Payment;
EXEC HR_First_Time_Fill_StaffPayment_Fact_T '2020-06-06', '2020-06-12';

select *
from HR_Fact_StaffPayment_T;


go
CREATE OR Alter PROCEDURE HR_Full_StaffPayment_Fact_T
    @start_date_input Date,
    @until_date Date
AS
BEGIN

    declare @last_time_key_in_fact nvarchar(255);
    declare @last_date_in_fact date;
    declare @current_date date;

    -- set @last_time_key_in_fact = (select max(spt.time_key) from DataWarehouse.dbo.HR_Fact_StaffPayment_T spt);
    -- set @last_date_in_fact = (select d.FullDateAlternateKey from DataWarehouse.dbo.S_Dim_Date d where TimeKey = @last_time_key_in_fact)
    set @last_date_in_fact = @start_date_input;
    -- set @current_date = dateadd(day, 1, @last_date_in_fact);
    set @current_date = @last_date_in_fact;

    WHILE @current_date <= @until_date
    BEGIN

        if (not exists (select *
        from DataWarehouse.dbo.[S_Dim_Date]
        where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @current_date))
		begin
            set @current_date = dateadd(day, 1, @current_date);
        end

		else 
		begin

            insert into HR_Fact_StaffPayment_T
            select p.staff_id, p.amount,
                (select DataWarehouse.dbo.S_Make_TimeKey (p.date_of_payment))
            from staging_area.dbo.Payment p
            where convert(date, p.date_of_payment) = @current_date;

            set @current_date = dateadd(day, 1, @current_date);

        end
    END
END

/*
select *
from Payment

insert into staging_area.dbo.Payment
values
    (4, 199000, '2020-06-13'),
    (3, 125000, '2020-06-13'),
    (4, 135000, '2020-06-15'),
    (2, 135000, '2020-06-16')
*/

EXEC HR_Full_StaffPayment_Fact_T '2020-06-13', '2020-06-16';

select *
from HR_Fact_StaffPayment_T;


go
CREATE OR ALTER PROCEDURE HR_First_Time_Fill_Fact_StaffPayment_Yearly @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly;
	truncate table DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp;

	declare @local_from_date Date
	declare @local_to_date Date
	set @local_from_date = @from_date
	set @local_to_date = @to_date
	

	insert into DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp (staff_id, maxEarned, avgEarned, totalEarned, time_key)
	select
	distinct
	hfst.staff_id,
	(
		select max(temp.ammount)
		from DataWarehouse.dbo.HR_Fact_StaffPayment_T temp
		where temp.staff_id = hfst.staff_id
		group by temp.staff_id
	) as maxEarned,
	(
		select AVG(temp.ammount)
		from DataWarehouse.dbo.HR_Fact_StaffPayment_T temp
		where temp.staff_id = hfst.staff_id
		group by temp.staff_id
	) as avgEarned,
	(
		select SUM(temp.ammount)
		from DataWarehouse.dbo.HR_Fact_StaffPayment_T temp
		where temp.staff_id = hfst.staff_id
		group by temp.staff_id
	) as totalEarned,
	(
		select DataWarehouse.dbo.S_Make_TimeKey (CONVERT(datetime, @local_to_date))
	) as time_key
	from DataWarehouse.dbo.HR_Fact_StaffPayment_T hfst inner join DataWarehouse.dbo.S_Dim_Date t on (hfst.time_key=t.TimeKey)
	where CONVERT(date,t.FullDateAlternateKey) >= @local_from_date and CONVERT(date,t.FullDateAlternateKey) <= @local_to_date


	insert into DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly(staff_id, maxEarned, avgEarned, totalEarned, time_key)
	select staff_id, maxEarned, avgEarned, totalEarned, time_key 
	from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp;


	if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp ) > 0
	BEGIN
		insert into DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_log(number_of_rows,time_when ,full_time ,fact_name ,[action] )
			values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp ), @local_to_date, GETDATE(), 'HR_Fact_StaffPayment_Yearly','insert first time');
	END

	truncate table DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp;
		
END
GO

EXEC HR_First_Time_Fill_Fact_StaffPayment_Yearly '2019-12-01', '2020-12-01';

select * from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly order by staff_id
select * from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_log




go
CREATE OR ALTER PROCEDURE HR_Fill_Fact_StaffPayment_Yearly @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp;

	declare @local_from_date Date
	declare @local_to_date Date
	set @local_from_date = @from_date
	set @local_to_date = @to_date
	

	insert into DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp (staff_id, maxEarned, avgEarned, totalEarned, time_key)
	select
	distinct
	hfst.staff_id,
	(
		select max(temp.ammount)
		from DataWarehouse.dbo.HR_Fact_StaffPayment_T temp
		where temp.staff_id = hfst.staff_id
		group by temp.staff_id
	) as maxEarned,
	(
		select AVG(temp.ammount)
		from DataWarehouse.dbo.HR_Fact_StaffPayment_T temp
		where temp.staff_id = hfst.staff_id
		group by temp.staff_id
	) as avgEarned,
	(
		select SUM(temp.ammount)
		from DataWarehouse.dbo.HR_Fact_StaffPayment_T temp
		where temp.staff_id = hfst.staff_id
		group by temp.staff_id
	) as totalEarned,
	(
		select DataWarehouse.dbo.S_Make_TimeKey (CONVERT(datetime, @local_to_date))
	) as time_key
	from DataWarehouse.dbo.HR_Fact_StaffPayment_T hfst inner join DataWarehouse.dbo.S_Dim_Date t on (hfst.time_key=t.TimeKey)
	where CONVERT(date,t.FullDateAlternateKey) >= @local_from_date and CONVERT(date,t.FullDateAlternateKey) <= @local_to_date


	insert into DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly(staff_id, maxEarned, avgEarned, totalEarned, time_key)
	select staff_id, maxEarned, avgEarned, totalEarned, time_key 
	from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp;


	if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp ) > 0
	BEGIN
		insert into DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_log(number_of_rows,time_when ,full_time ,fact_name ,[action] )
			values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp ), @local_to_date, GETDATE(), 'HR_Fact_StaffPayment_Yearly','insert first time');
	END

	truncate table DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_temp;
		
END
GO

EXEC HR_Fill_Fact_StaffPayment_Yearly '2019-12-01', '2020-12-01';

select * from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly order by staff_id
select * from DataWarehouse.dbo.HR_Fact_StaffPayment_Yearly_log






go
CREATE OR ALTER PROCEDURE HR_First_Time_Fill_Fact_Tickets_Daily @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table HR_Fact_Tickets_Daily;
	truncate table HR_Fact_Tickets_Daily_temp
	truncate table HR_Fact_Tickets_Daily_temp_ticket

	declare @local_from_date Date
	declare @local_to_date Date
	set @local_from_date = @from_date
	set @local_to_date = @to_date


	WHILE (@local_from_date <= @local_to_date)
	BEGIN
		truncate table HR_Fact_Tickets_Daily_temp
		truncate table HR_Fact_Tickets_Daily_temp_ticket
		
		insert into DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp_ticket (ticket_category_id, ticket_thread_id, ticket_id, rating, datetime_closed, datetime_created)
		select stt.ticket_category_id, st.ticket_thread_id, st.ticket_id, stt.rating, stt.datetime_closed, st.datetime_created
		from Staging_area.dbo.TicketThread stt inner join Staging_area.dbo.Ticket st on (stt.ticket_thread_id = st.ticket_thread_id)										
		where st.datetime_created >= @local_from_date and st.datetime_created < CONVERT(datetime,@local_from_date) + 1

		insert into DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp (ticket_category_id, totalThreads, totalTickets, average_Rating_of_ClosedThreads, time_key)
		select
		dhtc.ticket_category_id,
		(
			select count(tempHere.ticket_thread_id)
			from (
					select dhdtt.ticket_category_id, dhdtt.ticket_thread_id
					from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp_ticket dhdtt
					group by dhdtt.ticket_category_id, dhdtt.ticket_thread_id
				 ) as tempHere
			where tempHere.ticket_category_id = dhtc.ticket_category_id
		) as totalThread,
		(
			select count(dhdtt.ticket_id)
			from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp_ticket dhdtt
			where dhdtt.ticket_category_id = dhtc.ticket_category_id
		) as totalTickets,
		(
			select avg(dhdtt.rating)
			from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp_ticket dhdtt
			where dhdtt.ticket_category_id = dhtc.ticket_category_id and dhdtt.datetime_closed <= @local_from_date
		) as average_Rating_of_ClosedThreads,
		(
			select DataWarehouse.dbo.S_Make_TimeKey (CONVERT(datetime,@local_from_date))
		) as time_key
		from DataWarehouse.dbo.HR_Dim_TicketCategory dhtc

		insert into DataWarehouse.dbo.HR_Fact_Tickets_Daily (ticket_category_id, totalThreads, totalTickets, average_Rating_of_ClosedThreads, time_key)
		select ticket_category_id, totalThreads, totalTickets, average_Rating_of_ClosedThreads, time_key
		from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp

		if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp ) > 0
		BEGIN
			insert into DataWarehouse.dbo.HR_Fact_Tickets_Daily_log (number_of_rows, time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp ), @local_from_date, GETDATE(), 'Tickets_Daily','insert first time');
		END
		truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp;

		
		set @local_from_date = DATEADD(day,1,@local_from_date);
	END
END
GO

EXEC HR_First_Time_Fill_Fact_Tickets_Daily '2020-12-11', '2020-12-12'

select * from DataWarehouse.dbo.HR_Fact_Tickets_Daily
select * from DataWarehouse.dbo.HR_Fact_Tickets_Daily_log






go
CREATE OR ALTER PROCEDURE HR_Fill_Fact_Tickets_Daily @from_date DATE = NULL, @to_date DATE = NULL
AS
BEGIN
	truncate table HR_Fact_Tickets_Daily_temp
	truncate table HR_Fact_Tickets_Daily_temp_ticket

	declare @local_from_date Date
	declare @local_to_date Date
	set @local_from_date = @from_date
	set @local_to_date = @to_date


	WHILE (@local_from_date <= @local_to_date)
	BEGIN
		truncate table HR_Fact_Tickets_Daily_temp
		truncate table HR_Fact_Tickets_Daily_temp_ticket
		
		insert into DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp_ticket (ticket_category_id, ticket_thread_id, ticket_id, rating, datetime_closed, datetime_created)
		select stt.ticket_category_id, st.ticket_thread_id, st.ticket_id, stt.rating, stt.datetime_closed, st.datetime_created
		from Staging_area.dbo.TicketThread stt inner join Staging_area.dbo.Ticket st on (stt.ticket_thread_id = st.ticket_thread_id)										
		where st.datetime_created >= @local_from_date and st.datetime_created < CONVERT(datetime,@local_from_date) + 1

		insert into DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp (ticket_category_id, totalThreads, totalTickets, average_Rating_of_ClosedThreads, time_key)
		select
		dhtc.ticket_category_id,
		(
			select count(tempHere.ticket_thread_id)
			from (
					select dhdtt.ticket_category_id, dhdtt.ticket_thread_id
					from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp_ticket dhdtt
					group by dhdtt.ticket_category_id, dhdtt.ticket_thread_id
				 ) as tempHere
			where tempHere.ticket_category_id = dhtc.ticket_category_id
		) as totalThread,
		(
			select count(dhdtt.ticket_id)
			from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp_ticket dhdtt
			where dhdtt.ticket_category_id = dhtc.ticket_category_id
		) as totalTickets,
		(
			select avg(dhdtt.rating)
			from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp_ticket dhdtt
			where dhdtt.ticket_category_id = dhtc.ticket_category_id and dhdtt.datetime_closed <= @local_from_date
		) as average_Rating_of_ClosedThreads,
		(
			select DataWarehouse.dbo.S_Make_TimeKey (CONVERT(datetime,@local_from_date))
		) as time_key
		from DataWarehouse.dbo.HR_Dim_TicketCategory dhtc

		insert into DataWarehouse.dbo.HR_Fact_Tickets_Daily (ticket_category_id, totalThreads, totalTickets, average_Rating_of_ClosedThreads, time_key)
		select ticket_category_id, totalThreads, totalTickets, average_Rating_of_ClosedThreads, time_key
		from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp

		if (select COUNT(*) from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp ) > 0
		BEGIN
			insert into DataWarehouse.dbo.HR_Fact_Tickets_Daily_log (number_of_rows, time_when ,full_time ,fact_name ,[action] )
				values ((select COUNT(*) from DataWarehouse.dbo.HR_Fact_Tickets_Daily_temp ), @local_from_date, GETDATE(), 'Tickets_Daily','insert first time');
		END
		truncate table DataWarehouse.dbo.HR_Fact_InstructorCourse_T_temp;

		
		set @local_from_date = DATEADD(day,1,@local_from_date);
	END
END
GO

EXEC HR_Fill_Fact_Tickets_Daily '2020-12-11', '2020-12-12'

select * from DataWarehouse.dbo.HR_Fact_Tickets_Daily
select * from DataWarehouse.dbo.HR_Fact_Tickets_Daily_log