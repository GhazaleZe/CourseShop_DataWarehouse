use DataWarehouse
go

-- transaction fact for user ratings

drop table U_Fact_UserRating
create table U_Fact_UserRating
(
	[user_id] int,
	course_key int,
	course_id int,
	time_key nvarchar(100),
	full_time Date,
	rating decimal(3, 2),


);

create table U_user_rating_temp
(
	[user_id] int,
	course_key int,
	course_id int,
	time_key nvarchar(100),
	full_time Date,
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

select * from U_Fact_UserRating;
Select * from S_Dim_Date
select * from U_user_rating_temp

CREATE or Alter PROCEDURE U_First_Time_Fill_User_rating_fact
as
begin
	truncate table U_Fact_UserRating;
	declare @first_day Datetime;
	declare @first_day_v Date;
	set @first_day = (select min(staging_area.dbo.UserOnlineCourse.datetime_of_rating) from staging_area.dbo.UserOnlineCourse );
	set @first_day_v = convert(date,@first_day);
	declare @passing Date;
	declare @today Date;
	declare @timekey nvarchar(255);
	set @passing = @first_day_v;
	set @today =convert(date,GETDATE());
	while @today> @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @today))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			insert into DataWarehouse.dbo.U_user_rating_temp([user_id],course_id,course_key,time_key,full_time,rating) 
			select staging_area.dbo.UserOnlineCourse.[user_id] ,staging_area.dbo.UserOnlineCourse.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.UserOnlineCourse.course_id and ((price_starting_date<@passing) and ((@passing< price_starting_date ) or (price_end_date IS NULL)))),
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.UserOnlineCourse.datetime_of_rating)) ,convert(date,staging_area.dbo.UserOnlineCourse.datetime_of_rating) , staging_area.dbo.UserOnlineCourse.rating_num
			from staging_area.dbo.UserOnlineCourse
			where convert(date,staging_area.dbo.UserOnlineCourse.datetime_of_rating)= @passing;

			insert into DataWarehouse.dbo.U_Fact_UserRating([user_id],course_id,course_key,time_key,full_time,rating) 
			select [user_id],course_id,course_key,time_key,full_time,rating from DataWarehouse.dbo.U_user_rating_temp;

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

exec U_First_Time_Fill_User_rating_fact;


select * from U_UsersMart_log;

truncate table U_UsersMart_log;

select * from S_Dim_Course

-- *******************************************************

CREATE or Alter PROCEDURE U_Fill_User_rating_fact @today Date
as
begin
	declare @lastInFact Date;
	set @lastInFact = (select max(DataWarehouse.dbo.U_Fact_UserRating.full_time) from DataWarehouse.dbo.U_Fact_UserRating);
	declare @passing Datetime;
	--declare @today Datetime;
	declare @timekey nvarchar(255);
	set @passing = dateadd(day,1,@lastInFact);
	--set @today =GETDATE();
	while (@today> convert (date,@passing))
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where convert(date, DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey) = convert(date,@today)))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			insert into DataWarehouse.dbo.U_user_rating_temp([user_id],course_id,course_key,time_key,full_time,rating) 
			select staging_area.dbo.UserOnlineCourse.[user_id] ,staging_area.dbo.UserOnlineCourse.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.UserOnlineCourse.course_id),
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.UserOnlineCourse.datetime_of_rating)) ,staging_area.dbo.UserOnlineCourse.datetime_of_rating , staging_area.dbo.UserOnlineCourse.rating_num
			from staging_area.dbo.UserOnlineCourse
			where convert(date,staging_area.dbo.UserOnlineCourse.datetime_of_rating)= convert (date,@passing);

			insert into DataWarehouse.dbo.U_Fact_UserRating([user_id],course_id,course_key,time_key,full_time,rating) 
			select [user_id],course_id,course_key,time_key,full_time,rating from DataWarehouse.dbo.U_user_rating_temp;

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

exec U_Fill_User_rating_fact @today = '2020-12-20';


insert into DataWarehouse.dbo.U_user_rating_temp([user_id],course_id,course_key,time_key,full_time,rating) 
			select staging_area.dbo.UserOnlineCourse.[user_id] ,staging_area.dbo.UserOnlineCourse.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.UserOnlineCourse.course_id and ((price_starting_date<'2020-12-15') and (('2020-12-15'< price_starting_date ) or (price_end_date IS NULL)))),
			(select DataWarehouse.dbo.S_Make_TimeKey (staging_area.dbo.UserOnlineCourse.datetime_of_rating)) ,convert(date,staging_area.dbo.UserOnlineCourse.datetime_of_rating) , staging_area.dbo.UserOnlineCourse.rating_num
			from staging_area.dbo.UserOnlineCourse
			where convert(date,staging_area.dbo.UserOnlineCourse.datetime_of_rating)= '2020-12-15';





