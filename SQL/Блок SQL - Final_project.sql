CREATE DATABASE customers_transactions;

SET SQL_SAFE_UPDATES = 0;
UPDATE customers SET Gender = NULL WHERE Gender = '';
UPDATE customers SET Age = NULL WHERE Age = '';
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE Customers MODIFY Age INT NULL;

SELECT * FROM customers;

CREATE TABLE transactions
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL(10, 3),
Sum_payment DECIMAL(10, 2));

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS_final.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'secure_file_priv';

SELECT * FROM transactions;

#1 задание:
#Список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период,
#средний чек за период с 01.06.2015 по 01.06.2016, 
#средняя сумма покупок за месяц, 
#количество всех операций по клиенту за период,
#информацию в разрезе месяцев:

SELECT 
    c.Id_client,
    c.Gender,
    c.Age,
    MONTH(t.date_new) AS month_number,
    SUM(t.Sum_payment) AS monthly_spent,
    ROUND(SUM(t.Sum_payment) / COUNT(DISTINCT t.id_check), 2) AS average_check,
    COUNT(DISTINCT t.id_check) AS monthly_transactions
FROM transactions t
JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01' AND t.ID_client IN (
	SELECT ID_client 
	FROM transactions 
	WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
	GROUP BY ID_client 
	HAVING COUNT(DISTINCT MONTH(date_new)) = 12
  )
GROUP BY c.Id_client, c.Gender, c.Age, MONTH(t.date_new)
ORDER BY c.Id_client, month_number;

#пропишем код, чтобы видеть общую информацию по покупкам клиентов за все 12 месяцев:
SELECT 
    c.Id_client,
    c.Gender,
    c.Age,
    SUM(t.Sum_payment) AS total_spent,
    ROUND(SUM(t.Sum_payment) / COUNT(DISTINCT t.id_check), 2) AS average_check,
    ROUND(SUM(t.Sum_payment) / 12, 2) AS avg_monthly_spent,
    COUNT(DISTINCT t.id_check) AS total_transactions
FROM transactions t
JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY c.Id_client, c.Gender, c.Age
HAVING COUNT(DISTINCT MONTH(t.date_new)) = 12;

#2 задание:
#средняя сумма чека в месяц;
#среднее количество операций в месяц;
#среднее количество клиентов, которые совершали операции;
#долю от общего количества операций за год и долю в месяц от общей суммы операций;

SELECT 
    YEAR(t.date_new) AS tx_year,
    MONTH(t.date_new) AS tx_month,
    ROUND(SUM(t.Sum_payment) / COUNT(DISTINCT t.id_check), 2) AS avg_check_month,
    COUNT(DISTINCT t.id_check) AS total_transactions_month,
    COUNT(DISTINCT t.ID_client) AS active_clients_month,
    ROUND((COUNT(DISTINCT t.id_check) / (SELECT COUNT(DISTINCT id_check) FROM transactions)) * 100, 2) AS per_of_total_transactions,
    ROUND((SUM(t.Sum_payment) / (SELECT SUM(Sum_payment) FROM transactions)) * 100, 2) AS per_of_total_sum
FROM transactions t
GROUP BY YEAR(t.date_new), MONTH(t.date_new)
ORDER BY tx_year, tx_month;

#% соотношение M/F/NA (M/F/NA) в каждом месяце с их долей затрат;

WITH gender_stats AS (
	SELECT 
		YEAR(t.date_new) AS tx_year,
        MONTH(t.date_new) AS tx_month,
        COALESCE(c.Gender, 'NA') AS gender,
        COUNT(DISTINCT t.ID_client) AS gender_clients,
        SUM(t.Sum_payment) AS gender_spent
    FROM transactions t
    LEFT JOIN customers c ON t.ID_client = c.Id_client
    GROUP BY YEAR(t.date_new), MONTH(t.date_new), COALESCE(c.Gender, 'NA')),
monthly_totals AS (
    SELECT 
        YEAR(date_new) AS tx_year,
        MONTH(date_new) AS tx_month,
        COUNT(DISTINCT ID_client) AS total_clients,
        SUM(Sum_payment) AS total_spent
    FROM transactions
    GROUP BY YEAR(date_new), MONTH(date_new))
SELECT 
    g.tx_year,
    g.tx_month,
    g.gender,
    g.gender_clients,
    ROUND((g.gender_clients / m.total_clients) * 100, 2) AS gender_client_per,
    ROUND(g.gender_spent, 2) AS gender_spent,
    ROUND((g.gender_spent / m.total_spent) * 100, 2) AS gender_spent_per
FROM gender_stats g
JOIN monthly_totals m ON g.tx_year = m.tx_year AND g.tx_month = m.tx_month
ORDER BY g.tx_year, g.tx_month, g.gender;

#3 задание:
#возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
#с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

WITH client_age_groups AS (
    SELECT 
        t.id_check,
        t.Sum_payment,
        YEAR(t.date_new) AS tx_year,
        QUARTER(t.date_new) AS tx_quarter,
        CASE WHEN c.Age IS NULL THEN 'NA'
			ELSE CONCAT(FLOOR(c.Age / 10) * 10, '-', (FLOOR(c.Age / 10) * 10) + 9)
        END AS age_group
    FROM transactions t
    LEFT JOIN customers c ON t.ID_client = c.Id_client),
quarterly_totals AS (
    SELECT 
        YEAR(date_new) AS tx_year,
        QUARTER(date_new) AS tx_quarter,
        SUM(Sum_payment) AS total_quarter_spent,
        COUNT(DISTINCT id_check) AS total_quarter_transactions
    FROM transactions
    GROUP BY YEAR(date_new), QUARTER(date_new)),
all_time_totals AS (
    SELECT 
        SUM(Sum_payment) AS total_spent,
        COUNT(DISTINCT id_check) AS total_transactions
    FROM transactions)
SELECT 
    ag.tx_year,
    ag.tx_quarter,
    ag.age_group,
    SUM(ag.Sum_payment) AS quarterly_spent,
    COUNT(DISTINCT ag.id_check) AS quarterly_transactions,
    ROUND(SUM(ag.Sum_payment) / COUNT(DISTINCT ag.id_check), 2) AS avg_check_quarter,
    ROUND((SUM(ag.Sum_payment) / qt.total_quarter_spent) * 100, 2) AS per_of_quarter_spent,
    ROUND((SUM(ag.Sum_payment) / att.total_spent) * 100, 2) AS per_of_all_time_spent
FROM client_age_groups ag
JOIN quarterly_totals qt ON ag.tx_year = qt.tx_year AND ag.tx_quarter = qt.tx_quarter
CROSS JOIN all_time_totals att
GROUP BY ag.tx_year, ag.tx_quarter, ag.age_group, qt.total_quarter_spent, att.total_spent
ORDER BY ag.tx_year, ag.tx_quarter, ag.age_group;