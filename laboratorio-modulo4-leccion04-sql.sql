-- Ejercicio 1. Queries Generales

-- 1.1. Calcula el promedio más bajo y más alto de temperatura. Min y max de cada día

select c.fecha, min(c.temperatura), max(c.temperatura)
from clima c
group by c.fecha 
order by c.fecha asc;


-- 1.2. Obtén los municipios en los cuales coincidan las medias de la sensación térmica y de la temperatura. 
select 
    municipio_id, 
    round(avg(temperatura),2) as avg_temperatura, 
    round(avg(sensacion),2) as avg_sensacion
from clima
group by municipio_id
having AVG(temperatura) = AVG(sensacion);


-- 1.3. Obtén el local más cercano de cada municipio
select min(l.nombre) as nombre_local, min(l.distancia) as distancia_minima, m.nombre as nombre_municipio
from locales l 
inner join municipios m 
    on l.id_municipio = m.id_municipio
group by m.nombre ;

select min (distancia) from locales l group by l.id_municipio 


-- 1.4. Localiza los municipios que posean algún localizador a una distancia mayor de 2000 y que posean al menos 25 locales.

select m.nombre, sum(l.id_local) as total_locales
from municipios m
join locales l on m.id_municipio = l.id_municipio
where l.distancia > 2000
group by  m.nombre
having sum(l.id_local) >= 25;

select max(distancia) from locales l 


-- 1.5. Teniendo en cuenta que el viento se considera leve con una velocidad media de entre 6 y 20 km/h, 
-- moderado con una media de entre 21 y 40 km/h, fuerte con media de entre 41 y 70 km/h y
-- muy fuerte entre 71 y 120 km/h.
-- Calcula cuántas rachas de cada tipo tenemos en cada uno de los días.
-- Este ejercicio debes solucionarlo con la sentencia CASE de SQL
-- (no la hemos visto en clase, por lo que tendrás que buscar la documentación).

--select * from locales

-- SELECT CustomerName, City, Country
-- FROM Customers
-- ORDER BY
-- (CASE
--    WHEN City IS NULL THEN Country
--    ELSE City
-- END);

select
    fecha,
    sum(case
        when velocidad_viento between 6 and 20
        then 1
        else 0
    end) as leve,
    sum(case
        when velocidad_viento between 21 and 40
        then 1
        else 0
        end) as moderado,
        sum(case
        when velocidad_viento between 41 and 70
        then 1
        else 0
    end) as fuerte,
    sum(case
        when velocidad_viento between 71 and 120
        then 1
        else 0
    end) as muy_fuerte

from clima
group by fecha
order by fecha;


-- Ejercicio 2: Vistas

-- 2.1. Crea una vista que muestre la información de los locales que tengan incluido el código postal 
-- en su dirección. 

create view VistaCodigoPostal as 
select *
from locales l
where direccion like '%28___%';


-- 2.2. Crea una vista con los locales que tienen más de una categoría asociada.

create view VistaLocalesCategorias as
select id_local, id_municipio, nombre
    count(distinct categoria) as total_categorias
from locales l
group by id_local, id_municipio, nombre
having count(distinct categoria) > 1;

select m.nombre as nombre_municipio,
    (select count(l.id_local)
     from locales l 
     where l.id_municipio = m.id_municipio) as num_locales
from municipios m
order by num_locales DESC
limit 1;



-- 2.3. Crea una vista que muestre el municipio con la temperatura más alta de cada día

create view TemperaturasMasAltas as
select * from municipios m 
where id_municipio in (
                select municipio_id from (
                select municipio_id , 
                    rank() over (partition by fecha order by temperatura desc) as "ranking",
                    -- Separa por fecha y ordena por temperatura.
                    -- Las filas con rank 1 muestran las temperaturas más altas de cada municipio
                    
                    fecha, 
                    temperatura
                from clima c ) as prueba
                where ranking = 1 
            );
                -- Me quedo con las temperaturas más altas para una fecha (rank 1)

-- Va a devolver los valores de  id_municipio con las temperaturas más altas cada día
        
        
-- opción miguel
-- CREATE VIEW vista_3 AS
-- SELECT municipio, dia, promedio
-- FROM (
--            SELECT municipio, EXTRACT(DAY FROM w.fecha) AS dia, AVG(temp_celsius) promedio, MAX(AVG(temp_celsius)) OVER (PARTITION BY EXTRACT(DAY FROM w.fecha))
--            FROM municipios m 
--            INNER JOIN weather w 
--                ON w.id_municipio = m.id_municipio
--            GROUP BY municipio, EXTRACT(DAY FROM w.fecha)
--            )
-- WHERE promedio = max;


-- 2.4. Crea una vista con los municipios en los que haya una probabilidad de precipitación mayor del 100% durante mínimo 7 horas.
-- Cambio consulta porque no tengo probabilidad precipitación: humedad mayor al 80% durante 7 horas del día.

