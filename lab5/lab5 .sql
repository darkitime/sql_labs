--Долголюк Даниил
--Группа: 2
--Вариант 6
-- Лабораторная работа №5 посвящена оптимизации запросов и работе с индексами. 
-- Выполнение лабораторной работы №5 заключается в анализе запросов из л.р. 2-3 и создании набора индексов, которые будут использоваться системой для выполнения этих запросов. 
--Особенное внимание при этом стоит уделять запросам, которые чаще используются и/или содержат теоретико-множественные операции – соединение, пересечение, разность и объединение. 
--После создания индексов необходимо убедиться в том, что система их использует при выполнении запросов: для этого надо посмотреть план выполнения запроса. 
--В системе Postgres в pgAdmin 4 это можно сделать, нажав после выполнения запроса на пиктограмму Explain Analyze и перейдя на вкладки Explain и Analyze. 
--Или запустить команду explain analyze select.

--1.Создать упорядоченные по факультетам списки:
---а)факультет – преподаватель – проект;
EXPLAIN ANALYZE SELECT faculty, t.name AS tutor_name, p.name AS project_name
FROM v6_tutors AS t
JOIN v6_proj AS p ON t.id_tutor = p.id_tutor
ORDER BY faculty; -- идет Hash Join
------------------
CREATE INDEX idx_proj_id_tutor ON v6_proj(id_tutor);    --Создаем индекс для соединения таблиц по внешнему ключу id_tutors
CREATE INDEX idx_tutors_faculty ON v6_tutors(faculty);  --Создаём индекс для сортировки order by faculty
SET enable_seqscan = off;   --Данных мало, поэтому запрещаем оптимизатору предпочитать последовательное чтение
EXPLAIN ANALYZE 
SELECT faculty, t.name AS tutor_name, p.name AS project_name
FROM v6_tutors AS t
JOIN v6_proj AS p ON t.id_tutor = p.id_tutor
WHERE p.id>0
ORDER BY faculty; -- Запрос выполнился с индексом

--б) рабочих проектов, в которых участвует более 3-х человек;
CREATE INDEX idx_part_id ON v6_partic(id);  --Добавим новый индекс для подсчета количества человек
DROP INDEX IF EXISTS idx_proj_id_tutor CASCADE;
CREATE INDEX idx_proj_id_tutor_status ON v6_proj(id_tutor, status); -- Добавим новый индекс для фильтрации по статусу в WHERE и удалим старый
EXPLAIN ANALYZE 
SELECT 
    p.name AS project_name, 
    count(pa.id) AS "Количество человек",
    t.faculty
FROM v6_proj AS p
JOIN v6_partic AS pa ON p.id = pa.id
JOIN v6_tutors AS t on t.id_tutor = p.id_tutor
WHERE p.status = 'рабочий'
GROUP BY t.faculty, p.name, p.id
HAVING count(pa.id) > 3;

--в) проектов, в которых нет активных участников.
--Имеющегося набора индесов достаточно для работы запроса с индексами

EXPLAIN ANALYZE 
SELECT
    p.name AS project_name,
    t.faculty
FROM v6_proj AS p
JOIN v6_tutors AS t ON t.id_tutor = p.id_tutor
LEFT JOIN v6_partic AS pa ON p.id = pa.id
WHERE pa.id IS NULL; -- Использует индексы

--2. Убедиться с помощью запроса, что у каждого преподавателя не 
---более 10-ти активных проектов (выдать список нарушений).
--Пересоздадим idx_proj_id_tutor_status, добавив к нему dbegin,dend
DROP INDEX IF EXISTS idx_proj_id_tutor_status CASCADE;
CREATE INDEX idx_proj_tutor_status_dates ON v6_proj(id_tutor, status, dbegin, dend);

EXPLAIN ANALYZE 
SELECT
    t.name AS tutor_name,
    t.faculty,
    count(p.id_tutor) as "Количество проектов"
FROM v6_tutors AS t
JOIN v6_proj AS p ON t.id_tutor = p.id_tutor
where p.dbegin <= CURRENT_DATE and (CURRENT_DATE <= p.dend OR p.dend IS NULL)
GROUP BY t.name, t.faculty, t.id_tutor
HAVING count(p.id_tutor)> 10;

