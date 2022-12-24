-- 1. В каких городах больше одного аэропорта?
SELECT city AS "Город",
       count(airport_code) AS "Количество аэропортов"
FROM airports a 
GROUP BY 1
HAVING count(airport_code) > 1
ORDER BY 1; 

						--Логика выполнения
-- 1) В таблице airports считаем количество аэропортов (поле airport_code) c руппировкой по названию города
-- 2) В результурующей таблице отбираем с помощью оператора having те говора, где количест во аэропортов больше 1.

-- 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
SELECT DISTINCT a3.airport_name AS "Название аэропорта", 
				a3.city AS "Город", 
				max_range_plane.model AS "Модель самолета", 
				max_range_plane.range AS "Максимаоьная дальность полета"  
FROM airports a3 
JOIN flights f ON a3.airport_code = f.departure_airport 
JOIN 
	(SELECT * 
	FROM aircrafts a2 
				WHERE "range" = (SELECT max(a."range") 
				FROM aircrafts a )) AS max_range_plane ON f.aircraft_code = max_range_plane.aircraft_code
ORDER BY 1,2;

						--Логика выполнения
-- 1) В таблице aicrafts находим значение максимальной дальности полета
-- 2) В этой же таблице находим модели самолетов, значения дальности перелета соотвествует максимальной. Для этого условие нахождения максимума из предыдущего пунка упаковываем в подзапрос в поле Where
-- 3) Соединяем таблицу из п.2 с таблицей flights, для определения рейсов, которые выполнялись самолетами с максимальной дальностью полета
-- 4) К таблице airports присоединяем таблицу из п.3 и выводим необходимые данные, отсортировав по названию аэропорта и городу 

-- 3. Вывести 10 рейсов с максимальным временем задержки вылета
SELECT flight_no AS "Номер рейса",
       actual_departure - scheduled_departure AS "Время задержки"
FROM flights
WHERE actual_departure IS NOT NULL
ORDER BY 2 DESC 
LIMIT 10;

						--Логика выполнения
-- 1) В таблице flights отбираем те рейсы, которые вылетели
-- 2) Считаем время задержки как разность между запланированным и фактическим вылетом
-- 3) Получившейся результат сортируем по убыванию и выводим первые 10 записей

-- 4. Были ли брони, по которым не были получены посадочные талоны?
SELECT CASE 
	        WHEN count(*) > 0 then 'Да'
	        ELSE 'Нет'
			END AS "Были ли брони без постадочных талонов?"
FROM bookings b 
JOIN tickets t USING(book_ref)
LEFT JOIN boarding_passes bp USING(ticket_no)
WHERE boarding_no IS NULL; 

						--Логика выполнения
-- 1) Соединяем таблицу bookings через таблицу tickets с таблицей boarding_passes (ее соединяем с помощью Left Join, чтобы сохранить все множество бронирований)
-- 2) Отбираем только те записи, где нет информации о номере посадочного талона
-- 3) Прописываем условие: если количество строк в результирующей таблице больше 0, значит брони без посадочных талонов были. В противном случае - не были. 
-- 4) Финальный вывод - результат работы условия

-- 5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете. 
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или 
-- более ранних рейсах в течении дня
WITH max_cnt_seats AS 
(
SELECT a.aircraft_code,
       count(s.seat_no) AS max_cnt
FROM aircrafts a 
JOIN seats s USING(aircraft_code)
GROUP BY 1
),
boarded_cnt AS 
(
SELECT f.departure_airport,
       f.flight_id,
       f.actual_departure,
       count(b.boarding_no) AS boarded_cnt,
       max_cnt_seats.max_cnt,
       max_cnt_seats.max_cnt - count(b.boarding_no) AS qty_free_seats,
       round((max_cnt_seats.max_cnt :: numeric - count(b.boarding_no))/max_cnt_seats.max_cnt*100, 2) AS perc_free_seats
FROM flights f 
JOIN boarding_passes b USING(flight_id)
JOIN max_cnt_seats USING(aircraft_code)
GROUP BY 2,5
)
SELECT departure_airport AS "Аэропорт",
       flight_id AS "ID_рейса",
       actual_departure AS "Факт_дата_вылета",
       boarded_cnt AS "К-во_пассажиров",
       max_cnt AS "К-во_мест_в_самолете",
       qty_free_seats AS "К-во_своб_мест",
       perc_free_seats AS "%_своб_мест",
       sum(boarded_cnt) OVER (PARTITION BY departure_airport, actual_departure :: date ORDER BY actual_departure) AS "К-во_улетевших_из_аэропорта"
FROM boarded_cnt;

						--Логика выполнения
-- 1. Для каждой модели самолета находим количество мест. Для этого соединяем таблицу aircrafts с таблицей seats
-- 2. Соединяем таблицу flights с таблицей boarding_passes и таблицей из п1., считаем количество пассажиров, которые 
-- получили посадочный таллон и количество свободных мест (от количества мест в самолете отнимает количество посадочных 
-- талонов на этот рейс) и считаем % заполняемости самолета
-- 3. В результирующей таблице выводим все требуемые поля и считаем сумму улетевших с накоплением

