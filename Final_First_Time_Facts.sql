use DataWarehouse
go

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
	--select @passing,@today
	while @today> @passing
	begin

		if (not exists (select * from DataWarehouse.dbo.[S_Dim_Date] where DataWarehouse.dbo.[S_Dim_Date].FullDateAlternateKey = @passing))
		begin
			set @passing=dateadd(day,1,@passing);
		end

		else 
		begin
			insert into DataWarehouse.dbo.U_user_rating_temp([user_id],course_id,course_key,time_key,full_time,rating) 
			select staging_area.dbo.UserOnlineCourse.[user_id] ,staging_area.dbo.UserOnlineCourse.course_id , 
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.UserOnlineCourse.course_id ),
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

--*******************************************************************************



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
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.Comment.course_id ),
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
--*************************************************************************************




