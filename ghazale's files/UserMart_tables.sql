Use DataWarehouse
Go

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

