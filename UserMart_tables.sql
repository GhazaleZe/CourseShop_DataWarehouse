Use DataWarehouse
Go

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
