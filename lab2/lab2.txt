--Долголюк Даниил
--Группа: 2
--Вариант 6

--Л.р. №2. Выборка данных. Один из запросов надо написать двумя способами и объяснить, 
---какой из вариантов будет работать быстрее и почему.

---Создать упорядоченные по факультетам списки:
---факультет – преподаватель – проект;
SELECT faculty, t.name AS tutor_name, p.name AS project_name
FROM v6_tutors AS t
JOIN v6_proj AS p ON t.id_tutor = p.id_tutor
ORDER BY faculty;

---рабочих проектов, в которых участвует более 3-х человек;\
--1 Способ
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

--2 Способ (Дольше так как group by для всех проектов)
SELECT 
    p.name AS project_name, 
    count(pa.id) AS "Количество человек",
    t.faculty
FROM v6_proj AS p
JOIN v6_partic AS pa ON p.id = pa.id
JOIN v6_tutors AS t on t.id_tutor = p.id_tutor
GROUP BY t.faculty, p.name, p.id
HAVING count(CASE WHEN p.status = 'рабочий' THEN pa.id END) > 3;
-- не будет работать правильно. Добавляем данные:
INSERT INTO v6_proj
VALUES
    (10555, 'ИКТ', 'прикладной',11, '22.09.2026', '22.09.2027','новый');
INSERT INTO v6_partic
VALUES
    (10555, 1234124123, 'лаборант', '22.09.2026', NULL),
    (10555, 1234124124, 'научный сотрудник','21.09.2026', NULL),
    (10555, 1234124125, 'разработчик','24.09.2026', NULL),
    (10555, 1234124126, 'лаборант','23.09.2026', '21.09.2027');
-- и получаем этот проект в результате. А он новый.
-- Вообще указывать условие в части order by неверно: не соответствует стандарту, не везде работает.

---проектов, в которых нет активных участников.
SELECT
    p.name AS project_name,
    t.faculty
FROM v6_proj AS p
JOIN v6_tutors AS t ON t.id_tutor = p.id_tutor
LEFT JOIN v6_partic AS pa ON p.id = pa.id
WHERE pa.id IS NULL
GROUP BY t.faculty, p.name; 


---Убедиться с помощью запроса, что у каждого преподавателя не 
---более 10-ти активных проектов (выдать список нарушений). 
SELECT
    t.name AS tutor_name,
    t.faculty,
    count(p.id_tutor) as "Количество проектов"
FROM v6_tutors AS t
JOIN v6_proj AS p ON t.id_tutor = p.id_tutor
where p.dbegin <= CURRENT_DATE and (CURRENT_DATE <= p.dend OR p.dend IS NULL)
GROUP BY t.name, t.faculty, t.id_tutor
HAVING count(p.id_tutor)> 10;


---Проверить, что один и тот же студент не участвует более чем в двух проектах одновременно 
---(выдать список пар проектов, в которых он участвует одновременно).
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