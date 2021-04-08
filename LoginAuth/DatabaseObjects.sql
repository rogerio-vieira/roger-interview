--=============================================================================
-- Login Tables 

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE type = N'U' and name = N'tblUser')
BEGIN

	CREATE TABLE [dbo].[tblUser]
	(
		[UserId] [int] IDENTITY(1,1) NOT NULL,
		[UserName] [nvarchar](50) NULL,
		[UserPassword] [nvarchar](256) NULL,
		[UserEmail] [nvarchar](500) NULL,
		[UserLastLogin] [datetime] NULL,
		[UserEnabled] [bit] NOT NULL,
		[UserCreated] [datetime] NULL,
		[Attempts] [int] NULL,
		[AuthToken] [uniqueidentifier] NOT NULL,
		CONSTRAINT [tblUser_Pk] PRIMARY KEY CLUSTERED
		(
			[UserId] ASC
		)
	)

	ALTER TABLE [dbo].[tblUser] ADD DEFAULT ((0)) FOR [UserEnabled];
	ALTER TABLE [dbo].[tblUser] ADD DEFAULT ((0)) FOR [Attempts];
	ALTER TABLE [dbo].[tblUser] ADD DEFAULT (NEWID()) FOR [AuthToken];

END
GO


IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE type = N'U' and name = N'tblUserLog')
BEGIN

	CREATE TABLE [dbo].[tblUserLog]
	(
		[UserLogId] [int] IDENTITY(1,1) NOT NULL,
		[UserId] [int] NOT NULL,
		[StartTime] [datetime] NOT NULL,
		[EndTime] [datetime] NULL
		CONSTRAINT [tblUserLog_Pk] PRIMARY KEY CLUSTERED
		(
			[UserLogId] ASC
		),
		FOREIGN KEY (UserId) REFERENCES tblUser(UserId)
	)

END
GO
--=============================================================================
-- Procedure 

IF EXISTS (SELECT 1 FROM sys.procedures WHERE type = N'P' and name = N'usp_GetUserAccessCurrentMonth')
BEGIN
	DROP PROCEDURE dbo.usp_GetUserAccessCurrentMonth;
END
GO

CREATE PROCEDURE dbo.usp_GetUserAccessCurrentMonth
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT 
		u.UserName, 
		u.UserEmail,
		MAX(StartTime) UserLastLogin,
		COUNT(1) UserLoginsPerPeriod,
		(
			SELECT DATEADD(SECOND, AVG(DATEDIFF(SECOND, StartTime, EndTime)), CAST('00:00' AS TIME(0)) ) FROM dbo.tblUserLog
		) UserLoginAvgDuration
	FROM 
		dbo.tblUser u 
		INNER JOIN dbo.tblUserLog ul ON u.UserId = ul.UserId
	WHERE
		ul.StartTime >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	GROUP BY 
		u.UserName, 
		u.UserEmail
	ORDER BY 
		UserLoginsPerPeriod DESC

END
GO

--=============================================================================
-- Dummy Data Test

INSERT INTO dbo.tblUser (UserName, UserPassword, UserEmail, UserLastLogin, UserCreated) VALUES ('rvieira', '*******', 'rvieira55312@gmail.com', GETDATE()+1, GETDATE())

DECLARE @Counter INT = 10;
DECLARE @startTime DATETIME;
DECLARE @endTime DATETIME;

WHILE (@Counter >= 1)
BEGIN

	SET @startTime = DATEADD(DAY, -(@Counter), GETDATE());
	SET @endTime = DATEADD(SECOND, 30, @startTime);
	
	INSERT INTO dbo.tblUserLog (UserId, StartTime, EndTime) VALUES (1, @startTime, @endTime);

	SET @Counter -= 1;

END
GO

SELECT * FROM tblUser
SELECT * FROM tblUserLog

EXEC dbo.usp_GetUserAccessCurrentMonth