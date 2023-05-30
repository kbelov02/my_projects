--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим 
--так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

SELECT customer_id,
       payment_id,
       payment_date,
       amount, 
       ROW_NUMBER () OVER (ORDER BY payment_date) AS rn, 
       ROW_NUMBER () OVER (PARTITION BY customer_id ORDER BY payment_date) AS cust_pay_date,
       SUM(amount) OVER (PARTITION BY customer_id ORDER BY payment_date, amount) AS cust_sum, 
       DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY amount DESC) AS cust_pay_amt
FROM payment p 
ORDER BY 1, 3


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.

SELECT customer_id,
       payment_id,
       payment_date,
       amount, 
       LAG(amount,1,'0.0') OVER (PARTITION BY customer_id ORDER BY payment_date) AS prv_amt
FROM payment p 



--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

SELECT customer_id,
       payment_id,
       payment_date,
       amount, 
       amount - (LEAD(amount) OVER (PARTITION BY customer_id ORDER BY payment_date)) AS diff
FROM payment p 



--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

-- Вариант №1 
SELECT t1.customer_id,
       t1.payment_id,
       t1.payment_date,
       t1.amount
FROM (SELECT customer_id,
       		 payment_id,
       		 payment_date,
       		 amount,
       ROW_NUMBER () OVER (PARTITION BY customer_id ORDER BY payment_date DESC) AS rn 
	  FROM payment p) AS t1
WHERE rn = 1 

-- Вариант №2 с возможностью выбора всех платежей, дата и время которых является последней, а так же с проверкой, что этот платеж не нулевой
SELECT t1.customer_id,
       t1.payment_id,
       t1.payment_date,
       t1.amount
FROM (SELECT customer_id,
       		 payment_id,
       		 payment_date,
       		 amount,
       DENSE_RANK  () OVER (PARTITION BY customer_id ORDER BY payment_date DESC) AS rn 
	  FROM payment p) AS t1
WHERE rn = 1 
AND amount <> 0 



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.

SELECT DISTINCT staff_id,
       CAST(DATE_TRUNC('day', payment_date) AS date), 
       SUM(amount) OVER (PARTITION BY staff_id, payment_date :: date),  
       SUM(amount) OVER (PARTITION BY staff_id ORDER BY payment_date :: date)
FROM payment p 
WHERE payment_date :: date BETWEEN '2005-08-01' AND '2005-08-31'


--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

WITH t1 AS 
(SELECT customer_id,
       payment_date,
       ROW_NUMBER () OVER (ORDER by payment_date) AS payment_number
FROM payment p 
WHERE payment_date :: date = '2005-08-20')
SELECT t1.customer_id,
       t1.payment_date,
       t1.payment_number
FROM t1
WHERE MOD(t1.payment_number, 100) = 0 


--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

WITH 
t_agr AS
				(SELECT r.customer_id,
				       COUNT(i.film_id) AS cnt_films, 
				       SUM(p.amount) AS sum_amt,
				       max(r.rental_date) AS last_date
				FROM rental r 
				JOIN payment p USING(rental_id) 
				JOIN inventory i USING(inventory_id)   
				GROUP BY 1
				),
t_rank AS
				(SELECT c3.country, 
				       concat(c.first_name, ' ', c.last_name) AS cst_name,
				       ROW_NUMBER () OVER (PARTITION BY c3.country ORDER BY t_agr.cnt_films DESC) AS rn_cnt_films,
				       ROW_NUMBER () OVER (PARTITION BY c3.country ORDER BY t_agr.sum_amt DESC) AS rn_sum_amt,
				       ROW_NUMBER () OVER (PARTITION BY c3.country ORDER BY t_agr.last_date DESC) AS rn_last_date
				FROM t_agr
				JOIN customer c USING(customer_id) 
				JOIN address a USING(address_id) 
				JOIN city c2 USING(city_id) 
				JOIN country c3 USING(country_id)
				)
SELECT country AS "Страна",
       t1.cst_name AS "Покупатель, арендовавший наибольшее количество фильмов",
       t2.cst_name AS "Покупатель, арендовавший фильмов на самую большую сумму",
       t3.cst_name AS "Покупатель, который последним арендовал фильм"
FROM t_rank t1
JOIN t_rank t2 USING (country)
JOIN t_rank t3 USING (country)
WHERE t1.rn_cnt_films = 1
AND t2.rn_sum_amt = 1
AND t3.rn_last_date = 1
       


       


