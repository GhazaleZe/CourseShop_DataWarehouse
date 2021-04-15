USE Staging_area
GO

CREATE OR ALTER PROCEDURE Create_Staging_area
AS
BEGIN
	
	drop table Staging_area.dbo.Instructor
	drop table Staging_area.dbo.OnlineCourse
	drop table Staging_area.dbo.Topic
	drop table Staging_area.dbo.SubTopic
	drop table Staging_area.dbo.Downloaded
	drop table Staging_area.dbo.OffPrice
	drop table Staging_area.dbo.CourseInstructor
	drop table Staging_area.dbo.[User]
	drop table Staging_area.dbo.Comment
	drop table Staging_area.dbo.CommentVote
	drop table Staging_area.dbo.UserOnlineCourse
	drop table Staging_area.dbo.TicketCategory
	drop table Staging_area.dbo.TicketThread
	drop table Staging_area.dbo.Ticket
	drop table Staging_area.dbo.Category
	drop table Staging_area.dbo.CourseCategory
	drop table Staging_area.dbo.Job
	drop table Staging_area.dbo.Staff
	drop table Staging_area.dbo.Payment


	create table Instructor
	(
	inst_id INT PRIMARY KEY,
	first_name NVARCHAR(50),
	last_name NVARCHAR(50),
	phone_number VARCHAR(20),
	email_address NVARCHAR(255),
	is_email_verified BIT DEFAULT 0,
	short_description NVARCHAR(MAX),
	[description] NVARCHAR(MAX),
	rating DECIMAL(3,2) DEFAULT NULL,
	datetime_last_sign_in DATETIME DEFAULT CURRENT_TIMESTAMP,
	datetime_signed_up DATETIME DEFAULT CURRENT_TIMESTAMP,
	)

	create table OnlineCourse
	(
	course_id INT PRIMARY KEY,
	title NVARCHAR(255),
	[description] NVARCHAR(MAX),
	price INT DEFAULT 0,
	number_of_enrolled INT DEFAULT 0,
	rating DECIMAL(3,2) DEFAULT NULL,
	course_type NVARCHAR(255),
	course_level NVARCHAR(255),
	pre_req NVARCHAR(1000),
	[language] NVARCHAR(255),
	files_size INT DEFAULT 0,
	how_to_download NVARCHAR(1000),
	contact_way NVARCHAR(1000),
	completion_percentage INT,
	number_of_visits INT DEFAULT 0,
	length_in_calendar_time NVARCHAR(255),
	[start_date] DATETIME,
	datetime_content_update DATETIME DEFAULT CURRENT_TIMESTAMP,
	datetime_created DATETIME DEFAULT CURRENT_TIMESTAMP,
	)

	create table Topic
	(
	topic_id INT PRIMARY KEY,
	course_id INT,
	[priority] INT DEFAULT 0,
	title NVARCHAR(1000),
	[description] NVARCHAR(MAX)
	)

	create table SubTopic
	(
	sub_topic_id INT PRIMARY KEY,
	topic_id INT,
	[priority] INT DEFAULT 0,
	title NVARCHAR(1000),
	[description] NVARCHAR(MAX),
	source_file_link NVARCHAR(MAX),
	source_file_type NVARCHAR(255),
	is_it_premium BIT DEFAULT 1,
	)

	create table Downloaded
	(
	sub_topic_id INT,
	[user_id] INT,
	datetime_of_download DATETIME DEFAULT CURRENT_TIMESTAMP
	)

	create table OffPrice
	(
	off_price_id INT PRIMARY KEY,
	course_id INT,
	newPrice INT,
	datetime_off_start DATETIME,
	datetime_off_end DATETIME,
	)

	create table CourseInstructor
	(
	course_id INT,
	inst_id INT,
	PRIMARY KEY(course_id, inst_id)
	)

	create table [User]
	(
	[user_id] INT PRIMARY KEY,
	first_name NVARCHAR(50),
	last_name NVARCHAR(50),
	phone_number VARCHAR(20),
	email_address NVARCHAR(255),
	is_email_verified BIT DEFAULT 0 ,
	datetime_signed_up DATETIME DEFAULT CURRENT_TIMESTAMP,
	datetime_last_sign_in DATETIME DEFAULT CURRENT_TIMESTAMP,
	username NVARCHAR(100),
	gender NVARCHAR(6),
	date_of_birth DATETIME,
	hash_salt VARCHAR(256),
	password_hash VARCHAR(256),
	)

	create table Comment
	(
	comment_id INT PRIMARY KEY,
	[user_id] INT,
	course_id INT,
	comment_text NVARCHAR(MAX),
	parent_comment_id INT,
	datetime_created DATETIME DEFAULT CURRENT_TIMESTAMP
	)

	create table CommentVote
	(
	voter_user_id INT,
	comment_id INT,
	was_it_helpful BIT,
	datetime_created DATETIME DEFAULT CURRENT_TIMESTAMP
	PRIMARY KEY (voter_user_id, comment_id)
	)

	create table UserOnlineCourse
	(
	[user_id] INT,
	course_id INT,
	rating_num DECIMAL(3,2) DEFAULT NULL,
	datetime_of_rating DATETIME DEFAULT CURRENT_TIMESTAMP,
	comment_text NVARCHAR(MAX),
	used_off_price_id INT,
	actual_paid INT,
	datetime_user_enrolled DATETIME DEFAULT CURRENT_TIMESTAMP,
	grade Decimal(5,2) Default Null,
    datetime_of_grade Datetime Default Null
	PRIMARY KEY([user_id], course_id)
	)

	create table TicketCategory
	(
	ticket_category_id INT PRIMARY KEY,
	title NVARCHAR(200),
	[description] NVARCHAR(MAX)
	)

	create table TicketThread
	(
	ticket_thread_id INT PRIMARY KEY,
	[subject] NVARCHAR(100),
	ticket_category_id INT,
	related_staff_id INT,
	rating DECIMAL(3,2),
	datetime_closed DATETIME
	)

	create table Ticket
	(
	ticket_id INT PRIMARY KEY,
	[text] NVARCHAR(MAX),
	datetime_created DATETIME DEFAULT CURRENT_TIMESTAMP,
	ticket_thread_id INT,
	[user_id] INT
	)

	create table Category
	(
	category_id INT PRIMARY KEY,
	title NVARCHAR(200)
	)

	create table CourseCategory
	(
	course_id INT,
	category_id INT,
	PRIMARY KEY(course_id, category_id)
	)

	create table Job
	(
	job_id INT PRIMARY KEY,
	job_title NVARCHAR(300),
	job_description NVARCHAR(800)
	)

	create table Staff
	(
	staff_id INT PRIMARY KEY,
	first_name NVARCHAR(50),
	last_name NVARCHAR(50),
	date_of_birth DATETIME,
	email_address NVARCHAR(255),
	is_email_verified BIT DEFAULT 0,
	phone_number VARCHAR(15),
	datetime_joined DATETIME DEFAULT CURRENT_TIMESTAMP,
	datetime_last_sign_in DATETIME DEFAULT CURRENT_TIMESTAMP,
	current_monthly_salary Money Default 0,
	gender NVARCHAR(6),
	short_description NVARCHAR(400),
	username NVARCHAR(100),
	job_id INT,
	hash_salt VARCHAR(256),
	password_hash VARCHAR(256),
	)

	create table Payment
	(
	payment_id INT PRIMARY KEY,
	staff_id INT,
	amount Money,
	date_of_payment DATETIME
	)

