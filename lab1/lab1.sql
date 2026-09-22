--Долголюк Даниил
--Группа: 2
--Вариант 3

--DROP TABLE IF EXISTS v2_3_partic CASCADE;
--DROP TABLE IF EXISTS v2_3_proj CASCADE;
--DROP TABLE IF EXISTS v2_3_students CASCADE;
--DROP TABLE IF EXISTS v2_3_tutors CASCADE;
--DROP TABLE IF EXISTS v2_3_groups CASCADE;

--Л.р. №1. Создание и заполнение отношений БД деканата.

--1. Отношение "Группы" (поля "Номер группы", "Факультет").

CREATE TABLE v2_3_groups(
    grpno NUMERIC(2) NOT NULL CONSTRAINT pk_grp PRIMARY KEY,
    faculty VARCHAR(80) NOT NULL
);

INSERT INTO v2_3_groups
VALUES
    (1, 'прикладная математика'),
    (2, 'прикладная математика'),
    (3, 'прикладная физика'),
    (4, 'прикладная физика'),
    (5, 'прикладная информатика');
SELECT * FROM v2_3_groups;

--2. Отношение "Преподаватели" (поля "ФИО", "Должность (старший преподаватель, доцент, профессор)", 
--"Ученая степень (кандидат или доктор наук)", "Шифр научной специальности", "Факультет").
CREATE TABLE v2_3_tutors(
    name VARCHAR(50) NOT NULL CONSTRAINT pk_name PRIMARY KEY,
    post VARCHAR(40) NOT NULL CONSTRAINT check_post CHECK(post IN ('старший преподаватель', 'доцент', 'профессор')),
    acdeg VARCHAR(30) NULL CONSTRAINT check_acdeg CHECK(acdeg IN ('кандидат','доктор наук')),
    scienciph VARCHAR(30) NOT NULL,
    faculty VARCHAR(80) NOT NULL
);

INSERT INTO v2_3_tutors
VALUES
    ('Максимов Михал Александрович', 'профессор','доктор наук','4.2.1','прикладная физика'),
    ('Некосов Олег Владиславович', 'старший преподаватель', NULL ,'4.2.2','прикладная физика'),
    ('Максимова Анна Викторовна', 'профессор','доктор наук','4.2.1','прикладная математика'),
    ('Алексеев Александр Андреевич', 'доцент','доктор наук','5.2.1','прикладная информатика'),
    ('Попов Владимир Михайлович', 'доцент','кандидат','5.3.1','прикладная информатика');
SELECT * FROM v2_3_tutors;

--3.Отношение "Студенты" (поля "Номер зачетной книжки", "ФИО", "Группа", "Дата рождения").
CREATE TABLE v2_3_students(
    recnum NUMERIC(50) NOT NULL,
    name VARCHAR(50) NOT NULL CONSTRAINT rk_name PRIMARY KEY,
    grpno NUMERIC(2) NOT NULL CONSTRAINT ref_grp REFERENCES v2_3_groups,
    bithday DATE NOT NULL
);
INSERT INTO v2_3_students
VALUES
    (1234124123, 'Андреев Виктор Александрович',1, '1.01.2003'),
    (1234124124, 'Максимова Анастасия Михайловна', 3, '11.02.2003'),
    (1234124125, 'Антонова Анастасия Михайловна', 2, '17.06.2003'),
    (1234124126, 'Михайлов Михаил Михайлович', 4, '22.08.2003'),
    (1234124127, 'Архипова Мария Петровна', 5, '3.09.2003');
SELECT * FROM v2_3_students;

--4. Проекты
CREATE TABLE v2_3_proj(
    id NUMERIC(5,0) NOT NULL CONSTRAINT pk_id PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(20) NOT NULL CONSTRAINT check_type CHECK(type IN (upper('нир'),'прикладной')),
    head VARCHAR(50) NOT NULL CONSTRAINT ref_head REFERENCES v2_3_tutors,
    dbegin DATE NOT NULL,
    dend DATE NULL,
    status VARCHAR(30) NOT NULL CONSTRAINT check_stat CHECK(status IN ('новый','рабочий', 'в архиве'))
);
INSERT INTO v2_3_proj
VALUES
    (10101, 'ИКТ', 'прикладной','Максимов Михал Александрович', '22.09.2026', NULL,'новый'),
    (11211, 'НКТ', 'НИР','Максимов Михал Александрович', '21.09.2026', NULL,'рабочий'),
    (12111, 'ПУУУ', 'прикладной','Максимова Анна Викторовна', '24.09.2026', NULL,'новый'),
    (11111, 'ВИ', 'прикладной','Алексеев Александр Андреевич', '23.09.2026', '21.09.2027','в архиве'),
    (00000, 'ЛТИ', 'прикладной','Попов Владимир Михайлович', '22.09.2026', NULL,'новый');
SELECT * FROM v2_3_proj;

--5. Отношение "Участие в проектах" 
--(поле "Проект", "Студент", "Роль в проекте", "Дата начала участия", "Дата завершения участия").
CREATE TABLE v2_3_partic(
    id NUMERIC(5,0) NOT NULL CONSTRAINT ref_id REFERENCES v2_3_proj,
    name VARCHAR(50) NOT NULL CONSTRAINT ref_name REFERENCES v2_3_students,
    role VARCHAR(50) NOT NULL,
    dbegin DATE NOT NULL,
    dend DATE NULL
);
INSERT INTO v2_3_partic
VALUES
    (10101, 'Андреев Виктор Александрович', 'лабборант', '22.09.2026', NULL),
    (11211, 'Максимова Анастасия Михайловна', 'научный сотрудник','21.09.2026', NULL),
    (12111, 'Антонова Анастасия Михайловна', 'разработчик','24.09.2026', NULL),
    (11111, 'Михайлов Михаил Михайлович', 'лабборант','23.09.2026', '21.09.2027'),
    (00000, 'Архипова Мария Петровна', 'лабборант','22.09.2026', NULL);
SELECT * FROM v2_3_partic;


--Заполнение данных
---\copy v2_3_groups FROM 'lab1/groups.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
---SELECT * FROM v2_3_groups LIMIT 5;