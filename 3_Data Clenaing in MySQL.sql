-- While using the Table Data Import Wizard there was an issue with the columns that had long names, therefore I renamed them in Notepad++ before next import 
SELECT *
FROM `2_survey_renamed columns`;

-- To freely manipulate the data it is best to create a copy of our table
CREATE TABLE survey_edit
LIKE `2_survey_renamed columns`;

SELECT *
FROM survey_edit;

INSERT survey_edit
SELECT *
FROM `2_survey_renamed columns`;

-- First we check if the Unique ID number really does not repeat
SELECT *,
row_number () over (partition by `Unique ID`) AS row_num
FROM survey_edit;

WITH num_cte AS (
SELECT *,
row_number () over (partition by `Unique ID`) AS row_num
FROM survey_edit
)
SELECT *
FROM num_cte
WHERE row_num > 1; -- 0 rows were returned so the Unique ID is really unique 

-- It looks like the Email column does not have relevant information for us, so verify
SELECT *
FROM survey_edit
WHERE Email != 'anonymous'; -- we can get rid of this column

ALTER TABLE survey_edit
DROP COLUMN Email;

-- Now we need to change the Date Taken (America/New_York) to a standard date format in MySQL and update our table accordingly 
SELECT *, str_to_date(`Date Taken (America/New_York)`, '%m/%d/%Y')
FROM survey_edit;

UPDATE survey_edit
SET `Date Taken (America/New_York)` = str_to_date(`Date Taken (America/New_York)`, '%m/%d/%Y');

-- We also want MySQL to see this new data as DATE so
ALTER TABLE survey_edit
modify column `Date Taken (America/New_York)` DATE;

-- We will also set the Time Taken (America/New_York) to a TIME type of data
ALTER TABLE survey_edit
modify column `Time Taken (America/New_York)` TIME;

-- Now we check if in the columns Browser, OS, City and Country are any usable data
SELECT *
FROM survey_edit
WHERE Browser != '';

SELECT *
FROM survey_edit
WHERE OS != '';

SELECT *
FROM survey_edit
WHERE City != '';

SELECT *
FROM survey_edit
WHERE Country != '';

SELECT *
FROM survey_edit
WHERE Referrer != '';

-- And since these columns are completely empty we will drop all of them

ALTER TABLE survey_edit
DROP COLUMN Browser;

ALTER TABLE survey_edit
DROP COLUMN OS;

ALTER TABLE survey_edit
DROP COLUMN City;

ALTER TABLE survey_edit
DROP COLUMN Country;

ALTER TABLE survey_edit
DROP COLUMN Referrer;

-- We will set the Time Spent to TIME data type
ALTER TABLE survey_edit
modify column `Time Spent` TIME;
 
SELECT COUNT(DISTINCT `Q1 - Which Title Best Fits your Current Role?`) 
FROM survey_edit; -- Even though we had selection in this column many people choose the option OTHER and wrote something unique as an answer so we have 80 different answers

-- Here is the list with the 80 different answers, we will try to add them to our basic categories
SELECT `Q1 - Which Title Best Fits your Current Role?`
FROM survey_edit
GROUP BY `Q1 - Which Title Best Fits your Current Role?`;

-- The type of Data Analysis does not matter to us in this point so all Analyst titles will go under this category
SELECT *
FROM survey_edit
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):%Analy%';

UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Data Analyst'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):%Analy%';

-- We still have 56 unique answers so we will group them by some key words
SELECT *
FROM survey_edit
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):%Devel%';

-- We have one person who is a Web Developer
UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Web Developer'
WHERE `Unique ID` = '62a47e3ef3072dd89263c8c0';

-- But the rest under this tag are BI Developers
UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'BI Developer'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):%Devel%';

-- We will try to categorize also the rest of the answers, but really unige ones will go under Other
SELECT *
FROM survey_edit
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):Business Intelligence%';

UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Business Intelligence'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):Business Intelligence%';

SELECT *
FROM survey_edit
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):%Manag%';

-- One of the Managers can go under an already created category so
UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Business Intelligence'
WHERE `Unique ID` = '62b21d40bae91e4b8b985154';

-- Then we can create a Manager category 
UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Manager'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):%Manag%';

-- Then we add these two answers into existing categories
UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Data Scientist'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):Jr. Data Scientist';

UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Business Intelligence'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):BI consultant ';

