Use staging_area
Go

select * from staging_area.dbo.Comment

Update Comment 
set datetime_created=CURRENT_TIMESTAMP
where comment_id>24990

Update CommentVote 
set datetime_created=CURRENT_TIMESTAMP
where comment_id>24990

select * from CommentVote inner join Comment on Comment.comment_id=CommentVote.comment_id

select * from staging_area.dbo.CommentVote where datetime_created > '2020-11-12'