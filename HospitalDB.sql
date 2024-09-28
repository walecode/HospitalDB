--					############################  SECTION 1 ############################
-- In this section, the database tables, functions, stored procedures and triggers will be created.

CREATE DATABASE HospitalDB;

USE HospitalDB;
GO

-- Patients Table
CREATE TABLE Patients(
PatientID int PRIMARY KEY NOT NULL IDENTITY(1,1),
PatientFirstName nvarchar(30) NOT NULL,
PatientMiddleName nvarchar(30) NULL,
PatientLastName nvarchar(30) NOT NULL,
PatientAddress1 nvarchar(50) NOT NULL,
PatientAddress2 nvarchar(50) NULL,
PatientCity nvarchar(50) NULL,
PatientPostCode nvarchar(10) NOT NULL,
PatientDOB date NOT NULL,
Insurance varchar(10) UNIQUE NULL,
PasswordHash nvarchar(64) NOT NULL,
Salt UNIQUEIDENTIFIER,
PatientEmail nvarchar(50) UNIQUE NOT NULL,
UserName nvarchar(40) NOT NULL UNIQUE,
PatientTelephone nvarchar(20) NOT NULL,
DateJoined date NOT NULL,
DateLeft date NULL,
CONSTRAINT CK_Insuarance CHECK (LEN(Insurance) = 10),
CONSTRAINT ck_UserName CHECK (LEN(UserName) >= 6),
CONSTRAINT ck_PatientEmail CHECK (PatientEmail LIKE '[a-z,0-9,_,-,.]%@[a-z,0-9,_,-]%.[a-z][a-z]%')
);
GO

-- Departments Table
CREATE TABLE Departments(
DepartmentID tinyint PRIMARY KEY NOT NULL IDENTITY(1,1),
DepartmentName nvarchar(50) NOT NULL,
DepartmentLocation nvarchar(50) NOT NULL);
GO

-- Doctors Table
CREATE TABLE Doctors(
DoctorID int PRIMARY KEY NOT NULL IDENTITY(1,1),
DoctorFirstName nvarchar(30) NOT NULL,
DoctorMiddleName nvarchar(30) NULL,
DoctorLastName nvarchar(30) NOT NULL,
DoctorSpecialty nvarchar(50) NOT NULL,
DepartmentID tinyint NOT NULL,
CONSTRAINT fk_Doc_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
);
GO

-- Appointment Table
CREATE TABLE Appointments(
AppointmentID int PRIMARY KEY NOT NULL IDENTITY(1,1),
PatientID int NULL,
DoctorID int NULL,
AppointmentDate date NOT NULL,
AppointmentStartTime time(0) NOT NULL,
AppointmentEndTime time(0) NOT NULL,
AppointmentStatus nvarchar(20) COLLATE Latin1_General_CI_AI NOT NULL DEFAULT ('PENDING'),
DepartmentID tinyint NULL,
CONSTRAINT fk_Appt_PatientID FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
CONSTRAINT fk_Appt_DoctorID FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
CONSTRAINT fk_Appt_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
CONSTRAINT ck_AppointmentStatus CHECK (AppointmentStatus IN ('PENDING', 'COMPLETED', 'CANCELLED')),
CONSTRAINT ck_Appt_ThirtyMinuteSlotStart CHECK (DATEPART(MINUTE, AppointmentStartTime) % 30 = 0 AND DATEPART(SECOND, AppointmentStartTime) = 0),
CONSTRAINT ck_Appt_ThirtyMinuteSlotEnd CHECK (DATEPART(MINUTE,  AppointmentEndTime) % 30 = 0 AND DATEPART (SECOND, AppointmentEndTime) = 0),
CONSTRAINT ck_Appt_HospitalStartTime CHECK (DATEPART(HOUR, AppointmentStartTime) >= 9 AND DATEPART(HOUR, DATEADD(MINUTE, 30, AppointmentStartTime)) <= 17),
CONSTRAINT ck_Appt_HospitalEndTime CHECK (DATEPART(HOUR, DATEADD(SECOND, -1, AppointmentEndTime)) <= 17),
CONSTRAINT ck_Appt_EndsAfterStartTime CHECK (AppointmentStartTime < AppointmentEndTime)
);
GO


-- Medical Records table
CREATE TABLE MedicalRecords(
RecordID int PRIMARY KEY NOT NULL IDENTITY(1,1),
DoctorID int NOT NULL,
PatientID int NOT NULL,
CONSTRAINT fk_mr_DoctorID FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
CONSTRAINT fk_mr_PatientID FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);
GO


-- Diagnosis Table
CREATE TABLE Diagnosis(
DiagnosisID int  PRIMARY KEY NOT NULL IDENTITY(1,1),
Diagnosis nvarchar(100) NOT NULL,
RecordID int NOT NULL,
CONSTRAINT fk_diag_RecordID FOREIGN KEY (RecordID) REFERENCES MedicalRecords(RecordID)
);
GO


-- Allergy Table
CREATE TABLE Allergy(
AllergyID int PRIMARY KEY NOT NULL IDENTITY(1,1),
Allergy nvarchar(100) NOT NULL,
RecordID int NOT NULL,
CONSTRAINT fk_algy_RecordID FOREIGN KEY (RecordID) REFERENCES MedicalRecords(RecordID)
);
GO


-- Medicine Table
CREATE TABLE Medicine(
MedicineID int PRIMARY KEY NOT NULL IDENTITY(1,1),
Medicine nvarchar(100) NOT NULL,
MedicinePrescribedDate date NOT NULL,
RecordID int NOT NULL,
CONSTRAINT fk_med_RecordID FOREIGN KEY (RecordID) REFERENCES MedicalRecords(RecordID)
);
GO


