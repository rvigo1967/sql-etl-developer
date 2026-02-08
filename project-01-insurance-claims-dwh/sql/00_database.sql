Use master;

-- Create database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'InsuranceClaimsDwh')
CREATE DATABASE InsuranceClaimsDwh;
GO
