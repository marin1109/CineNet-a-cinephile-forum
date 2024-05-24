-- open psql

-- drop database if exists
DROP DATABASE IF EXISTS cinenet;

-- create database
CREATE DATABASE cinenet;

-- create tables
\i Load_DB.sql

-- create request 
\i Question.sql