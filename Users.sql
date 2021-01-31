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

select [user_id],course_id,course_key,time_key,full_time,rating from U_Fact_UserRating order by [user_id];
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


select * from U_UsersMart_log;

truncate table U_UsersMart_log;

select * from S_Dim_Course

-- *******************************************************

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

--*************************************************************

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
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.Comment.course_id ),
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

select * from S_Dim_Date

insert into S_Dim_Date(TimeKey,FullDateAlternateKey,PersianFullDateAlternateKey,DayNumberOfWeek) values('20210131','2021-01-31','1399-11-12',1);
insert into S_Dim_Date(TimeKey,FullDateAlternateKey,PersianFullDateAlternateKey,DayNumberOfWeek) values('20201111','2020-11-11','1399-09-12',1);

--********************************************************************************


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
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.Comment.course_id ),
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
delete from U_UsersMart_log where log_key >10
select * from U_UsersMart_log
select * from U_Fact_CommentRating_Temp;


--********************************************************************************


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
			(select course_key from DataWarehouse.dbo.S_Dim_Course where DataWarehouse.dbo.S_Dim_Course.course_id = staging_area.dbo.Comment.course_id ),
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

select * from U_Fact_CommentRating where comment_id=24997 and voter_user_id=917;

--truncate table U_Fact_CommentRating;
--**********************************************************************************

 
CREATE or Alter PROCEDURE U_Fact_InfluentialUsers_Acc @first_day_v Date,@today Date 
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

