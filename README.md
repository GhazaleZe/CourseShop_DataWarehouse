# CourseShop_DataWarehouse
### Note: Full Persian documentation is available in [document.pdf](https://github.com/GhazaleZe/CourseShop_DataWarehouse/blob/main/document.pdf)   
## About Source database:   
- The source database of this data warehouse is a database for the online education sales website. In this way, users enter the website and purchase the courses that they want.   This website has users and a special role of users, including student(user), instructor, and staff. Users can buy the course they want. This course is offered by an instructor. The staff responds to relevant questions and tickets or has other tasks such as programming and related works.  
- This database contains 23 tables.
## About Data Warehouse:
- This designed data warehouse for this source database contains :
   - 7 Dimensions
   - 3 Marts 
   - 18 Fact
### Dimensions: 
- S_Dim_User
- S_Dim_Course
- S_Dim_Date
- C_Dim_CourseTopic
- HR_Dim_Instructor
- HR_Dim_Staff
- HR_Dim_TicketCategory
### Marts
- Course_Education
- User Behavior 
- Human Resources
### Course_Education Mart's Facts
- C_Fact_CourseBuying
- C_Fact_CourseBuying_Periodic
- C_Fact_Course_Buying_Acc
- C_Fact_CourseDownloading
- C_Fact_Course_Downloading_Periodic 
### User Behavior Mart's Facts
- U_Fact_UserRating 
- U_Fact_PassedCourses 
- U_Fact_UserRate_Acc 
- U_Fact_Comments 
- U_Fact_CommentRating 
- U_Fact_InfluentialUsers_Acc
### Human Resources Mart's Facts
- HR_Fact_InstructorCourse_T
- HR_Fact_InstructorCourse_ACC
- HR_Fact_InstructorRate_Daily
- HR_Fact_StaffPayment_T
- HR_Fact_StaffPayment_Yearly
- HR_Fact_Tickets_Daily
