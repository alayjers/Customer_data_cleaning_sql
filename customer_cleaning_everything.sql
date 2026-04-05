-- exploration

SELECT * FROM raw_customers LIMIT 0;

SELECT 
    "CustomerID",
    "Name",
    "Gender",
    "Age",
    "City",
    "Signup_Date",
    "Last_purchase_date",
    "purchase_amount",
    "feedback_score",
    "email",
    "Phone_number",
    "Country"
FROM raw_customers 
LIMIT 10;

SELECT COUNT(*) FROM raw_customers;

SELECT 
    COUNT(*) as total,
    COUNT("CustomerID") as has_id,
    COUNT("Name") as has_name,
    COUNT("Gender") as has_gender,
    COUNT("Age") as has_age,
    COUNT("City") as has_city,
    COUNT("Signup_Date") as has_signup,
    COUNT("Last_purchase_date") as has_last_purchase,
    COUNT("purchase_amount") as has_amount,
    COUNT("feedback_score") as has_feedback,
    COUNT("email") as has_email,
    COUNT("Phone_number") as has_phone,
    COUNT("Country") as has_country
FROM raw_customers;

SELECT "Age", COUNT(*) 
FROM raw_customers 
WHERE "Age" < 0 OR "Age" > 120
GROUP BY "Age";

SELECT "feedback_score", COUNT(*) 
FROM raw_customers 
WHERE "feedback_score" < 1 OR "feedback_score" > 10
GROUP BY "feedback_score";

SELECT "Gender", COUNT(*) 
FROM raw_customers 
GROUP BY "Gender";

SELECT "Country", COUNT(*) 
FROM raw_customers 
GROUP BY "Country";

SELECT "CustomerID", COUNT(*) 
FROM raw_customers 
GROUP BY "CustomerID" 
HAVING COUNT(*) > 1;

SELECT "email", COUNT(*) 
FROM raw_customers 
GROUP BY "email" 
HAVING COUNT(*) > 1;


-- cleaning

DROP TABLE IF EXISTS customers_cleaned;

CREATE TABLE customers_cleaned AS
SELECT 
    UPPER(TRIM("CustomerID")) as customer_id,
    
    INITCAP(TRIM(REGEXP_REPLACE("Name", '\s+', ' ', 'g'))) as customer_name,
    
    CASE 
        WHEN UPPER(TRIM("Gender")) IN ('M', 'MALE', 'MAN') THEN 'Male'
        WHEN UPPER(TRIM("Gender")) IN ('F', 'FEMALE', 'WOMAN') THEN 'Female'
        ELSE 'Other'
    END as gender,
    
    CASE 
        WHEN "Age" BETWEEN 18 AND 100 THEN "Age"
        ELSE NULL
    END as age,
    
    INITCAP(TRIM("City")) as city,
    
    CASE
        WHEN "Signup_Date" ~ '^\d{4}-\d{2}-\d{2}$' THEN "Signup_Date"::DATE
        WHEN "Signup_Date" ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE("Signup_Date", 'MM/DD/YYYY')
        WHEN "Signup_Date" ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE("Signup_Date", 'MM-DD-YYYY')
        ELSE NULL
    END as signup_date,
    
    CASE
        WHEN "Last_purchase_date" ~ '^\d{4}-\d{2}-\d{2}$' THEN "Last_purchase_date"::DATE
        WHEN "Last_purchase_date" ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE("Last_purchase_date", 'MM/DD/YYYY')
        WHEN "Last_purchase_date" ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE("Last_purchase_date", 'MM-DD-YYYY')
        ELSE NULL
    END as last_purchase_date,
    
    CASE 
        WHEN "purchase_amount" > 0 THEN "purchase_amount"
        ELSE NULL
    END as purchase_amount,
    
    CASE 
        WHEN "feedback_score" BETWEEN 1 AND 10 THEN "feedback_score"
        ELSE NULL
    END as feedback_score,
    
    LOWER(TRIM("email")) as email,
    
    REGEXP_REPLACE("Phone_number", '[^0-9]', '', 'g') as phone_number,
    
    INITCAP(TRIM("Country")) as country
    
FROM raw_customers
WHERE "CustomerID" IS NOT NULL;

DELETE FROM customers_cleaned a
USING customers_cleaned b
WHERE a.customer_id = b.customer_id 
  AND a.ctid > b.ctid;

DELETE FROM customers_cleaned a
USING customers_cleaned b
WHERE a.email = b.email 
  AND a.customer_id > b.customer_id;


-- Cleaning Verification
SELECT 
    (SELECT COUNT(*) FROM raw_customers) as raw_count,
    (SELECT COUNT(*) FROM customers_cleaned) as cleaned_count;


SELECT * FROM customers_cleaned LIMIT 10;


SELECT 
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END) as null_id,
    COUNT(CASE WHEN customer_name IS NULL THEN 1 END) as null_name,
    COUNT(CASE WHEN email IS NULL THEN 1 END) as null_email,
    COUNT(CASE WHEN age IS NULL THEN 1 END) as null_age,
    COUNT(CASE WHEN country IS NULL THEN 1 END) as null_country
FROM customers_cleaned;


SELECT gender, COUNT(*) FROM customers_cleaned GROUP BY gender;

-- Analytics
SELECT 
    country,
    COUNT(*) as customer_count,
    ROUND(AVG(purchase_amount), 2) as avg_spend
FROM customers_cleaned
WHERE country IS NOT NULL
GROUP BY country
ORDER BY customer_count DESC;

SELECT 
    CASE 
        WHEN age < 25 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END as age_group,
    COUNT(*) as customer_count,
    ROUND(AVG(purchase_amount), 2) as avg_spend
FROM customers_cleaned
WHERE age IS NOT NULL
GROUP BY age_group
ORDER BY age_group;


SELECT 
    city,
    country,
    COUNT(*) as customer_count
FROM customers_cleaned
WHERE city IS NOT NULL
GROUP BY city, country
ORDER BY customer_count DESC
LIMIT 10;

SELECT 
    DATE_TRUNC('month', signup_date) as month,
    COUNT(*) as new_customers
FROM customers_cleaned
WHERE signup_date IS NOT NULL
GROUP BY DATE_TRUNC('month', signup_date)
ORDER BY month DESC
LIMIT 12;

SELECT 
    feedback_score,
    COUNT(*) as customer_count
FROM customers_cleaned
WHERE feedback_score IS NOT NULL
GROUP BY feedback_score
ORDER BY feedback_score;


SELECT 
    customer_id,
    customer_name,
    SUM(purchase_amount) as total_spent,
    COUNT(*) as purchase_count
FROM customers_cleaned
WHERE purchase_amount IS NOT NULL
GROUP BY customer_id, customer_name
ORDER BY total_spent DESC
LIMIT 10;


SELECT 
    customer_id,
    customer_name,
    email,
    last_purchase_date
FROM customers_cleaned
WHERE last_purchase_date < CURRENT_DATE - INTERVAL '90 days'
ORDER BY last_purchase_date;

SELECT 
    CASE 
        WHEN age < 25 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END as age_group,
    gender,
    COUNT(*) as customer_count,
    ROUND(AVG(purchase_amount), 2) as avg_spend
FROM customers_cleaned
WHERE age IS NOT NULL AND gender IS NOT NULL AND purchase_amount IS NOT NULL
GROUP BY age_group, gender
ORDER BY age_group, gender;