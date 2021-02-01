use DataWarehouse
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

--************************************************************************

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

--*********************************************************************************
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