END
GO




CREATE OR ALTER PROCEDURE Fill_Staging_area
AS
BEGIN
	
	insert into Staging_area.dbo.Instructor
		(
		inst_id,
		first_name,
		last_name,
		phone_number,
		email_address,
		is_email_verified,
		short_description,
		[description],
		rating,
		datetime_last_sign_in,
		datetime_signed_up
		)
	select
		inst_id,
		first_name,
		last_name,
		phone_number,
		email_address,
		is_email_verified,
		short_description,
		[description],
		rating,
		datetime_last_sign_in,
		datetime_signed_up
	from [Source].dbo.Instructor


	insert into Staging_area.dbo.OnlineCourse
		(
		course_id,
		title,
		[description],
		price,
		number_of_enrolled,
		rating,
		course_type,
		course_level,
		pre_req,
		[language],
		files_size,
		how_to_download,
		contact_way,
		completion_percentage,
		number_of_visits,
		length_in_calendar_time,
		[start_date],
		datetime_content_update,
		datetime_created
		)
	select
		course_id,
		title,
		[description],
		price,
		number_of_enrolled,
		rating,
		course_type,
		course_level,
		pre_req,
		[language],
		files_size,
		how_to_download,
		contact_way,
		completion_percentage,
		number_of_visits,
		length_in_calendar_time,
		[start_date],
		datetime_content_update,
		datetime_created
	from [Source].dbo.OnlineCourse


	insert into Staging_area.dbo.Topic
		(
		topic_id,
		course_id,
		[priority],
		title,
		[description]
		)
	select
		topic_id,
		course_id,
		[priority],
		title,
		[description]
	from [Source].dbo.Topic

	insert into Staging_area.dbo.SubTopic
		(
		sub_topic_id,
		topic_id,
		[priority],
		title,
		[description],
		source_file_link,
		source_file_type,
		is_it_premium
		)
	select
		sub_topic_id,
		topic_id ,
		[priority],
		title,
		[description],
		source_file_link,
		source_file_type,
		is_it_premium
	from [Source].dbo.SubTopic


	insert into Staging_area.dbo.Downloaded
		(
		sub_topic_id,
		[user_id],
		datetime_of_download
		)
	select
		sub_topic_id,
		[user_id],
		datetime_of_download
	from [Source].dbo.Downloaded


	insert into Staging_area.dbo.OffPrice
		(
		off_price_id,
		course_id,
		newPrice,
		datetime_off_start,
		datetime_off_end
		)
	select
		off_price_id,
		course_id,
		newPrice,
		datetime_off_start,
		datetime_off_end
	from [Source].dbo.OffPrice


	insert into Staging_area.dbo.CourseInstructor
		(
		course_id,
		inst_id
		)
	select
		course_id,
		inst_id
	from [Source].dbo.CourseInstructor


	insert into Staging_area.dbo.[User]
		(
		[user_id],
		first_name,
		last_name,
		phone_number,
		email_address,
		is_email_verified,
		datetime_signed_up,
		datetime_last_sign_in,
		username,
		gender,
		date_of_birth,
		hash_salt,
		password_hash
		)
	select
		[user_id],
		first_name,
		last_name,
		phone_number,
		email_address,
		is_email_verified,
		datetime_signed_up,
		datetime_last_sign_in,
		username,
		gender,
		date_of_birth,
		hash_salt,
		password_hash
	from [Source].dbo.[User]


	insert into Staging_area.dbo.Comment
		(
		comment_id,
		[user_id],
		course_id,
		comment_text,
		parent_comment_id,
		datetime_created
		)
	select
		comment_id,
		[user_id],
		course_id,
		comment_text,
		parent_comment_id,
		datetime_created
	from [Source].dbo.Comment


	insert into Staging_area.dbo.CommentVote
		(
		voter_user_id,
		comment_id,
		was_it_helpful,
		datetime_created
		)
	select
		voter_user_id,
		comment_id,
		was_it_helpful,
		datetime_created
	from [Source].dbo.CommentVote


	insert into Staging_area.dbo.UserOnlineCourse
		(
		[user_id],
		course_id,
		rating_num,
		datetime_of_rating,
		comment_text,
		used_off_price_id,
		actual_paid,
		datetime_user_enrolled,
		grade,
		datetime_of_grade
		)
	select
		[user_id],
		course_id,
		rating_num,
		datetime_of_rating,
		comment_text,
		used_off_price_id,
		actual_paid,
		datetime_user_enrolled,
		grade,
		datetime_of_grade
	from [Source].dbo.UserOnlineCourse


	insert into Staging_area.dbo.TicketCategory
		(
		ticket_category_id,
		title,
		[description]
		)
	select
		ticket_category_id,
		title,
		[description]
	from [Source].dbo.TicketCategory


	insert into Staging_area.dbo.TicketThread
		(
		ticket_thread_id,
		[subject],
		ticket_category_id,
		related_staff_id,
		rating,
		datetime_closed
		)
	select
		ticket_thread_id,
		[subject],
		ticket_category_id,
		related_staff_id,
		rating,
		datetime_closed
	from [Source].dbo.TicketThread


	insert into Staging_area.dbo.Ticket
		(
		ticket_id,
		[text],
		datetime_created,
		ticket_thread_id,
		[user_id]
		)
	select
		ticket_id,
		[text],
		datetime_created,
		ticket_thread_id,
		[user_id]
	from [Source].dbo.Ticket


	insert into Staging_area.dbo.Category
		(
		category_id,
		title
		)
	select
		category_id,
		title
	from [Source].dbo.Category


	insert into Staging_area.dbo.CourseCategory
		(
		course_id,
		category_id
		)
	select
		course_id,
		category_id
	from [Source].dbo.CourseCategory


	insert into Staging_area.dbo.Job
		(
		job_id,
		job_title,
		job_description
		)
	select
		job_id,
		job_title,
		job_description
	from [Source].dbo.Job


	insert into Staging_area.dbo.Staff
		(
		staff_id,
		first_name,
		last_name,
		date_of_birth,
		email_address,
		is_email_verified,
		phone_number,
		datetime_joined,
		datetime_last_sign_in,
		current_monthly_salary,
		gender,
		short_description,
		username,
		job_id,
		hash_salt,
		password_hash
		)
	select
		staff_id,
		first_name,
		last_name,
		date_of_birth,
		email_address,
		is_email_verified,
		phone_number,
		datetime_joined,
		datetime_last_sign_in,
		current_monthly_salary,
		gender,
		short_description,
		username,
		job_id,
		hash_salt,
		password_hash
	from [Source].dbo.Staff


	insert into Staging_area.dbo.Payment
		(
		payment_id,
		staff_id,
		amount,
		date_of_payment
		)
	select
		payment_id,
		staff_id,
		amount,
		date_of_payment
	from [Source].dbo.Payment


END
GO

EXEC Create_Staging_area
EXEC Fill_Staging_area


--select * from Staging_area.dbo.Instructor
--select * from Staging_area.dbo.OnlineCourse
--select * from Staging_area.dbo.Topic
--select * from Staging_area.dbo.SubTopic
--select * from Staging_area.dbo.Downloaded
--select * from Staging_area.dbo.OffPrice
--select * from Staging_area.dbo.CourseInstructor
--select * from Staging_area.dbo.[User]
--select * from Staging_area.dbo.Comment
--select * from Staging_area.dbo.CommentVote
--select * from Staging_area.dbo.UserOnlineCourse
--select * from Staging_area.dbo.TicketCategory
--select * from Staging_area.dbo.TicketThread
--select * from Staging_area.dbo.Ticket
--select * from Staging_area.dbo.Category
--select * from Staging_area.dbo.CourseCategory
--select * from Staging_area.dbo.Job
--select * from Staging_area.dbo.Staff
--select * from Staging_area.dbo.Payment