create view VistaHumedad as
select  c.municipio_id,
        m.nombre as nombre_municipio,
        c.fecha,
        count(c.hora) as horas_humedad_alta
from clima c
join municipios m
    on c.municipio_id = m.id_municipio
where c.humedad_relativa > 80
group by c.municipio_id, c.fecha, m.nombre
having count(c.hora) >= 7
order by c.fecha;


-- 2.5. Obtén una lista con los parques de los municipios que tengan algún castillo.
create view VistaCastillo as 
select *
from locales l
where l.nombre like '%astillo%' and l.categoria = 'Park' or l.categoria = 'Castle';


-- Ejercicio 3. Tablas Temporales

-- 3.1. Crea una tabla temporal que muestre cuántos días han pasado desde que 
-- se obtuvo la información de la tabla AEMET.

create temporary table dias_recoleccion as
select
    c.fecha as fecha_recoleccion,
    current_date - c.fecha AS dias_desde
from
    clima c;

-- 3.2. Crea una tabla temporal que muestre los locales que tienen más de una
-- categoría asociada e indica el conteo de las mismas

create temporary table LocalesCategorias as
select 
    l.id_local,
    l.nombre,
    count(distinct l.categoria) as conteo_categorias
from locales l
group by l.id_local, l.nombre
having count(distinct l.categoria) > 1;


-- 3.3. Crea una tabla temporal que muestre los tipos de cielo para los cuales la
-- probabilidad de precipitación mínima de los promedios de cada día es 5.
-- Dado que no tengo prob. precipitación, la condición será, cielos donde los mm de precipitación sean >=2
create temporary table CieloConPrecipitacion as
select 
    c.cielo,
    avg(c.precipitacion) as mm_precipitacion
from clima c
where c.precipitacion >= 2
group by c.cielo;


-- 3.4. Crea una tabla temporal que muestre el tipo de cielo más y menos repetido por municipio.
create temporary table CielosPorMunicipio as
select count(c.cielo), c.cielo, c.municipio_id
from clima c 
group by c.cielo, c.municipio_id

-- No he conseguido acabar este ejercicio.

select * from clima

-- Ejercicio 4. Subqueries

-- 4.1. Necesitamos comprobar si hay algún municipio en el cual no tenga ningún local registrado.
select nombre
from municipios m
where id_municipio not in (
    select distinct id_municipio
    from locales l
);

select distinct id_municipio from locales

-- 4.2. Averigua si hay alguna fecha en la que el cielo se encuente "Muy nuboso con tormenta".

select 
    (select nombre
    from municipios
    where id_municipio = c.municipio_id) as municipio,
    c.fecha
from clima c
where c.cielo = 'Muy nuboso con tormenta';


-- 4.3. Encuentra los días en los que los avisos sean diferentes a "Sin riesgo".
-- He eliminado la columna riesgos

-- 4.4. Selecciona el municipio con mayor número de locales.
select m.nombre as nombre_municipio,
    (select 
    count(l.id_local)
     from locales l 
     where l.id_municipio = m.id_municipio) as num_locales
from municipios m
order by num_locales desc
limit 1;


-- 4.5. Obtén los municipios muya media de sensación térmica sea mayor que la media total.

select 
    m.nombre as nombre_municipio,
    round(media.media_sensacion,2) as media_sensacion
from municipios m
inner join (
    select 
        municipio_id, 
        avg(sensacion) as media_sensacion
    from clima c
    group by municipio_id
    having
        avg(sensacion) > (
            select avg(sensacion) 
            from clima
        )
) as media 
on 
    m.id_municipio = media.municipio_id;


-- 4.6. Selecciona los municipios con más de dos fuentes.
select 
    (select nombre 
    from municipios
    where id_municipio = l.id_municipio) as municipio,
    l.id_municipio,
    count(l.id_local) as num_locales_con_fuente
from locales l
where l.categoria = 'Fountain'
group by l.id_municipio
having count(l.id_local) > 2;


-- 4.7. Localiza la dirección de todos los estudios de cine que estén abiertod en el municipio de "Madrid".
select direccion
from locales
where id_municipio = (
    select id_municipio 
    from municipios 
    where nombre = 'Madrid'
)
and categoria = 'Film Studio'
and estado = 'VeryLikelyOpen';

select distinct categoria from locales

-- 4.8. Encuentra la máxima temperatura para cada tipo de cielo.
-- No puedo usar subquery porque la tengo en la misma tabla.
select 
    cielo, 
    max(temperatura) as max_temperatura
from clima c
group by cielo;


-- 4.9. Muestra el número de locales por categoría que muy probablemente se encuentren abiertos.
select 
    categoria, 
    COUNT(id_local) as numero_locales
from locales l
where estado = 'VeryLikelyOpen'
group by categoria;

select distinct estado from locales


