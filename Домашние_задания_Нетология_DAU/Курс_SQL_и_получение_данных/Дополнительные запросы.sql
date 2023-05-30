--1. Сколько оплатил каждый пользователь за прокат фильмов за каждый месяц
SELECT c.customer_id,
	   concat(c.last_name, ' ', c.first_name) AS customer_name, 
	   CAST(date_trunc('month', p.payment_date) AS date) AS year_month, 
	   sum(p.amount) AS total
FROM payment p 
JOIN customer c USING(customer_id)
GROUP BY 1,3
ORDER BY 1

-- 2. На какую сумму продал каждый сотрудник магазина
SELECT s.store_id,
	   concat(s2.last_name, ' ', s2.first_name) AS staff_name,
	   sum(p.amount) AS total	   
FROM payment p 
JOIN customer c USING(customer_id)
JOIN store s USING(store_id)
JOIN staff s2 USING(staff_id)
GROUP BY 1, 2
ORDER BY 1

--3. Сколько каждый пользователь взял фильмов в аренду
SELECT concat(c.last_name, ' ', c.first_name) AS customer_name,
       count(i.film_id) AS cnt_films
FROM rental r 
JOIN inventory i USING(inventory_id)
JOIN customer c USING(customer_id)
GROUP BY c.customer_id 
ORDER BY 1

--4. Сколько раз брали в прокат фильмы, в которых снимались актрисы с именем Julia
SELECT count(r.rental_id)
FROM rental r 
JOIN inventory i USING(inventory_id)
JOIN film f USING(film_id)
JOIN film_actor fa USING(film_id)
JOIN actor a USING(actor_id)
WHERE a.first_name ILIKE 'Julia'

-- 5. Сколько актеров снимались в фильмах, в названии которых встречается подстрока bed
SELECT count(fa.actor_id) 
FROM film f 
JOIN film_actor fa USING(film_id)
WHERE f.title ILIKE '%bed%'

--6. Вывести пользователей, у которых указано два адреса
SELECT c.last_name || ' ' || c.first_name AS customer_name
FROM customer c 
JOIN address a USING(address_id)
WHERE a.address IS NOT NULL 
AND a.address2 IS NOT NULL 

--7. Сформировать массив из категорий фильмов и для каждого фильма вывести индекс массива соответствующей категории
SELECT f.title,
       array_position((SELECT array_agg("name") FROM category), c."name" ) AS index_arr_cat
FROM film f
JOIN film_category fc USING(film_id)
JOIN category c USING(category_id)


--8. Вывести массив с идентификаторами пользователей в фамилиях которых есть подстрока 'ah'
SELECT array_agg(customer_id)
FROM customer c 
WHERE last_name ILIKE '%ah%'

-- 9. Вывести фильмы, у которых в названии третья буква 'b'
SELECT title
FROM film f 
WHERE title ILIKE '__b%'