-- THE PAST APPOINTMENTS TABLE IS DESIGNED TO BE A SIMILAR TABLE TO THE APPOINTMENT TABLE, BUT WILL ONLY HOLD RECORDS OF APPOINTMENTS THAT HAVE BEEN COMPLETED, I.E. THE APPOINTMENT STATUS IS COMPLETED. THE IDEA IS THAT THIS TABLE WOULD STORE RECORDS OF THE MAIN APPOINTMENT TABLE THAT HAVE BEEN COMPLETED (THE PAST APPOINTMENT TABLE WILL BE DIRECTLY POPULATED WITH ROWS FROM THE MAIN APPOINTMENT TABLE, NO MANUAL INSERT), SO THERE ISN'T A NEED FOR AS SIMILAR CONSTRAINT CHECKS ON THE APPOINTMENTSTARTTIME, APPOINTMENTENDTIME AND APPOINTMENTDATE COLUMNS LIKE IN THE MAIN APPOINTMENT TABLE.
CREATE TABLE PastAppointments(
AppointmentID int PRIMARY KEY, -- There won't be a need for the identity keyword
PatientID int NOT NULL,
DoctorID int NOT NULL,
AppointmentDate date NOT NULL,
AppointmentStartTime time(0) NOT NULL,
AppointmentEndTime time(0) NOT NULL,
AppointmentStatus nvarchar(20),
DepartmentID tinyint NULL,
CONSTRAINT fk_pstAppt_PatientID FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
CONSTRAINT fk_pstAppt_DoctorID FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
CONSTRAINT fk_pstAppt_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
CONSTRAINT ck_pstAppointmentStatus CHECK (AppointmentStatus = 'COMPLETED'),	-- This constraints ensures only appointments with a completed status are in the past appointment table.
);
GO


-- Feedback Table
CREATE TABLE Feedback(
FeedbackId int PRIMARY KEY NOT NULL IDENTITY(1,1),
FeedbackComment nvarchar(max) NULL,
FeedbackRating tinyint NULL,
AppointmentID int NOT NULL,
CONSTRAINT ck_FeedbackRating CHECK (FeedbackRating >= 1 AND FeedbackRating <= 5), 		-- This ensures that ratings will range from 1 to 5, with 1 being the minimum and 5 being the maximum rating.
CONSTRAINT fk_fb_AppointmentID FOREIGN KEY (AppointmentID) REFERENCES PastAppointments(AppointmentID)
);
GO


-- The DoctorAvailabilitySlot table will keep track of a doctor/s available slots for each day.  Each Slot is 30 minutes long.
CREATE TABLE DoctorAvailabilitySlot(
SlotID int PRIMARY KEY NOT NULL IDENTITY(1,1),
DoctorID int NOT NULL,
SlotStartTime time(0) NOT NULL,
SlotEndTime time(0) NOT NULL,
SlotDate date NOT NULL,
IsBooked bit NOT NULL DEFAULT 0,
CONSTRAINT uc_ UNIQUE (DoctorID, SlotStartTime, SlotEndTime, SlotDate), -- Checks slot entries are not duplicated.
CONSTRAINT fk_da_DoctorID FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
CONSTRAINT ck_da_ThirtyMinuteSlotStart CHECK (DATEPART(MINUTE, SlotStartTime) % 30 = 0 AND DATEPART(SECOND, SlotStartTime) = 0),
CONSTRAINT ck_da_ThirtyMinuteSlotEnd CHECK (DATEPART(MINUTE,  SlotEndTime) % 30 = 0 AND DATEPART (SECOND, SlotEndTime) = 0),
CONSTRAINT ck_da_HospitalStartTime CHECK (DATEPART(HOUR, SlotStartTime) >= 9 AND DATEPART(HOUR, DATEADD(MINUTE, 30, SlotStartTime)) <= 17),
CONSTRAINT ck_da_HospitalEndTime CHECK (DATEPART(HOUR, DATEADD(SECOND, -1, SlotEndTime)) <= 17),
CONSTRAINT ck_da_EndsAfterStartTime CHECK (SlotStartTime < SlotEndTime)
);
GO


-- This stored procedure would be used on the Patient Registration portal for patients to register their details on the database. 
CREATE PROCEDURE uspPatientRegistration
	@firstName nvarchar(30),
	@middleName nvarchar(30) = NULL,
	@lastName nvarchar(30),
	@address1 nvarchar(50),
	@address2 nvarchar(50) = NULL,
	@city nvarchar(50) = NULL,
	@postCode nvarchar(10),
	@dob date,
	@insurance varchar(10) = NULL,
	@username nvarchar(40),
	@password nvarchar(50),
	@email nvarchar(50),
	@telephone nvarchar(20),
	@dateJoined date
AS
BEGIN TRANSACTION
BEGIN TRY
	DECLARE @salt UNIQUEIDENTIFIER=NEWID()
	INSERT INTO Patients (PatientFirstName, PatientMiddleName, PatientLastName, PatientAddress1, PatientAddress2, PatientCity, PatientPostCode, PatientDOB, Insurance,
				UserName, PasswordHash, Salt, PatientEmail, PatientTelephone, DateJoined)
	VALUES (@firstName, @middleName, @lastName, @address1, @address2, @city, @postCode, @dob, @insurance, @username, 
			HASHBYTES('SHA2_512', @password+CAST(@salt AS nvarchar(36))), @salt, @email, @telephone, @dateJoined)
COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO




-- This stored procedure would be used by doctors to update the new Diagnosis for a patient.
CREATE PROCEDURE uspNewDiagnosis
	@docID int, @pID int, @diagnosis nvarchar(100)
AS
BEGIN TRANSACTION
BEGIN TRY
	DECLARE @recordID int
	INSERT INTO MedicalRecords(DoctorID, PatientID)
	VALUES (@docID, @pID)

	SET @recordID = SCOPE_IDENTITY(); 		-- Retrieves the identity value that was generated for the inserted medical record.
	INSERT INTO Diagnosis(Diagnosis, RecordID)
	VALUES (@diagnosis, @recordID)
COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO



-- This stored procedure would be used by doctors to update the new Allergy for a patient.
CREATE PROCEDURE uspNewAllergy
	@docID int, @pID int, @allergy nvarchar(100)
AS
BEGIN TRANSACTION
BEGIN TRY
	DECLARE @recordID int
	INSERT INTO MedicalRecords(DoctorID, PatientID)
	VALUES (@docID, @pID)

	SET @recordID = SCOPE_IDENTITY(); 			-- Retrieves the identity value that was generated for the inserted medical record.

	INSERT INTO Allergy(Allergy, RecordID)
	VALUES (@allergy, @recordID)

COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO




-- This stored procedure would be used by doctors to update the new Medicine for a patient.
CREATE PROCEDURE uspNewMedicine
	@docID int,	@pID int,	@medicine nvarchar(100),	@medPrescDate date
AS
BEGIN TRANSACTION
BEGIN TRY
	DECLARE @recordID int
	INSERT INTO MedicalRecords(DoctorID, PatientID)
	VALUES (@docID, @pID)

	SET @recordID = SCOPE_IDENTITY(); 			-- Retrieves the identity value that was generated for the inserted medical record.
	INSERT INTO Medicine(Medicine, MedicinePrescribedDate, RecordID)
	VALUES (@medicine, @medPrescDate, @recordID)

COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO



-- For entering slots for doctors on the database.
CREATE PROCEDURE uspInsertDoctorAvailabilitySlot
	@docID int,
	@startTime time(0),
	@endTime time(0),
	@slotDate date
AS
BEGIN TRANSACTION
BEGIN TRY
	INSERT INTO DoctorAvailabilitySlot(DoctorID, SlotStartTime, SlotEndTime, SlotDate)
	VALUES (@docID, @startTime, @endTime, @slotDate)

COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO

CREATE TRIGGER SlotIsBooked ON Appointments
AFTER INSERT
AS BEGIN
	DECLARE @slotID INT;
	DECLARE @doctorID INT;
	DECLARE @startTime time(0);
	DECLARE @slotDate date;

	SELECT @doctorID = DoctorID from inserted;
	SELECT @startTime = AppointmentStartTime from inserted;
	SELECT @slotDate = AppointmentDate from inserted;

	UPDATE DoctorAvailabilitySlot
	SET IsBooked = 1
	WHERE DoctorID = @doctorID AND SlotStartTime = @startTime AND SlotDate = @slotDate;
END;
GO



-- Checks if a selected appointment is available to be booked
CREATE FUNCTION IsAppointmentTimeAvailableFunction(
@docID INT, @apptStartTime time(0), @apptEndtime time(0), @apptDate date
) RETURNS BIT
BEGIN
		DECLARE @apptconf BIT
		IF EXISTS(
				SELECT 1 FROM DoctorAvailabilitySlot AS das        -- This checks if the selected appointment date/time is available in the DoctorAvailabilitySlot 
				WHERE @apptDate = das.SlotDate						-- table and that the Slot is not booked.
					AND @apptStartTime = das.SlotStartTime
					AND @apptEndtime = das.SlotEndTime
					AND @docID = das.DoctorID
					AND IsBooked = 0
		) 
		BEGIN
			SET @apptconf = 1
		END
		ELSE
		BEGIN
				SET @apptconf = 0
		END	
		RETURN @apptconf
END;
GO



-- A stored procedure to book an appointment.
CREATE PROCEDURE uspBookNewAppointment
	@pID int,	
	@docID int,	 
	@apptDate date,	
	@startTime time(0),	
	@endTime time(0),	
	@deptID int
AS BEGIN TRANSACTION
BEGIN TRY
	IF (dbo.IsAppointmentTimeAvailableFunction(@docID, @startTime, @endTime, @apptDate) = 1)
		BEGIN			
			INSERT INTO Appointments(PatientID, DoctorID, AppointmentDate, AppointmentStartTime, AppointmentEndTime, DepartmentID)
			VALUES (@pID, @docID, @apptDate, @startTime, @endTime, @deptID)
		END
	ELSE
		BEGIN
			PRINT 'The selected appointment for ' + CAST(DATEPART(DAY, @apptDate) AS VARCHAR) + ', ' + CAST(DATEPART(MONTH, @apptDate) AS VARCHAR) + ' ' + 'is  unavailable to be booked'
		END
COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO


--Patient Feedback stored procedure, checks if an appointment has been completed before accepting the patient's feedback.
CREATE PROCEDURE uspPatientFeedback
	@comment nvarchar(max),
	@rating tinyint,
	@apptID int
AS
BEGIN TRANSACTION
BEGIN TRY
	IF EXISTS(
			SELECT 1 FROM PastAppointments AS pa 
			WHERE pa.AppointmentID = @apptID AND pa.AppointmentStatus = 'COMPLETED')
	BEGIN
		INSERT INTO Feedback(FeedbackComment, FeedbackRating, AppointmentID)
		VALUES (@comment, @rating, @apptID)		
	END

	ELSE
	BEGIN
		PRINT 'Appointment has to be completed, before feedback can be given'
	END

COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO


--This stored procedure is created in-order to update the status of appointments that have been completed to the COMPLETED status. It can be calle
CREATE PROCEDURE uspAppointmentCompleted
@apptID int
AS
BEGIN TRANSACTION
BEGIN TRY
			UPDATE Appointments
			SET AppointmentStatus = 'COMPLETED'
			WHERE AppointmentID = @apptID

COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO


-- This stored procedure can update all appointments that are now in the past whos status is pending.
CREATE PROCEDURE uspPendingPastAppointmentsCompleted
AS
BEGIN TRANSACTION
BEGIN TRY
			UPDATE Appointments
			SET AppointmentStatus = 'COMPLETED'
			WHERE AppointmentDate <= CAST(GETDATE() AS DATE) AND AppointmentEndTime <= CAST(GETDATE() AS TIME(0)) AND AppointmentStatus = 'PENDING'

COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO



--This Trigger is initiated when a completed appointment is to be deleted from the appointment table. Instead of deleting the record, the past appoitment table is updated.
CREATE TRIGGER trgUpdatePastAppointments ON Appointments
AFTER DELETE
AS BEGIN
		DECLARE @apptStatus nvarchar(20);
		SELECT @apptStatus = AppointmentStatus FROM DELETED;
		IF @apptStatus = 'COMPLETED'
		BEGIN
			INSERT INTO PastAppointments (AppointmentID, PatientID, DoctorID, AppointmentDate, AppointmentStartTime, AppointmentEndTime, AppointmentStatus, DepartmentID)
			SELECT d.AppointmentID, d.PatientID, d.DoctorID, d.AppointmentDate, d.AppointmentStartTime, d.AppointmentEndTime, d.AppointmentStatus, d.DepartmentID
			FROM DELETED as d;
		END
END;
GO

CREATE PROCEDURE uspClearBookedandExpiredSlot
AS
BEGIN TRANSACTION
BEGIN TRY
			DELETE FROM DoctorAvailabilitySlot 
			WHERE SlotDate < CAST(GETDATE() AS DATE) OR SlotEndTime < CAST(GETDATE() AS TIME(0))

COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO


--					############################  SECTION 2 ############################
-- In this section, data is inserted into the tables using insert statements, and the stored procedures.
	
-- Entering some values into the Patients table using the PatientRegistration Stored Procedure.
EXEC uspPatientRegistration 
@firstName= 'James', @middleName = 'Taiwo', @lastName = 'Bankole', @address1 ='Apartment 5, Sedgewick Court', @address2 = 'Westy Lane', @city = 'Salford', @postcode = 'M6 8TP', 
@dob = '1999-10-02', @insurance = '0123456789', @username = 'jbanks1', @password = '1@Jbanks', @email = 'jamesbankole@yahoo.com', @telephone = '01314463628',
@dateJoined = '1999-10-03';
EXEC uspPatientRegistration 
@firstName= 'Paul', @middleName = 'Kehinde', @lastName = 'Bankole', @address1 ='Apartment 5, Sedgewick Court', @address2 = 'Westy Lane', @city = 'Salford', @postcode = 'M6 8TP', 
@dob = '1999-10-02', @insurance = '0123456788', @username = 'pbanksy', @password = '2@BanksP', @email = 'paul.bankole@gmail.com', @telephone = '07414473629',
@dateJoined = '1999-10-03';
EXEC uspPatientRegistration 
@firstName= 'Cameron', @lastName = 'Cleverly', @address1 = '5, Barton Crescent', @address2 = 'Leigh', @city = 'Wigan', @postcode = 'WN7 9WX', 
@dob = '1982-09-02', @insurance = '0003456990', @username = 'CC300ly', @password = 'CC%Lima', @email = 'cameroncleverly@yahoo.com', @telephone = '07744363698',
@dateJoined = '2022-01-04';
EXEC uspPatientRegistration 
@firstName= 'Charles', @lastName = 'Boulting', @address1 = '10, Dallam Street', @city = 'Manchester', @postcode = 'M1 2BL', 
@dob = '1985-01-09', @insurance = '0143456780', @username = 'Cboult9', @password = '2@CCwek9', @email = 'cboulting@nhssupport.co.uk', @telephone = '07349463629',
@dateJoined = '2023-10-03';
EXEC uspPatientRegistration 
@firstName= 'Mary', @lastName = 'Singh', @address1 = '16, Ethridge Lane', @city = 'Salford', @postcode = 'M6 9TK', 
@dob = '1999-11-30', @insurance = '0443456789', @username = 'mSingh4', @password = '8MSLeig$', @email = 'singhmary1@gmail.com', @telephone = '07415463629',
@dateJoined = '2022-02-15';
EXEC uspPatientRegistration 
@firstName= 'Naveer', @lastName = 'Singh', @address1 = '16, Ethridge Lane', @city = 'Salford', @postcode = 'M6 9TK', 
@dob = '1995-10-02', @insurance = '0943456788', @username = 'nBigSingh', @password = 'kuB2451', @email = 'sing.naveer@chorleydrinks.co.uk', @telephone = '07314493628',
@dateJoined = '2022-10-03';
EXEC uspPatientRegistration 
@firstName= 'Benita', @lastName = 'Demsley', @address1 = '19, Colton Avenue', @city = 'Salford', @postcode = 'M6 1T9', 
@dob = '2005-03-02', @insurance = '0823456784', @username = 'bdemss1', @password = '1$Bdems', @email = 'bdemsley@yahoo.co.uk', @telephone = '02314463628',
@dateJoined = '2004-09-04';
EXEC uspPatientRegistration 
@firstName= 'Denise', @lastName = 'Maslow', @address1 = 'Maslow Court', @address2 = 'Maslow Close', @city = 'Salford', @postcode = 'M6 7WF', 
@dob = '1960-02-02', @insurance = '0823456780', @username = 'dMaslow', @password = 'D3n1seM', @email = 'denise@maslowcorp.co.uk', @telephone = '01414463628',
@dateJoined = '1999-01-04';
EXEC uspPatientRegistration 
@firstName= 'Mark', @lastName = 'Maslow', @address1 = 'Maslow Court', @city = 'Salford', @postcode = 'M6 7WF', 
@dob = '1959-04-10', @insurance = '0923456680', @username = 'mMaslow', @password = 'M@rkM1', @email = 'mark@maslowcorp.co.uk', @telephone = '01414463623',
@dateJoined = '1999-10-16';
EXEC uspPatientRegistration 
@firstName= 'Christopher', @lastName = 'Barton', @address1 = '4, Winchester Lane', @city = 'Manchester', @postcode = 'M11 7AV', 
@dob = '1992-06-27', @insurance = '0923456789', @username = 'cbarton', @password = 'cBarton2', @email = 'chris@bluefinishing.co.uk', @telephone = '01384463629',
@dateJoined = '2015-10-21';
EXEC uspPatientRegistration 
@firstName= 'Catherine', @lastName = 'Pudsley', @address1 = '92, Fairbone Street', @address2 = 'Bolton, Greater Manchester', @postcode = 'M27 7BF', 
@dob = '1994-10-02', @insurance = '0523456789', @username = 'PudsKate', @password = '28@CateP', @email = 'katepudsley@yahoo.co.uk', @telephone = '01314463628',
@dateJoined = '2021-11-28';
EXEC uspPatientRegistration 
@firstName= 'Samuel', @lastName = 'Moloney', @address1 = '17, Charlton Lane ', @address2 = 'Moston', @city = 'Manchester', @postcode = 'M30 9TV', 
@dob = '2005-10-02', @insurance = '0723456789', @username = 'SamMolo', @password = '27@SamMo2', @email = 'smoloney@gmail.com', @telephone = '07394463628',
@dateJoined = '2018-05-27';
GO

