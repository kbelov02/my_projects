--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".
EXPLAIN ANALYZE
SELECT film_id,
       title,
       special_features
FROM film
WHERE special_features && ARRAY['Behind the Scenes']

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

-- Вариант №1
SELECT film_id,
       title,
       special_features
FROM film
WHERE special_features @> ARRAY['Behind the Scenes']

-- Вариант №2
SELECT film_id,
       title,
       special_features
FROM film
WHERE array_position(special_features, 'Behind the Scenes') IS NOT NULL 

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.
WITH t1 AS
(
		SELECT film_id,
       		   title,
       		   special_features
		FROM film
		WHERE special_features && ARRAY['Behind the Scenes']
)
SELECT r.customer_id,
       count(t1.film_id) AS "Количество фмльмов"
FROM rental r 
JOIN inventory i USING(inventory_id)
JOIN t1 USING(film_id)
GROUP BY 1
ORDER BY 1


--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

SELECT r.customer_id,
       count(t1.film_id) AS "Количество фмльмов"
FROM (SELECT film_id,
       		   title,
       		   special_features
		FROM film
		WHERE special_features && ARRAY['Behind the Scenes']) AS t1
JOIN inventory i USING(film_id)
JOIN rental r USING(inventory_id)
GROUP BY 1
ORDER BY 1

--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

CREATE MATERIALIZED VIEW films_behind_the_scenes AS 
(SELECT r.customer_id,
       count(t1.film_id) AS "Количество фмльмов"
FROM (SELECT film_id,
       		   title,
       		   special_features
		FROM film
		WHERE special_features && ARRAY['Behind the Scenes']) AS t1
JOIN inventory i USING(film_id)
JOIN rental r USING(inventory_id)
GROUP BY 1
ORDER BY 1)
WITH NO DATA 

REFRESH MATERIALIZED VIEW films_behind_the_scenes 

--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания, 
--   поиск значения в массиве происходит быстрее
--2. какой вариант вычислений работает быстрее: 
--   с использованием CTE или с использованием подзапроса

-- 1. Проанализируем 3 зароса из заданий 1 и 2:
EXPLAIN ANALYZE -- 67,50 0,351ms
SELECT film_id,
       title,
       special_features
FROM film
WHERE special_features && ARRAY['Behind the Scenes']

EXPLAIN ANALYZE -- 67,50 0,334ms
SELECT film_id,
       title,
       special_features
FROM film
WHERE special_features @> ARRAY['Behind the Scenes']

EXPLAIN ANALYZE -- 67,50 0,332ms
SELECT film_id,
       title,
       special_features
FROM film
WHERE array_position(special_features, 'Behind the Scenes') IS NOT NULL

-- Стоимость всех трех запросов одинакова, но запрос с функцией "array_position" выболняется немного быстрее, чем запросы 
-- с операторами
----------------------------------------------------

-- 2. Проанализируем запросы из заданий 3 и 4:
EXPLAIN ANALYZE -- 675,47 7,475ms
WITH t1 AS
(
		SELECT film_id,
       		   title,
       		   special_features
		FROM film
		WHERE special_features && ARRAY['Behind the Scenes']
)
SELECT r.customer_id,
       count(t1.film_id) AS "Количество фмльмов"
FROM rental r 
JOIN inventory i USING(inventory_id)
JOIN t1 USING(film_id)
GROUP BY 1
ORDER BY 1

EXPLAIN ANALYZE -- 675,47 7,321ms
SELECT r.customer_id,
       count(t1.film_id) AS "Количество фмльмов"
FROM (SELECT film_id,
       		   title,
       		   special_features
		FROM film
		WHERE special_features && ARRAY['Behind the Scenes']) AS t1
JOIN inventory i USING(film_id)
JOIN rental r USING(inventory_id)
GROUP BY 1
ORDER BY 1

-- Стоимость запросов одинакова, но запрос, который включает в себя подзапрос в поле FROM выполнился быстрее, 
-- чем запрос, где использовалась временное табличное выражение

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.

SELECT staff_name,
       title,
       payment_date,
       amount,
       customer_name
FROM (
SELECT s.last_name || ' ' || s.first_name AS staff_name,
       f.title,
       p.payment_date, 
       p.amount,
       c.last_name || ' ' || c.first_name AS customer_name,
       ROW_NUMBER () OVER (PARTITION BY s.staff_id ORDER BY p.payment_date) AS rn
FROM rental r 
JOIN payment p USING(rental_id)
JOIN customer c ON p.customer_id = c.customer_id 
JOIN staff s ON p.staff_id = s.staff_id
JOIN inventory i USING(inventory_id)
JOIN film f USING(film_id)
) AS t1
WHERE rn = 1 


--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день
 
WITH cnt_film AS 
(
SELECT i.store_id,
       r.rental_date :: date AS "date",
       count(i.film_id) AS cnt_film
FROM rental r 
JOIN inventory i using(inventory_id)
GROUP BY 1,2
ORDER BY 3 DESC 
),
max_cnt_film AS 
(
SELECT store_id,
       max(cnt_film) AS max_cnt_film
FROM cnt_film
GROUP BY 1
),
total_amt AS 
(
SELECT s.store_id,
       p.payment_date :: date AS "date",
       SUM(p.amount) AS total_amt
FROM payment p
JOIN staff s using(staff_id)
GROUP BY 1,2
ORDER BY 3 
),
min_total_amt AS 
(
SELECT store_id,
       min(total_amt) AS min_total_amt
FROM total_amt
GROUP BY 1
),
store_max_cnt_film AS 
(
SELECT cnt_film.store_id,
       cnt_film.date,
       cnt_film.cnt_film
FROM cnt_film, max_cnt_film
WHERE cnt_film.cnt_film = max_cnt_film.max_cnt_film
),
store_min_total_amt AS 
(
SELECT total_amt.store_id,
       total_amt.date,
       total_amt.total_amt
FROM total_amt, min_total_amt
WHERE total_amt.total_amt = min_total_amt.min_total_amt
)
SELECT store_max_cnt_film.store_id AS "ID магазина",
       store_max_cnt_film.date AS "День, в который арендовали больше всего фильмов",
       store_max_cnt_film.cnt_film AS "Количество фильмов",
       store_min_total_amt.date AS "День, в который продали меньше всего фильмов",
       store_min_total_amt.total_amt AS "Сумма продажи"
FROM store_max_cnt_film
JOIN store_min_total_amt USING(store_id)