--10. Найти последнюю запись по пользователю в таблице аренда без учета last_update 
SELECT * 
FROM rental r2 
WHERE rental_id IN 
(SELECT LAST_VALUE (rental_id) OVER (PARTITION BY customer_id ORDER BY rental_date RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM rental r 
ORDER BY customer_id, rental_date) 
ORDER BY customer_id 

--11. Вывести ФИО пользователя и название третьего фильма, который он брал в аренду.
WITH rn AS
(SELECT c.last_name || ' ' || c.first_name AS customer_name,
       r.rental_date,
       f.title AS film_title,
       ROW_NUMBER () OVER (PARTITION BY r.customer_id ORDER BY r.rental_date) AS rn
FROM rental r 
JOIN customer c USING(customer_id)
JOIN inventory i USING (inventory_id)
JOIN film f USING(film_id))
SELECT customer_name, 
	   film_title
FROM rn 
WHERE rn = 3
ORDER BY 1 

--12. Вывести пользователей, которые брали один и тот же фильм больше одного раза.
SELECT DISTINCT customer_name
FROM (SELECT c.last_name || ' ' || c.first_name AS customer_name,
	   i.film_id,
	   count(r.rental_id) OVER (PARTITION BY r.customer_id, i.film_id) AS cnt_ren
	  FROM rental r 
	  JOIN inventory i USING(inventory_id)
      JOIN customer c USING(customer_id)) AS cnt_films
WHERE cnt_ren > 1
ORDER BY 1

--13. Какой из месяцев оказался наиболее доходным?
WITH 
sales_per_month AS
(SELECT date_trunc('month', p.payment_date)::date AS month_number,	   
	    sum(amount) AS total_amt
FROM payment p 
GROUP BY 1),
max_sales AS 
(SELECT max(total_amt) AS max_sales
FROM sales_per_month) 
SELECT spm.month_number,
       spm.total_amt
FROM sales_per_month AS spm
JOIN max_sales AS ms ON spm.total_amt=ms.max_sales


--14. Одним запросом ответить на два вопроса: в какой из месяцев взяли в аренду фильмов больше всего? На сколько по отношению к предыдущему месяцу было сдано в аренду больше/меньше фильмов.
WITH 
cnt_diff_month AS
(SELECT date_trunc('month', r.rental_date)::date AS month_number,	
	   count(i.film_id) AS cnt_films,
	   count(i.film_id) - (lag(count(i.film_id), 1) OVER (ORDER BY date_trunc('month', r.rental_date))) AS diff_cur_prev_month
FROM rental r 
JOIN inventory i USING(inventory_id)
GROUP BY date_trunc('month', r.rental_date)
ORDER BY date_trunc('month', r.rental_date))
SELECT *
FROM cnt_diff_month
WHERE cnt_films = (SELECT max(cnt_films) 
					FROM cnt_diff_month)

--15. Определите первые две категории фильмов по каждому пользователю, которые они чаще всего берут в аренду.
WITH max_film_cat AS
(SELECT c2.last_name || ' ' || c2.first_name AS customer_name,
	   c."name" AS cat_name,
	   count(i.film_id) AS cnt_films
FROM rental r 
JOIN customer c2 USING(customer_id)
JOIN inventory i USING(inventory_id)
JOIN film f USING(film_id)
JOIN film_category fc USING(film_id)
JOIN category c USING(category_id)
GROUP BY 1,2
ORDER BY 1, 3 DESC),
count_rank AS
(SELECT *,
      ROW_NUMBER () OVER (PARTITION BY customer_name ORDER BY cnt_films DESC) AS rn
FROM max_film_cat)
SELECT customer_name,
       array_agg(cat_name) AS cat
FROM count_rank
WHERE rn IN (1,2)
GROUP BY 1

--1. Рассчитайте совокупный доход всех магазинов на каждую дату.
SELECT r.rental_date :: date AS "date",
sum(p.amount) AS total_amt
FROM payment p 
JOIN rental r USING(rental_id)
JOIN inventory i USING(inventory_id)
GROUP BY 1
ORDER BY 1

--2. Выведите наиболее и наименее востребованные жанры
--(те, которые арендовали наибольшее/наименьшее количество раз),
--число их общих продаж и сумму дохода
WITH 
sales_per_cat AS
(SELECT c."name" AS cat_name, 
	   count(r.rental_id) AS qty_saler_per_cat,
	   sum(p.amount) AS total_sales_per_cat
FROM payment p 
JOIN rental r USING(rental_id)
JOIN inventory i USING(inventory_id)
JOIN film f USING(film_id)
JOIN film_category fc USING(film_id)
JOIN category c USING(category_id)
GROUP BY 1)
SELECT *
FROM sales_per_cat
WHERE qty_saler_per_cat = (SELECT max(qty_saler_per_cat) FROM sales_per_cat)
OR qty_saler_per_cat = (SELECT min(qty_saler_per_cat) FROM sales_per_cat)

-- 3. Какова средняя арендная ставка для каждого жанра?
-- (упорядочить по убыванию, среднее значение округлить до сотых)
SELECT c."name" AS cat_name, 
	   round(avg(f.rental_rate), 2) AS rnd_rental_rate
FROM film f 
JOIN film_category fc USING(film_id)
JOIN category c USING(category_id)
GROUP BY 1
ORDER BY 2 DESC 

--4. Cоставить список из 5 самых дорогих клиентов (арендовавших фильмы с 10 по 13 июня)
--формат списка:
--'Имя_клиента Фамилия_клиента email address is: e-mail_клиента'

SELECT first_name || ' ' || last_name || ' ' || 'email address is:' || ' ' || email AS list_of_cinephiles
FROM 
		(SELECT c.last_name,
		       c.first_name,
		       c.email, 
		       sum(p.amount)
		FROM customer c 
		JOIN rental r USING(customer_id)
		JOIN payment p USING(customer_id)
		WHERE r.rental_date :: date BETWEEN '2005-06-10' AND '2005-06-13'
		GROUP BY 1,2,3
		ORDER BY 4 DESC
		LIMIT 5) AS t1

--5. Сколько арендованных фильмов было возвращено в срок, до срока возврата и после, выведите максимальную разницу со сроком?
WITH 
ret_in_time AS 
(SELECT count(f.film_id) 
FROM rental r 
JOIN inventory i USING(inventory_id)
JOIN film f USING(film_id)
WHERE r.rental_date :: date + f.rental_duration = r.return_date :: date),
ret_before_time AS 
(SELECT count(f.film_id) 
FROM rental r 
JOIN inventory i USING(inventory_id)
JOIN film f USING(film_id)
WHERE r.rental_date :: date + f.rental_duration < r.return_date :: date),
ret_with_delay AS 
(SELECT f.film_id, 
	   count(f.film_id) OVER () qty_ret_with_delay,
       r.rental_date :: date + f.rental_duration - r.return_date :: date AS qty_dеlay_days       
FROM rental r 
JOIN inventory i USING(inventory_id)
JOIN film f USING(film_id)
WHERE r.rental_date :: date + f.rental_duration > r.return_date :: date)
SELECT DISTINCT (SELECT * FROM ret_in_time ) AS qty_ret_in_time,
	   (SELECT * FROM ret_before_time) AS qty_ret_before_time,
		qty_ret_with_delay,
        (SELECT max(qty_dеlay_days)  FROM  ret_with_delay) AS max_delay_days    
FROM ret_with_delay
