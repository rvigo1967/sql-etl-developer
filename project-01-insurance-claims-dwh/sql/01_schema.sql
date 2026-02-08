
Use InsuranceClaimsDwh;

-- Create schemas
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='stg') EXEC('CREATE SCHEMA stg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='dim') EXEC('CREATE SCHEMA dim');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='fact') EXEC('CREATE SCHEMA fact');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='etl') EXEC('CREATE SCHEMA etl');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='rpt') EXEC('CREATE SCHEMA rpt');
GO

-- ETL audit tables
CREATE TABLE etl.LoadRun (
  LoadRunId       INT IDENTITY(1,1) PRIMARY KEY,
  LoadName        NVARCHAR(100) NOT NULL,
  StartedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  EndedAt         DATETIME2(0) NULL,
  Status          NVARCHAR(20) NOT NULL DEFAULT 'RUNNING', -- RUNNING/SUCCESS/FAILED
  RowsInserted    INT NOT NULL DEFAULT 0,
  RowsUpdated     INT NOT NULL DEFAULT 0,
  RowsRejected    INT NOT NULL DEFAULT 0
);

CREATE TABLE etl.LoadRunError (
  LoadRunErrorId  INT IDENTITY(1,1) PRIMARY KEY,
  LoadRunId       INT NOT NULL,
  ErrorAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  ErrorNumber     INT NULL,
  ErrorMessage    NVARCHAR(4000) NULL,
  ErrorProcedure  NVARCHAR(200) NULL,
  ErrorLine       INT NULL,
  CONSTRAINT FK_LoadRunError_LoadRun FOREIGN KEY (LoadRunId) REFERENCES etl.LoadRun(LoadRunId)
);

CREATE TABLE etl.RejectRow (
  RejectRowId     INT IDENTITY(1,1) PRIMARY KEY,
  LoadRunId       INT NOT NULL,
  SourceSystem    NVARCHAR(50) NOT NULL,
  EntityName      NVARCHAR(50) NOT NULL,
  RejectReason    NVARCHAR(400) NOT NULL,
  Payload         NVARCHAR(MAX) NULL,
  RejectedAt      DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_RejectRow_LoadRun FOREIGN KEY (LoadRunId) REFERENCES etl.LoadRun(LoadRunId)
);
GO

-- Staging tables (simulate raw extracts)
CREATE TABLE stg.CustomerRaw (
  SourceCustomerId NVARCHAR(50) NOT NULL,
  FullName         NVARCHAR(200) NOT NULL,
  DateOfBirth      DATE NULL,
  Email            NVARCHAR(200) NULL,
  StateCode        CHAR(2) NULL,
  UpdatedAt        DATETIME2(0) NOT NULL
);

CREATE TABLE stg.PolicyRaw (
  SourcePolicyId   NVARCHAR(50) NOT NULL,
  SourceCustomerId NVARCHAR(50) NOT NULL,
  PolicyType       NVARCHAR(50) NOT NULL,
  EffectiveDate    DATE NOT NULL,
  ExpirationDate   DATE NULL,
  UpdatedAt        DATETIME2(0) NOT NULL
);

CREATE TABLE stg.ClaimRaw (
  SourceClaimId    NVARCHAR(50) NOT NULL,
  SourcePolicyId   NVARCHAR(50) NOT NULL,
  LossDate         DATE NOT NULL,
  ClaimStatus      NVARCHAR(30) NOT NULL,
  ClaimAmount      DECIMAL(12,2) NOT NULL,
  UpdatedAt        DATETIME2(0) NOT NULL
);
GO

-- Dimensions (SCD Type 1 for simplicity)
CREATE TABLE dim.Customer (
  CustomerKey      INT IDENTITY(1,1) PRIMARY KEY,
  SourceCustomerId NVARCHAR(50) NOT NULL UNIQUE,
  FullName         NVARCHAR(200) NOT NULL,
  DateOfBirth      DATE NULL,
  Email            NVARCHAR(200) NULL,
  StateCode        CHAR(2) NULL,
  LastUpdatedAt    DATETIME2(0) NOT NULL
);

CREATE TABLE dim.Policy (
  PolicyKey        INT IDENTITY(1,1) PRIMARY KEY,
  SourcePolicyId   NVARCHAR(50) NOT NULL UNIQUE,
  CustomerKey      INT NOT NULL,
  PolicyType       NVARCHAR(50) NOT NULL,
  EffectiveDate    DATE NOT NULL,
  ExpirationDate   DATE NULL,
  LastUpdatedAt    DATETIME2(0) NOT NULL,
  CONSTRAINT FK_Policy_Customer FOREIGN KEY (CustomerKey) REFERENCES dim.Customer(CustomerKey)
);

CREATE TABLE dim.Date (
  DateKey          INT NOT NULL PRIMARY KEY, -- YYYYMMDD
  [Date]           DATE NOT NULL UNIQUE,
  [Year]           SMALLINT NOT NULL,
  [Month]          TINYINT NOT NULL,
  [Day]            TINYINT NOT NULL,
  MonthName        NVARCHAR(20) NOT NULL
);
GO

-- Fact table
CREATE TABLE fact.Claim (
  ClaimKey         INT IDENTITY(1,1) PRIMARY KEY,
  SourceClaimId    NVARCHAR(50) NOT NULL UNIQUE,
  PolicyKey        INT NOT NULL,
  LossDateKey      INT NOT NULL,
  ClaimStatus      NVARCHAR(30) NOT NULL,
  ClaimAmount      DECIMAL(12,2) NOT NULL,
  LastUpdatedAt    DATETIME2(0) NOT NULL,
  CONSTRAINT FK_Claim_Policy FOREIGN KEY (PolicyKey) REFERENCES dim.Policy(PolicyKey),
  CONSTRAINT FK_Claim_Date   FOREIGN KEY (LossDateKey) REFERENCES dim.Date(DateKey)
);
GO

-- Helpful indexes
CREATE INDEX IX_Customer_State ON dim.Customer(StateCode);
CREATE INDEX IX_Policy_Customer ON dim.Policy(CustomerKey);
CREATE INDEX IX_Claim_Status ON fact.Claim(ClaimStatus) INCLUDE (ClaimAmount, LossDateKey, PolicyKey);
CREATE INDEX IX_Claim_LossDate ON fact.Claim(LossDateKey) INCLUDE (ClaimAmount, ClaimStatus, PolicyKey);
GO