-- Some values will now be entered into the departments table, a stored procedure is not used in this situation as there aren't any data integrity checks done for the department table.
INSERT INTO Departments(DepartmentName, DepartmentLocation)
VALUES ('Accident and Emergency', 'Block B, Fairlough Lane'),
	 ('Cardiology', 'Block A, Fairlough Lane'),
	 ('Pediatrics', 'Block c, Fairlough Lane'),
	 ('Gastroenterology', 'Block D, Fairlough Lane'),
	 ('General Surgery', 'Block E, Fairlough Lane'),
	 ('Obstetrics and Gynaecology', 'Block F, Fairlough Lane'),
	 ('Maternity', 'Block G, Fairlough Lane'),
	 ('Neurology', 'Block H, Fairlough Lane'),
	 ('Radiotherapy', 'Block J, Fairlough Lane'),
	 ('Ear nose and throat (ENT)', 'Block K, Fairlough Lane'),
	 ('Elderly services', 'Block M, Fairlough Lane');


-- Doctor details will be entered into the doctors table using the newDoctor stored procedure.
INSERT INTO Doctors (DoctorFirstName, DoctorLastName, DoctorSpecialty, DepartmentID)
VALUES ('Benedicta', 'Bello', 'Obstetrics and Gynaecology', 6);
INSERT INTO Doctors (DoctorFirstName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Paul', 'Sandston', 'Cardiothoracic surgery', 2);
INSERT INTO Doctors (DoctorFirstName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Ria', 'Padukone', 'Neuropathology', 8);
INSERT INTO Doctors (DoctorFirstName, DoctorMiddleName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Sade', 'Oluwabimpe', 'Cole', 'Geriatric Medicine', 11);
INSERT INTO Doctors (DoctorFirstName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Kuma', 'Kenyatta', 'Gastroenterologists', 4);
INSERT INTO Doctors (DoctorFirstName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Chelsea', 'Darwin', 'Gastroenterologists', 4);
INSERT INTO Doctors (DoctorFirstName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Carlton', 'Cole', 'Pediatric cardiology', 3);
INSERT INTO Doctors (DoctorFirstName, DoctorMiddleName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Yun', 'Oh', 'Mi', 'Emergency Medicine', 1);
INSERT INTO Doctors (DoctorFirstName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Ji', 'Chang-wook', 'Geriatric psychiatry', 11);
INSERT INTO Doctors (DoctorFirstName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Michelle', 'Alozie', 'Maternal-fetal medicine', 7);
INSERT INTO Doctors (DoctorFirstName, DoctorMiddleName, DoctorLastName, DoctorSpecialty, DepartmentID)
	VALUES ('Asisat', 'Lamina','Oshoala', 'Plastic, reconstructive and aesthetic surgery', 1);
GO


---- Doctor Availability Slots is entered uisng the uspInsertDoctorAvailabilitySlot stored procedure.
EXEC uspInsertDoctorAvailabilitySlot
@docID = 1 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 1 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 1 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 1 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 1 , @startTime = '14:30',	@endTime = '15:00', @slotDate = '2024-04-28';


EXEC uspInsertDoctorAvailabilitySlot
@docID = 2 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 2 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 2 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 2 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';


EXEC uspInsertDoctorAvailabilitySlot
@docID = 3 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 3 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 3 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 3 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 3 , @startTime = '14:30',	@endTime = '15:00', @slotDate = '2024-04-28';

EXEC uspInsertDoctorAvailabilitySlot
@docID = 4 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 4 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 4 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 4 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';


EXEC uspInsertDoctorAvailabilitySlot
@docID = 5 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 5 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 5 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 5 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';


EXEC uspInsertDoctorAvailabilitySlot
@docID = 6 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 6 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 6 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 6 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';

EXEC uspInsertDoctorAvailabilitySlot
@docID = 7 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 7 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 7 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 7 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';

EXEC uspInsertDoctorAvailabilitySlot
@docID = 8 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 8 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 8 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 8 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';

EXEC uspInsertDoctorAvailabilitySlot
@docID = 9 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 9 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 9 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 9 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';

EXEC uspInsertDoctorAvailabilitySlot
@docID = 10 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 10 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 10 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 10 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';

EXEC uspInsertDoctorAvailabilitySlot
@docID = 11 , @startTime = '10:00',	@endTime = '10:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 11 , @startTime = '9:30',	@endTime = '10:00', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 11 , @startTime = '16:00',	@endTime = '16:30', @slotDate = '2024-04-28';
EXEC uspInsertDoctorAvailabilitySlot
@docID = 11 , @startTime = '16:30',	@endTime = '17:00', @slotDate = '2024-04-28';
GO


-- Patient(Benita), to see a maternity doctor(Michelle Alozie) in the morning
EXEC uspBookNewAppointment
@pID = 7, @docID = 10, @apptDate = '2024-04-28', @startTime = '10:00', @endTime = '10:30', @deptID = 7;

-- Patient(Samuel), to see doctor(Ria) in the evening
EXEC uspBookNewAppointment
@pID = 12, @docID = 3, @apptDate = '2024-04-28', @startTime = '16:00', @endTime = '16:30', @deptID = 8;

-- Patient(Mark Maslow), to see doctor(Kuma) in the Morning
EXEC uspBookNewAppointment
@pID = 9, @docID = 5, @apptDate = '2024-04-28', @startTime = '10:00', @endTime = '10:30', @deptID = 4;

-- Patient(Denise Maslow), to see doctor(Kuma) in the Morning
EXEC uspBookNewAppointment
@pID = 8, @docID = 5, @apptDate = '2024-04-28', @startTime = '09:30', @endTime = '10:00', @deptID = 4;


-- Patient(James Taiwo Bankole), to see doctor(Chelsea) in the Morning
EXEC uspBookNewAppointment
@pID = 1, @docID = 6, @apptDate = '2024-04-28', @startTime = '10:00', @endTime = '10:30', @deptID = 4;

-- Patient(Cameron Cleverly), to see doctor(Chelsea) in the Evening
EXEC uspBookNewAppointment
@pID = 3, @docID = 6, @apptDate = '2024-04-28', @startTime = '16:00', @endTime = '16:30', @deptID = 4;

-- Patient(Mary Singh), to see doctor(Benedicta), Obstetrics and Gynaecology in the Morning
EXEC uspBookNewAppointment
@pID = 5, @docID = 1, @apptDate = '2024-04-28', @startTime = '10:00', @endTime = '10:30', @deptID = 6;

-- Patient(Catherine Pudsley), to see doctor(Benedicta), Obstetrics and Gynaecology in the Evening
EXEC uspBookNewAppointment
@pID = 11, @docID = 1, @apptDate = '2024-04-28', @startTime = '14:30', @endTime = '15:00', @deptID = 6;
GO

-- Patient(Catherine Pudsley), to see doctor(Ria), in the Morning
EXEC uspBookNewAppointment
@pID = 11, @docID = 3, @apptDate = '2024-04-28', @startTime = '16:30', @endTime = '17:00', @deptID = 8;
GO


-- Doctors setting appointments to completed using the uspAppointmentCompleted stored procedure.
EXEC uspAppointmentCompleted @apptID = 18;
EXEC uspAppointmentCompleted @apptID = 20;
EXEC uspAppointmentCompleted @apptID = 21;
EXEC uspAppointmentCompleted @apptID = 22;
EXEC uspAppointmentCompleted @apptID = 24;
EXEC uspAppointmentCompleted @apptID = 25;

-- Doctors can use the uspNewDiagnosis, uspNewMedicine and uspNewAllergy stored procedures to update new medicine, allergies and diagnosis.
EXEC uspNewDiagnosis
	@docID = 10,
	@pID = 7,
	@diagnosis = 'Pregnancy';

EXEC uspNewDiagnosis
	@docID = 10,
	@pID = 7,
	@diagnosis = 'Fibroid';

EXEC uspNewAllergy
	@docID = 10,
	@pID = 7,
	@allergy = 'Peanuts';

EXEC uspNewMedicine
	@docID = 10,
	@pID = 7,
	@medicine = 'Folic Acid',
	@medPrescDate = '2024-04-22'; 

EXEC uspNewMedicine
	@docID = 10,
	@pID = 7,
	@medicine = 'Claritin',
	@medPrescDate = '2024-04-22';

EXEC uspNewMedicine
	@docID = 10,
	@pID = 7,
	@medicine = 'Sudafed',
	@medPrescDate = '2024-04-22';
GO

EXEC uspNewDiagnosis
	@docID = 5,
	@pID = 9,
	@diagnosis = 'Colon Cancer';

EXEC uspNewAllergy
	@docID = 5,
	@pID = 9,
	@allergy = 'Dust';

EXEC uspNewMedicine
	@docID = 5,
	@pID = 9,
	@medicine = 'Fluorouracil',
	@medPrescDate = '2024-04-22';
GO

EXEC uspNewDiagnosis
	@docID = 5,
	@pID = 8,
	@diagnosis = 'Diarrhoea';

EXEC uspNewAllergy
	@docID = 5,
	@pID = 8,
	@allergy = 'Gluten';

EXEC uspNewMedicine
	@docID = 5,
	@pID = 8,
	@medicine = 'Loperamide',
	@medPrescDate = '2024-04-22';
GO

EXEC uspNewDiagnosis
	@docID = 6,
	@pID = 1,
	@diagnosis = 'Peptic Ulcer';

EXEC uspNewAllergy
	@docID = 6,
	@pID = 1,
	@allergy = 'Hazelnut';

EXEC uspNewMedicine
	@docID = 6,
	@pID = 1,
	@medicine = 'Omeprazole',
	@medPrescDate = '2024-04-22'; 
GO

EXEC uspNewDiagnosis
	@docID = 1,
	@pID = 5,
	@diagnosis = 'Fibroid';

EXEC uspNewDiagnosis
	@docID = 1,
	@pID = 5,
	@diagnosis = 'Cervical Cancer';

EXEC uspNewAllergy
	@docID = 1,
	@pID = 5,
	@allergy = 'Aspergillus fumigatus';

EXEC uspNewAllergy
	@docID = 1,
	@pID = 5,
	@allergy = 'Pollen';

EXEC uspNewMedicine
	@docID = 1,
	@pID = 5,
	@medicine = 'Cisplatin',
	@medPrescDate = '2024-04-22'; 

EXEC uspNewMedicine
	@docID = 1,
	@pID = 5,
	@medicine = 'Cerazette',
	@medPrescDate = '2024-04-22';
GO


EXEC uspNewDiagnosis
	@docID = 1,
	@pID = 11,
	@diagnosis = 'Fibroid';



EXEC uspNewAllergy
	@docID = 1,
	@pID = 11,
	@allergy = 'Hay';


EXEC uspNewMedicine
	@docID = 1,
	@pID = 11,
	@medicine = 'Folic Acid',
	@medPrescDate = '2024-04-22'; 

EXEC uspNewMedicine
	@docID = 1,
	@pID = 11,
	@medicine = 'Cerazette',
	@medPrescDate = '2024-04-22';
GO

-- The uspPatientFeedback stored procedure is used by the patient to get their feedback.
EXEC uspPatientFeedback 
@comment = 'The doctor broke the news of my pregnancy to me in such an wholesome way. I have been trying for a child for about 5 years. I am really thankful to doctor Michelle and the team for their efforts.',
@rating = 5,
@apptID = 18;

EXEC uspPatientFeedback 
@comment = 'Doctor Kuma has been immense, he broke the news to me in a way that it was not devastating. I am on my meds and looking forward to chemotherapy.',
@rating = 5,
@apptID = 20;

EXEC uspPatientFeedback 
@comment = 'Thank you Doctor Kuma, coming to the hospital on that day and hearing the news of my husband''s cancer almost broke me but the way it was handled by doctor Kuma 
and the team was truly awesome. I am getting better from the diahhorea. Thank you!',
@rating = 5,
@apptID = 21;

EXEC uspPatientFeedback 
@comment = 'The doctor wasn''t smiling and I felt they were dismissive of my further complaints.',
@rating = 2,
@apptID = 22;

EXEC uspPatientFeedback 
@comment = 'I am on the meds now and looking forward to Chemotherapy. Thank you Dr. Bello and the team. I am so happy this was discovered at the early stage but felt 
it could have been handled a bit better',
@rating = 4,
@apptID = 24;
GO

EXEC uspPatientFeedback 
@comment = 'Thank You Doctor',
@rating = 5,
@apptID = 25;
GO



--					############################  SECTION 3 ############################
-- In this section, we will be answering some questions which we can use to extract data from the tables and/or alter the tables.
	
-- 		####### QUESTION 1 - A constraint that checks that the appointment date is not in the past.
ALTER TABLE Appointments
ADD CONSTRAINT ck_Date_NotInPast CHECK (AppointmentDate >= CAST(GETDATE() AS date) AND AppointmentStartTime > CAST(GETDATE() AS time(0)));
GO


-- 		####### QUESTION 2 - List all the patients with older than 40 and have Cancer in diagnosis.
SELECT p.PatientFirstName + ' ' + ISNULL(p.PatientMiddleName, '') + ' ' + p.PatientLastName as PatientFullName , p.PatientID, DATEDIFF(YEAR, p.PatientDOB, GETDATE()) as Age, d.Diagnosis
FROM Patients as p INNER JOIN MedicalRecords as m
ON p.PatientID = m.PatientID INNER JOIN Diagnosis as d
ON m.RecordID = d.RecordID
WHERE DATEDIFF(YEAR, p.PatientDOB, GETDATE()) > 40 AND d.Diagnosis LIKE '%cancer';
GO


-- 		####### QUESTION 3 
-- Search the database of the hospital for matching character strings by the name of a medicine. Results should be sorted with most recent medicine prescribed date first.

CREATE PROCEDURE SearchMedicine(@searchString AS nvarchar(100))
AS 
	BEGIN
		SELECT Medicine, MedicinePrescribedDate 
		FROM Medicine
		WHERE Medicine LIKE CONCAT('%',@searchString) OR Medicine LIKE CONCAT('%',@searchString,'%') OR Medicine LIKE CONCAT(@searchString,'%')
		ORDER BY MedicinePrescribedDate DESC
	END;
GO

-- Executing the stored procedure 
EXEC SearchMedicine 'c';
GO


--  		####### QUESTION 4
-- Return a full list of diagnosis and allergies for a specific patient who has an appointment today (i.e., the system date when the query is run) using a stored procedure.

CREATE PROCEDURE uspPatientDiagnosisAndAllergy(@pID AS int)
AS
BEGIN
	WITH PatientRecord(PatientID, PatientFullName, AppointmentDate, Diagnosis) AS
	(
	SELECT p.PatientID, p.PatientFirstName + ' ' + ISNULL(p.PatientMiddleName, '') + ' ' + p.PatientLastName as PatientFullName, a.AppointmentDate, d.Diagnosis
		FROM 
	Appointments as a 
	INNER JOIN  Patients as p ON a.PatientID = p.PatientID
	INNER JOIN MedicalRecords as m ON p.PatientID = m.PatientID
	INNER JOIN Diagnosis as d ON m.RecordID = d.RecordID
	WHERE m.PatientID = @pID
	AND CONVERT(DATE, a.AppointmentDate) = CONVERT(DATE, GETDATE())
	)

	SELECT pr.PatientID, pr.PatientFullName, pr.AppointmentDate, pr.Diagnosis, alg.Allergy
			FROM 
	Appointments as a 
	INNER JOIN  Patients as p ON a.PatientID = p.PatientID
	INNER JOIN PatientRecord as pr ON pr.PatientID = p.PatientID
	INNER JOIN MedicalRecords as m ON p.PatientID = m.PatientID
	INNER JOIN Allergy as alg ON m.RecordID = alg.RecordID
	WHERE m.PatientID = @pID
	AND CONVERT(DATE, a.AppointmentDate) = CONVERT(DATE, GETDATE())
END


-- Executing the stored procedure
EXEC uspPatientDiagnosisAndAllergy @pID = 11



-- 		####### QUESTION 5: Update the details for an existing doctor
CREATE PROCEDURE UpdateDoctorDetails(
	@docId AS INT, 
	@docFirstName AS NVARCHAR(30) = NULL, 
	@docMiddleName AS NVARCHAR(30) = NULL, 
	@docLastName AS NVARCHAR(30) = NULL,
	@docSpecialty AS NVARCHAR(50) = NULL, 
	@deptID AS TINYINT = NULL
)
AS
BEGIN TRANSACTION
BEGIN TRY
-- By using Coalesce in the SET operation, if the user provides a value it will be used Otherwise the current value is used.
	UPDATE Doctors
	SET   
	DoctorFirstName = COALESCE (@docFirstName, DoctorFirstName), 
	DoctorMiddleName = COALESCE (@docMiddleName, DoctorMiddleName), 
	DoctorLastName = COALESCE (@docLastName, DoctorLastName),
	DoctorSpecialty = COALESCE (@docSpecialty, DoctorSpecialty),
	DepartmentID = COALESCE (@deptID, DepartmentID)
	WHERE DoctorID = @docId;
COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO 

-- Executing the Stored Procdure
EXEC UpdateDoctorDetails @docID = 5, @docMiddleName = 'John';


-- 		####### QUESTION 6 
-- Delete the appointment with an already completed status using a stored procedure

-- A new stored procedure is created to delete appointments that have beeen completed.
CREATE PROCEDURE uspDeleteCompletedAppointments
AS
BEGIN TRANSACTION
BEGIN TRY
			DELETE FROM Appointments WHERE AppointmentStatus = 'COMPLETED'

COMMIT TRANSACTION
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION
	DECLARE @ErrorMsg nvarchar(4000), @ErrorSeverity int
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
	RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
END CATCH;
GO 

EXEC uspDeleteCompletedAppointments;
GO


-- 		####### QUESTION 7
-- A view is created for the hospital to retrieve the the appointment date and time, showing all previous and current appointments for all doctors, and
--  including details of the department (the doctor is associated with), doctor’s specialty and any associate review/feedback given for a doctor.
	
CREATE VIEW doctorAppointmentRecords 
AS 
SELECT
		d.DoctorID,		a.AppointmentDate, 		a.AppointmentStartTime, 		a.AppointmentEndTime,		d.DepartmentID, d.DoctorFirstName + ' ' + ISNULL(d.DoctorMiddleName, '') + ' ' + d.DoctorLastName as DoctorFullName,		d.DoctorSpecialty,		f.FeedbackComment
FROM Doctors AS d
JOIN Appointments as a
ON d.DoctorID = a.DoctorID
LEFT OUTER JOIN Feedback as f
ON f.AppointmentID = a.AppointmentID

UNION

SELECT 
		d.DoctorID,		pa.AppointmentDate, 		pa.AppointmentStartTime, 		pa.AppointmentEndTime,		d.DepartmentID, d.DoctorFirstName + ' ' + ISNULL(d.DoctorMiddleName, '') + ' ' + d.DoctorLastName as DoctorFullName,		d.DoctorSpecialty,		f.FeedbackComment
FROM Doctors AS d
JOIN PastAppointments as pa
ON d.DoctorID = pa.DoctorID
JOIN Feedback as f
ON f.AppointmentID = pa.AppointmentID
GO

-- A select statement is used to query the view that was created.
SELECT * FROM doctorAppointmentRecords


-- 		####### QUESTION 8 
-- Create a trigger so that the current state of an appointment can be changed to available when it is cancelled.
	
-- Before creating the trigger,  we add a new check string to accomodate the 'AVAILABLE' status in the ck_AppointmentStatus constraint.
ALTER TABLE Appointments
DROP CONSTRAINT ck_AppointmentStatus;

ALTER TABLE Appointments
ADD CONSTRAINT ck_AppointmentStatus CHECK (AppointmentStatus IN ('PENDING', 'COMPLETED', 'CANCELLED', 'AVAILABLE'));
GO

-- The trigger is then created which instead of updating the column when the status is set to CANCELLED, it updates the appointment status to AVAILABLE.

CREATE TRIGGER trgMakeCancelledApptAvailable
ON
Appointments
INSTEAD OF UPDATE
AS BEGIN
		DECLARE @apptStatus nvarchar(20), @apptID int;

		SELECT @apptStatus = AppointmentStatus, @apptID = AppointmentID  FROM inserted;
		IF @apptStatus = 'CANCELLED'
		BEGIN
			UPDATE Appointments
			SET AppointmentStatus = 'AVAILABLE', PatientID = NULL, DoctorID = NULL, DepartmentID = NULL
			WHERE AppointmentID = @apptID
	
		END
END;
GO

-- The trigger is tested by setting the appointment status to cancelled
UPDATE Appointments
SET AppointmentStatus = 'CANCELLED'
WHERE PatientID = 12;

UPDATE Appointments
SET AppointmentStatus = 'CANCELLED'
WHERE PatientID = 3;

UPDATE Appointments
SET AppointmentStatus = 'CANCELLED'
WHERE PatientID = 11;
GO

SELECT * FROM Appointments

	
-- 		####### QUESTION 9 
-- A query that allows the hospital to identify the number of completed appointments with the specialty of doctors as ‘Gastroenterologists’.
SELECT COUNT(AppointmentID) AS GastroenterologistsAppointment
FROM PastAppointments
WHERE DoctorID IN (SELECT DoctorID FROM Doctors WHERE DoctorSpecialty = 'Gastroenterologists')