-- And as said before the rest will have the category Other
UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Other'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify):%';

-- Since the 'BI Developer' and 'Business Intelligence' are small groups we will merge them into one
SELECT *
FROM survey_edit
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'BI Developer';

SELECT *
FROM survey_edit
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Business Intelligence';

UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Business Intelligence'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'BI Developer';

-- Also the 'Other (Please Specify)' and 'Web Developer' will go under 'Other'
UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Other'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Other (Please Specify)';

UPDATE survey_edit
SET `Q1 - Which Title Best Fits your Current Role?` = 'Other'
WHERE `Q1 - Which Title Best Fits your Current Role?` LIKE 'Web Developer';

-- That is how we went from 80 answers to just 9 
SELECT `Q1 - Which Title Best Fits your Current Role?`
FROM survey_edit
GROUP BY `Q1 - Which Title Best Fits your Current Role?`;

-- In the next column we have just 2 option answer
SELECT `Q2 - Did you switch careers into Data?`
FROM survey_edit
GROUP BY `Q2 - Did you switch careers into Data?`;

-- In the next column we have pre-selected ranges
SELECT `Q3 - Current Yearly Salary (in USD)`
FROM survey_edit
GROUP BY `Q3 - Current Yearly Salary (in USD)`;

-- In the next column we have again many different answers due to the Other option
SELECT `Q4 - What Industry do you work in?`
FROM survey_edit
GROUP BY `Q4 - What Industry do you work in?`;

-- I would only separate the Student category from here and put the rest under Other
SELECT *
FROM survey_edit
WHERE `Q4 - What Industry do you work in?` LIKE '%Stud%';

UPDATE survey_edit
SET `Q4 - What Industry do you work in?` = 'Student'
WHERE `Q4 - What Industry do you work in?` LIKE '%Stud%';

UPDATE survey_edit
SET `Q4 - What Industry do you work in?` = 'Other'
WHERE `Q4 - What Industry do you work in?` LIKE 'Other%';

-- In the next column we have again the Other option so we have to clean the answers a bit
SELECT `Q5 - Favorite Programming Language`
FROM survey_edit
GROUP BY `Q5 - Favorite Programming Language`;

SELECT `Q5 - Favorite Programming Language`
FROM survey_edit
WHERE `Q5 - Favorite Programming Language` LIKE '%SQL%'; -- even though we have some answers with Excel that is not a programing language so we can set everything to SQL

UPDATE survey_edit
SET `Q5 - Favorite Programming Language` = 'SQL'
WHERE `Q5 - Favorite Programming Language` LIKE '%SQL%';

-- In this step we will eliminate answers that we do not categorize as programing language, so Power BI, Excel and answers that state they have non
SELECT `Q5 - Favorite Programming Language`
FROM survey_edit
WHERE `Q5 - Favorite Programming Language` LIKE '%power%';

UPDATE survey_edit
SET `Q5 - Favorite Programming Language` = 'none'
WHERE `Q5 - Favorite Programming Language` LIKE '%power%';

UPDATE survey_edit
SET `Q5 - Favorite Programming Language` = 'none'
WHERE `Q5 - Favorite Programming Language` LIKE '%excel%';

SELECT `Q5 - Favorite Programming Language`
FROM survey_edit
WHERE `Q5 - Favorite Programming Language` LIKE '%don%';

UPDATE survey_edit
SET `Q5 - Favorite Programming Language` = 'none'
WHERE `Q5 - Favorite Programming Language` LIKE '%don%';

-- Here we just check if the selected filter will be good for this change
SELECT `Q5 - Favorite Programming Language`
FROM survey_edit
WHERE `Q5 - Favorite Programming Language` LIKE '%no%';

UPDATE survey_edit
SET `Q5 - Favorite Programming Language` = 'none'
WHERE `Q5 - Favorite Programming Language` LIKE '%no%';

UPDATE survey_edit
SET `Q5 - Favorite Programming Language` = 'none'
WHERE `Q5 - Favorite Programming Language` = 'Other:Just started learning ';

UPDATE survey_edit
SET `Q5 - Favorite Programming Language` = 'none'
WHERE `Q5 - Favorite Programming Language` = 'Other:I do analysis and create presentations based on datasets provided by others';

-- Now the rest of the answers can go to Other category
SELECT `Q5 - Favorite Programming Language`
FROM survey_edit
WHERE `Q5 - Favorite Programming Language` LIKE 'Other%';

