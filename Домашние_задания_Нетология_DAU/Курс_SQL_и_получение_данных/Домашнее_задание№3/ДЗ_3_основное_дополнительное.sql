--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

select concat(cst.last_name, ' ', cst.first_name) as "Customer name",
       a.address as "Address",
       c.city as "City",
       cntr.country as "Country"
from customer as cst
join address as a using(address_id)
join city as c using(city_id)
join country as cntr using(country_id)

--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select store_id as "ID магазина",
       count(customer_id) as "Количество покупателей"
from customer c 
group by 1


--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select store_id as "ID магазина",
       count(customer_id) as "Количество покупателей"
from customer c 
group by 1
having count(customer_id) > 300


-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

select c.store_id AS "ID магазина",
       count(c.customer_id) as "Количество покупателей",
       cit.city as "Город",
       concat(st.last_name, ' ', st.first_name) as "Имя сотрудника"
from customer c 
join store s on c.store_id =s.store_id 
join staff st on s.manager_staff_id =st.staff_id 
join address a on s.address_id =a.address_id 
join city cit using(city_id)
group by 1,3,4
having count(c.customer_id) > 300

--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя",
       count(r.rental_id) as "Количество фильмов"
from customer c 
join rental r using(customer_id)
group by 1
order by 2 desc 
limit 5


--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя",
       count(r.rental_id) as "Количество фильмов",
       round(sum(p.amount)) as "Общая стоимость платежей",
       min(p.amount) as "Минимальная стоимость платежа",
       max(p.amount) as "Максимальная стоимость платежа"
from  customer c 
join rental r using(customer_id)
join payment p using(rental_id)
group by 1



--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.
 
select t1.city as "Город 1", 
       t2.city as "Город 2"
from city as t1
cross join city as t2
where t1.city <> t2.city

--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date), 
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.
 
select customer_id as "ID покупателя",
       round(avg(date_part('day', DATE_TRUNC('day',return_date) - DATE_TRUNC('day', rental_date))) :: numeric, 2) as "Среднее количество дней на возврат"
from rental r 
group by 1
order by 1

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

select f.title as "Название фильма",
        f.rating as "Рейтинг",
        c.name as "Жанр",
        f.release_year as "Год выпуска",
        l.name as "Язык",
       count(r.rental_id) as "Количество аренд",
       sum(p.amount) as "Общая стоимость аренды"
from rental r 
join payment p using(rental_id)
join inventory i using(inventory_id)
join film f using(film_id)
join film_category fc using(film_id)
join category c using(category_id)
join "language" l using(language_id)
group by f.film_id, f.title, f.rating, c."name", f.release_year, l."name" 
order by 1 
 

--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.

select f.title as "Название фильма",
        f.rating as "Рейтинг",
        c.name as "Жанр",
        f.release_year as "Год выпуска",
        l.name as "Язык",
       count(r.rental_id) as "Количество аренд",
       sum(p.amount) as "Общая стоимость аренды"
from rental r 
join payment p using(rental_id)
join inventory i using(inventory_id)
right join film f using(film_id)
join film_category fc using(film_id)
join category c using(category_id)
join "language" l using(language_id)
group by f.film_id, f.title, f.rating, c."name", f.release_year, l."name" 
having count(r.rental_id) = 0
order by 6 

--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select staff_id,
       count(payment_id) as "Количество продаж",
       case 
       	    when count(payment_id) > 7300 then 'Да'
       	    else 'Нет'
       end   as "Премия"
from payment p  
group by 1