--3. Проверить, что один и тот же студент не участвует более чем в двух проектах одновременно 
---(выдать список пар проектов, в которых он участвует одновременно).
CREATE INDEX idx_part_stud_proj_dates 
ON v6_partic(stud_id, id, dbegin, dend); -- Создадим индекс
--Не удаляем старый индекс, так как новый не заменяет старый т.к на первом месте stud_id 
--> данные сортируются по студентам
 
EXPLAIN ANALYZE 
SELECT
    s.name as student,
    s.grpno as group,
    s.recnum as "Зачетка",
    p1.name as project_1,
    p2.name as project_2
FROM v6_students AS s
JOIN v6_partic AS pa1 ON s.recnum = pa1.stud_id
JOIN v6_partic AS pa2 ON pa1.stud_id = pa2.stud_id AND pa1.id < pa2.id 

JOIN v6_proj AS p1 ON pa1.id = p1.id
JOIN v6_proj AS p2 ON pa2.id = p2.id

WHERE p1.status != 'в архиве' and p2.status != 'в архиве'
    AND (pa1.dend IS NULL OR pa1.dend >= pa2.dbegin)
    AND (pa2.dend IS NULL OR pa2.dend >= pa1.dbegin);


--4. Представление "Вакансии в проектах": название проекта – название роли. Вакансия открыта, если студент для роли не определен или дата завершения участия больше текущей, 
--но меньше, чем дата завершения проекта.
CREATE OR REPLACE VIEW
    v6_roles_proj(project_name, role_name)
        AS SELECT p.name, part.role
        FROM v6_proj p
        JOIN v6_partic part ON p.id = part.id
        WHERE part.stud_id IS NULL 
            OR (part.dend > CURRENT_DATE and part.dend<p.dend);
EXPLAIN ANALYZE 
SELECT * FROM v6_roles_proj; --Запрос использует уже существующие индексы

--5. Представление "Текущие проекты", у которых дата завершения проекта больше текущей или не определена
CREATE OR REPLACE VIEW
    v6_current_proj(id, project_name, project_type, head, project_begin_date, project_end_date, status)
        AS SELECT id, name, type, id_tutor,dbegin, dend, status
        FROM v6_proj p
        WHERE dend > CURRENT_DATE 
            OR dend IS NULL;
EXPLAIN ANALYZE
SELECT * FROM v6_current_proj WHERE id = 9999; -- Запрос использует уже существующие индексы

--6. Представление "Ошибки в данных об участии в проектах": данные об участии в проектах, для которых даты начала участия и/или завершения участия не соответствуют периоду выполнения проекта.
CREATE OR REPLACE VIEW
    v6_errors_in_partic_data (project_id, student_id, student_role, begin_student_date, begin_project_date, end_student_date, end_project_date)
    AS SELECT part.id, part.stud_id, part.role, part.dbegin,p.dbegin, part.dend, p.dend
    FROM v6_partic part
    JOIN v6_proj p ON p.id=part.id
    WHERE 
    part.dbegin < p.dbegin
    OR (p.dend IS NOT NULL AND part.dbegin > p.dend)
    OR (part.dend IS NOT NULL AND part.dend < p.dbegin)
    OR (p.dend IS NOT NULL AND part.dend IS NOT NULL AND part.dend > p.dend)
    OR (p.dend IS NOT NULL AND part.dend IS NULL AND p.dend < CURRENT_DATE);

EXPLAIN ANALYZE
SELECT * FROM v6_errors_in_partic_data; -- Запрос использует уже существующие индексы

SET enable_seqscan = ON;
--Таким образом мы создали следующий набор индексов:
--1. CREATE INDEX idx_tutors_faculty ON v6_tutors(faculty);
--2. CREATE INDEX idx_part_id ON v6_partic(id);
--3. --CREATE INDEX idx_proj_tutor_status_dates ON v6_proj(id_tutor, status, dbegin, dend);
--4. CREATE INDEX idx_part_stud_proj_dates  ON v6_partic(stud_id, id, dbegin, dend);

