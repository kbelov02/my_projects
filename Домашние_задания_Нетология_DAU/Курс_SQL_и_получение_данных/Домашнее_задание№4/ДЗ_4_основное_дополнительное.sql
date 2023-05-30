--=============== МОДУЛЬ 4. УГЛУБЛЕНИЕ В SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO homework_4;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--База данных: если подключение к облачной базе, то создаёте новую схему с префиксом в --виде фамилии, название должно быть на латинице в нижнем регистре и таблицы создаете --в этой новой схеме, если подключение к локальному серверу, то создаёте новую схему и --в ней создаёте таблицы.

CREATE SCHEMA homework_4

--Спроектируйте базу данных, содержащую три справочника:
--· язык (английский, французский и т. п.);
--· народность (славяне, англосаксы и т. п.);
--· страны (Россия, Германия и т. п.).
--Две таблицы со связями: язык-народность и народность-страна, отношения многие ко многим. Пример таблицы со связями — film_actor.
--Требования к таблицам-справочникам:
--· наличие ограничений первичных ключей.
--· идентификатору сущности должен присваиваться автоинкрементом;
--· наименования сущностей не должны содержать null-значения, не должны допускаться --дубликаты в названиях сущностей.
--Требования к таблицам со связями:
--· наличие ограничений первичных и внешних ключей.

--В качестве ответа на задание пришлите запросы создания таблиц и запросы по --добавлению в каждую таблицу по 5 строк с данными.
 
--СОЗДАНИЕ ТАБЛИЦЫ ЯЗЫКИ

CREATE TABLE language (
             language_id serial PRIMARY KEY,
             name varchar(20) NOT NULL UNIQUE
             )

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ ЯЗЫКИ
INSERT INTO language(name)
VALUES 
       ('Russian'),
       ('French'),
       ('English'),
       ('German'),
       ('Spanish')

DROP TABLE language

--СОЗДАНИЕ ТАБЛИЦЫ НАРОДНОСТИ
CREATE TABLE ethnics (
			 ethnic_id serial PRIMARY KEY,
			 name varchar(50) NOT NULL UNIQUE
			 );

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ НАРОДНОСТИ			
INSERT INTO ethnics(name) 
VALUES 
		('slavs'),
		('germans'),
		('gauls'),
		('britons'),
		('iberians');
			
--СОЗДАНИЕ ТАБЛИЦЫ СТРАНЫ
CREATE TABLE country (
             country_id serial PRIMARY KEY,
             name varchar(50) NOT NULL UNIQUE
             );

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СТРАНЫ
INSERT INTO country(name)
VALUES 	    
			('Russia'),
			('France'),
			('England'),
			('Germany'),
			('Spain');
		
--СОЗДАНИЕ ПЕРВОЙ ТАБЛИЦЫ СО СВЯЗЯМИ
CREATE TABLE language_ethnics (
             language_id int NOT NULL,
             ethnic_id int NOT NULL,
             PRIMARY KEY (language_id, ethnic_id),
             FOREIGN KEY (language_id) REFERENCES language(language_id) ON DELETE RESTRICT ON UPDATE CASCADE, 
             FOREIGN KEY (ethnic_id) REFERENCES ethnics(ethnic_id) ON DELETE RESTRICT ON UPDATE CASCADE 
             );
             
--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

INSERT INTO language_ethnics(language_id, ethnic_id)
VALUES		
			(1, 1),
			(2, 3),
			(3, 4),
			(4, 2),
			(5, 5);


--СОЗДАНИЕ ВТОРОЙ ТАБЛИЦЫ СО СВЯЗЯМИ
CREATE TABLE ethnics_country (
             ethnic_id int NOT NULL,
             country_id int NOT NULL,
             PRIMARY KEY (ethnic_id, country_id),
             FOREIGN KEY (ethnic_id) REFERENCES ethnics(ethnic_id) ON DELETE RESTRICT ON UPDATE CASCADE,
             FOREIGN KEY (country_id) REFERENCES country(country_id) ON DELETE RESTRICT ON UPDATE CASCADE
             );
            
--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ
INSERT INTO ethnics_country (ethnic_id, country_id)
VALUES 
			(1, 1),
			(2, 4),
			(3, 2),
			(4, 3),
			(5, 5);		

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============


--ЗАДАНИЕ №1 
--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, ограничение not null и условие, что значение должно быть больше 0
--Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.

CREATE TABLE film_new (
             film_id serial PRIMARY KEY,
			 film_name varchar(255) NOT NULL,
			 film_year int CHECK (film_year > 0),
			 film_rental_rate numeric(4,2) DEFAULT 0.99,
			 film_duration int NOT NULL CHECK (film_duration > 0)
			 );			

--ЗАДАНИЕ №2 
--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]
INSERT INTO film_new (film_name, film_year, film_rental_rate, film_duration)
SELECT *
FROM unnest(
             ARRAY['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List'],
             ARRAY[1994, 1999, 1985, 1994, 1993],
             ARRAY[2.99, 0.99, 1.99, 2.99, 3.99],
             ARRAY[142, 189, 116, 142, 195]
             );

--ЗАДАНИЕ №3
--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41

UPDATE film_new 
SET film_rental_rate =  film_rental_rate + 1.41;


--ЗАДАНИЕ №4
--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new

DELETE FROM film_new fn 
WHERE film_name = 'Back to the Future';

--ЗАДАНИЕ №5
--Добавьте в таблицу film_new запись о любом другом новом фильме

INSERT INTO film_new (film_name, film_year, film_rental_rate, film_duration)
VALUES 
       ('Shutter Island', 2010, 3.8, 138);

--ЗАДАНИЕ №6
--Напишите SQL-запрос, который выведет все колонки из таблицы film_new, 
--а также новую вычисляемую колонку "длительность фильма в часах", округлённую до десятых

SELECT *, 
       round(film_duration :: numeric/60, 1) AS length_in_hour
FROM film_new fn; 

--ЗАДАНИЕ №7 
--Удалите таблицу film_new

DROP TABLE film_new; 
