# Case Study #3 - Foodie-Fi 🥑
Reference: [8 Week SQL Challenge - Foodie-Fi](https://8weeksqlchallenge.com/case-study-3/)
***
## Introduction
Subscription based businesses are super popular and Danny realised that there was a large gap in the market - he wanted to create a new streaming service that only had food related content - something like Netflix but with only cooking shows!

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.
***
## Available Data
Danny has shared the data design for Foodie-Fi and also short descriptions on each of the database tables - our case study focuses on only 2 tables but there will be a challenge to create a new table for the Foodie-Fi team.

All datasets exist within the foodie_fi database schema - be sure to include this reference within your SQL scripts as you start exploring the data and answering the case study questions.
***
### Entity Relationship Diagram
![Foodie-FiERD](Foodie-FiERD.png)
***
## Case Study Questions
This case study is split into an initial data understanding question before diving straight into data analysis questions before finishing with 1 single extension challenge.
## A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

```sql

SELECT *
FROM subscriptions
JOIN plans
USING (plan_id)
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18 ,19);

```
#### From the eight sample customers provided in the subscriptions table, all of them subscribed to a trial before choosing another plan. Only two customers from the sample did not continue their subscription.
![Week-3-A](FoodieFiOutput/Week-3-A.png)
***
