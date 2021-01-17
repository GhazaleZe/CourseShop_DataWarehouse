use DataWarehouse
go

CREATE or Alter PROCEDURE U_Fill_User_rating_fact @today Date
as
begin
	declare @lastInFact Date;
	set @lastInFact = (select max(DataWarehouse.dbo.U_Fact_UserRating.full_time) from DataWarehouse.dbo.U_Fact_UserRating);
	declare @passing Date;
	--declare @today Datetime;
	declare @timekey nvarchar(255);
	set @passing = dateadd(day,1,@lastInFact);
	--set @today =GETDATE();
	while (@today> @passing)
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @today))
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
			where convert(date,staging_area.dbo.UserOnlineCourse.datetime_of_rating)= @passing;

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