UPDATE survey_edit
SET `Q5 - Favorite Programming Language` = 'Other'
WHERE `Q5 - Favorite Programming Language` LIKE 'Other%';

-- The Q6 questions always give us a range of Happiness and the data is defined as int, so no edit is required
SELECT *
FROM survey_edit;

-- Next problem is again with the Other option in `Q8 - Most important thing in a new job today` that generates too many answers
SELECT `Q8 - Most important thing in a new job today`
FROM survey_edit
GROUP BY `Q8 - Most important thing in a new job today`;

-- But Learning opportunity is a recurring answer so
SELECT *
FROM survey_edit
WHERE `Q8 - Most important thing in a new job today` LIKE '%learn%';

UPDATE survey_edit
SET `Q8 - Most important thing in a new job today` = 'Learning opportunity'
WHERE `Q8 - Most important thing in a new job today` LIKE '%learn%';

-- The rest will go under category Other
SELECT *
FROM survey_edit
WHERE `Q8 - Most important thing in a new job today` LIKE 'Other%';

UPDATE survey_edit
SET `Q8 - Most important thing in a new job today` = 'Other'
WHERE `Q8 - Most important thing in a new job today` LIKE 'Other%';

-- Now to clean up the Other option in the `Q11 - Which Country do you live in?` we will create a Other category since in many subcategories there are only few same 
SELECT `Q11 - Which Country do you live in?`
FROM survey_edit
GROUP BY `Q11 - Which Country do you live in?`;

SELECT `Q11 - Which Country do you live in?`
FROM survey_edit
WHERE `Q11 - Which Country do you live in?` LIKE 'Other%'; 

UPDATE survey_edit
SET `Q11 - Which Country do you live in?` = 'Other'
WHERE `Q11 - Which Country do you live in?` LIKE 'Other%';

UPDATE survey_edit
SET `Q11 - Which Country do you live in?` = 'Other'
WHERE `Q11 - Which Country do you live in?`= 'Japan';

-- In the next column with education we have also empty fields and we will populate these with non
SELECT `Q12 - Highest Level of Education`
FROM survey_edit
GROUP BY `Q12 - Highest Level of Education`;

SELECT `Q12 - Highest Level of Education`
FROM survey_edit
WHERE `Q12 - Highest Level of Education` LIKE '';

UPDATE survey_edit
SET `Q12 - Highest Level of Education` = 'non'
WHERE `Q12 - Highest Level of Education` LIKE '';

-- For the last column we again clean the Other option
SELECT `Q13 - Ethnicity`
FROM survey_edit
GROUP BY `Q13 - Ethnicity`;

SELECT `Q13 - Ethnicity`
FROM survey_edit
WHERE `Q13 - Ethnicity` LIKE '%Latino%';

UPDATE survey_edit
SET `Q13 - Ethnicity` = 'Hispanic or Latino'
WHERE `Q13 - Ethnicity` LIKE '%Latino%';

-- Here we can see we got also some MIXed race so we filter them out first
SELECT `Q13 - Ethnicity`
FROM survey_edit
WHERE `Q13 - Ethnicity` LIKE '%African%';

SELECT `Q13 - Ethnicity`
FROM survey_edit
WHERE `Q13 - Ethnicity` LIKE '%half%'; -- '%mix%'

UPDATE survey_edit
SET `Q13 - Ethnicity` = 'Mix'
-- WHERE `Q13 - Ethnicity` LIKE '%half%'; -- '%mix%'
WHERE `Q13 - Ethnicity` = 'Other (Please Specify):Bi-racial people should be able to check 2 options in 2022. ';

UPDATE survey_edit
SET `Q13 - Ethnicity` = 'Black or African American'
WHERE `Q13 - Ethnicity` LIKE '%African%';

-- Then we again try to put these answers under Option into an already existing bigger category
SELECT `Q13 - Ethnicity`
FROM survey_edit
WHERE `Q13 - Ethnicity` LIKE '%Indian%';

UPDATE survey_edit
SET `Q13 - Ethnicity` = 'Indian'
WHERE `Q13 - Ethnicity` LIKE '%Indian%';

UPDATE survey_edit
SET `Q13 - Ethnicity` = 'Other'
WHERE `Q13 - Ethnicity` LIKE 'Other%';

SELECT *
FROM survey_edit