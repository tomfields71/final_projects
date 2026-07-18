CREATE TABLE data_audience
(date DATE,
user_id VARCHAR(50),
view_adverts INT);

CREATE TABLE data_audience
(experiment_num INT,
experiment_group VARCHAR(50),
user_id INT,
revenue INT);

CREATE TABLE listers
(user_id INT,
date DATE,
cnt_adverts INT,
age INT,
cnt_contacts INT,
revenue INT);

SELECT * FROM data_audience;
SELECT * FROM data_AB_test;
SELECT * FROM listers;

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\listers.csv"
INTO TABLE listers
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# MAU продукта:
SELECT 
	DATE_FORMAT(date, '%Y-%m') AS month_,
	COUNT(DISTINCT user_id) AS MAU
FROM data_audience
WHERE date >= '2023-11-01' AND date <= '2023-11-30'
GROUP BY month_;

# DAU продукта:
SELECT
    date AS activity_date,
    COUNT(DISTINCT user_id) AS DAU
FROM data_audience
GROUP BY date
ORDER BY date;

SELECT AVG(daily_data.DAU) AS average_DAU
FROM (SELECT
		date,
		COUNT(DISTINCT user_id) AS DAU
	FROM data_audience
	GROUP BY date
) AS daily_data;

# Retention продукта:
SELECT
    ROUND(COUNT(user_id) * 100.0 / (
        SELECT COUNT(DISTINCT user_id) 
        FROM data_audience 
        WHERE date = '2023-11-01'), 2) AS day_1_retention_rate
FROM (
    SELECT user_id
    FROM data_audience
    WHERE date IN ('2023-11-01', '2023-11-02')
    GROUP BY user_id
    HAVING COUNT(DISTINCT date) = 2 
       AND MIN(date) = '2023-11-01'
) AS retained_users;

# Пользовательская конверсия:
SELECT
    ROUND(COUNT(DISTINCT c.user_id) * 100.0 / (
        SELECT COUNT(DISTINCT user_id) 
        FROM data_audience), 2) AS user_conversion
FROM data_audience c
WHERE c.view_adverts > 0;

# Среднее кол-во просмотренных объявлений:
SELECT 
    ROUND(SUM(view_adverts) / COUNT(DISTINCT user_id), 2) AS avg_views
FROM data_audience;

# ARPU:
SELECT
    experiment_num,
    experiment_group,
    ROUND(SUM(revenue) / COUNT(DISTINCT user_id), 2) AS arpu,
    
    ROUND(SUM(CASE WHEN revenue > 0 THEN revenue ELSE 0 END) / 
          COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END), 2) AS arppu,
          
    ROUND(COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END) * 100.0 / 
          COUNT(DISTINCT user_id), 2) AS paying_users_percent
FROM data_AB_test
GROUP BY experiment_num, experiment_group
ORDER BY experiment_num, experiment_group;