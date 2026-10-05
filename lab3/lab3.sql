--Долголюк Даниил
--Группа: 2
--Вариант 6


--Л.р. №3. Работа с представлениями. Для созданных представлений необходимо проверить с помощью команд DML, являются ли они обновляемыми, и объяснить полученный результат.



--Представление "Вакансии в проектах": название проекта – название роли. Вакансия открыта, если студент для роли не определен или дата завершения участия больше текущей, 
--но меньше, чем дата завершения проекта.
CREATE OR REPLACE VIEW
    v6_roles_proj(project_name, role_name)
        AS SELECT p.name, part.role
        FROM v6_proj p
        JOIN v6_partic part ON p.id = part.id
        WHERE part.stud_id IS NULL 
            OR (part.dend > CURRENT_DATE and part.dend<p.dend);
            --не является обновляемым так выбирает данные более чем из одной таблицы
SELECT * FROM v6_roles_proj;


--Представление "Текущие проекты", у которых дата завершения проекта больше текущей или не определена
CREATE OR REPLACE VIEW
    v6_current_proj(id, project_name, project_type, head, project_begin_date, project_end_date, status)
        AS SELECT id, name, type, id_tutor,dbegin, dend, status
        FROM v6_proj p
        WHERE dend > CURRENT_DATE 
            OR dend IS NULL;
INSERT INTO v6_current_proj (id, project_name, project_type, head, project_begin_date, project_end_date, status)
VALUES (9999, 'Тестовый проект', 'НИР',11, '04.10.2026', '06.06.2027','рабочий');

UPDATE v6_current_proj
SET project_name = 'Обновеленный тестовый проект'
WHERE id = 9999

DELETE FROM v6_current_proj
WHERE id = 9999

SELECT * FROM v6_current_proj WHERE id = 9999;
--DROP VIEW IF EXISTS v6_current_proj CASCADE;

--Представление "Ошибки в данных об участии в проектах": данные об участии в проектах, для которых даты начала участия и/или завершения участия не соответствуют периоду выполнения проекта.
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
        --не является обновляемым так выбирает данные более чем из одной таблицы

SELECT * FROM v6_errors_in_partic_data