-- 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества
SELECT a.model AS "Модель самолета",
      count(flight_id) AS "Количество выполненных рейсов",
      (SELECT count(*)
      FROM flights f2) AS "Общее количество рейсов",
      round(count(flight_id)::numeric/(SELECT count(*)
      FROM flights f2)*100,2) AS "Процентное соотношение"
FROM flights f 
JOIN aircrafts a USING(aircraft_code)
GROUP BY 1;

						--Логика выполнения
-- 1. Считем общее количесвто рейсов.
-- Используем это запрос в качестве подзапроса при выводе в результирующей таблице
-- 2. Соединяем таблицу flights с таблицей aircrafts и считаем количество рейсов для каждого самолета.
-- 3. Считаем % соотношение используя подзапрос из п.1. 


-- 7. Были ли города, в которые можно добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
WITH min_bus AS 
(SELECT tf.flight_id,
       tf.fare_conditions,
       fv.departure_city,
       fv.arrival_city,
       min(tf.amount) AS min_bus_amt
FROM ticket_flights tf
JOIN flights_v fv USING(flight_id)
WHERE tf.fare_conditions = 'Business'
GROUP BY 1,2,3,4
ORDER BY 1),
max_eco AS
(SELECT tf.flight_id,
       tf.fare_conditions,
       fv.departure_city,
       fv.arrival_city,
       max(tf.amount) AS max_eco_amt
FROM ticket_flights tf 
JOIN flights_v fv USING(flight_id)
WHERE tf.fare_conditions = 'Economy'
GROUP BY 1,2,3,4
ORDER BY 1),
t1 AS
(SELECT DISTINCT min_bus.arrival_city
FROM min_bus
JOIN max_eco USING(flight_id)
WHERE min_bus.min_bus_amt < max_eco.max_eco_amt)
SELECT arrival_city AS "Бизнесс дешевле эконома"
FROM t1
UNION ALL 
SELECT 'Таких городов нет'
WHERE NOT EXISTS (SELECT * FROM t1)

						--Логика выполнения
-- 1. Создаем временную таблицу, в которой считаем минимальную стоимость билета категрии Бизнес по каждому рейсу 
-- 2. Создаем временную таблицу, в которой считаем максимальную стоимость билета категрии Эконом по каждому рейсу 
-- 3. Соединяем временные таблицы по номеру рейса и задаем условие вывода: стоимость билета Бизнес дешевле стоимости билета Эконом
-- 4. К результирующей таблице присоединяем новую строку с сообщением об отсутствии данных и выводим ее только тогда, 
--когда результирующая таблица пуста


-- 8.Между какими городами нет прямых рейсов?
CREATE VIEW exist_city_connection AS
SELECT DISTINCT a.city AS dep_city,
       a2.city AS ariv_city
FROM flights f 
JOIN airports a ON f.departure_airport = a.airport_code 
JOIN airports a2 ON f.arrival_airport = a2.airport_code

SELECT a.city AS "Город вылета",
       a2.city AS "Город прилета"
FROM airports a, airports a2 
WHERE a.city <> a2.city 
EXCEPT 
SELECT *
FROM exist_city_connection
ORDER BY 1,2;

						--Логика выполнения
-- 1. Создаем представление в котором выводим пары "город отправления - город прибытия". Для этого в к таблице flights
-- 2 раза присоединяем таблицу airports: первый раз по полю аэропорта отправления, второй раз по полю аэропорта прибытия
-- 3. Делаем декартово произведение таблицы airports саму на себя, дополнительным условием убираем те пары, в которых названия городов
-- одинаковы. Далее исключаем пары говродов из представления, созданного в п.1 и выводим требуемый результат.   

-- 9.Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
-- сравните с допустимой максимальной дальностью перелетов в самолетах, обслуживающих эти рейс*
SELECT DISTINCT a.airport_name  AS "Аэропорт вылета",
       a2.airport_name AS "Аэропорт прилета",
       round((acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude-a2.longitude))*6371) :: NUMERIC, 2) AS "Расстояние, км",
       a3.model AS "Модель самолета",
       a3."range" AS "Максимальная дальность полетаб км",
       CASE
             WHEN round((acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)*cosd(a2.latitude)*cosd(a.longitude-a2.longitude))*6371) :: NUMERIC, 2) < a3."range" 
             THEN 'Перелет возможен без дозаправки'
             ELSE 'Перелет невозможен без дозаправки'
       	END AS "Возможность перелета"       
FROM flights f 
JOIN airports a ON f.departure_airport = a.airport_code 
JOIN airports a2 ON f.arrival_airport = a2.airport_code 
JOIN aircrafts a3 ON f.aircraft_code = a3.aircraft_code 
ORDER BY 1,2,4;
						--Логика выполнения
-- 1. К таблице flights 2 раза присоединяем таблицу airports: 
--первый раз по полю аэропорта отправления, второй раз по полю аэропорта прибытия и таблицу aircrafts
-- 2. Выводим аэропорт отправления и прибытия, по формуле считаем расстояние между аэропортами, выводим моедль самолета 
-- и максимальную дальность полета 
-- 4. В условии сравниваем расстояние между аэропортами с максимальной дальностью полета самолета и выводим ответ: долетит без дозаправки или нет