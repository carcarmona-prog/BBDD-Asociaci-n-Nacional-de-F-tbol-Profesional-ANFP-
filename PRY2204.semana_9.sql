-- 0) LIMPIEZA: elimina tablas y secuencia si existen (se puede re-ejecutar)
-- ---------------------------------------------------------------------
BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('JUGADOR_IDIOMA','PERMANENCIA_CLUB','PERSONAL_DE_PLANTA',
                                 'JUGADORES','TRABAJADORES','COMUNA','IDIOMA',
                                 'ESCUELA_FORMATIVA','CLUB_FUTBOL','NACIONALIDAD',
                                 'ASOCIACION','REGION')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences
            WHERE sequence_name = 'SEQ_COD_CLUB') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;

-- Tablas sin claves foraneas
CREATE TABLE REGION (
    cod_region     NUMBER(4)     NOT NULL,
    nombre_region  VARCHAR2(50)  NOT NULL,
    CONSTRAINT PK_REGION PRIMARY KEY (cod_region)
);
 
CREATE TABLE ASOCIACION (
    cod_asociacion     NUMBER(6)     NOT NULL,
    nombre_asociacion  VARCHAR2(50)  NOT NULL,
    fecha_creacion     DATE          NOT NULL,
    tipo_asociacion    CHAR(1)       NOT NULL,
    CONSTRAINT PK_ASOCIACION PRIMARY KEY (cod_asociacion),
    CONSTRAINT CK_ASOCIACION_TIPO CHECK (tipo_asociacion IN ('P','A')),
    CONSTRAINT CK_ASOCIACION_FECHA_CREACION
        CHECK (fecha_creacion >= TO_DATE('31-12-1980','DD-MM-YYYY'))
);
 
CREATE TABLE NACIONALIDAD (
    cod_nacionalidad     NUMBER(6) GENERATED ALWAYS AS IDENTITY
                         (START WITH 210 INCREMENT BY 2) NOT NULL,
    nombre_nacionalidad  VARCHAR2(30) NOT NULL,
    CONSTRAINT PK_NACIONALIDAD PRIMARY KEY (cod_nacionalidad),
    CONSTRAINT UN_NACIONALIDAD_NOMBRE UNIQUE (nombre_nacionalidad)
);
 
CREATE TABLE CLUB_FUTBOL (
    cod_club               NUMBER(6)     NOT NULL,
    nombre_club            VARCHAR2(30)  NOT NULL,
    patrimonio_moneda_nac  NUMBER(12)    NOT NULL,
    direccion              VARCHAR2(50)  NOT NULL,
    tipo_club              VARCHAR2(15)  DEFAULT 'Profesional' NOT NULL,
    CONSTRAINT PK_CLUB_FUTBOL PRIMARY KEY (cod_club),
    CONSTRAINT UN_CLUB_FUTBOL_NOMBRE UNIQUE (nombre_club),
    CONSTRAINT CK_CLUB_FUTBOL_TIPO CHECK (tipo_club IN ('Profesional','Amateur')),
    CONSTRAINT CK_CLUB_FUTBOL_PATRIMONIO CHECK (patrimonio_moneda_nac >= 0)
);
 
-- Secuencia para el codigo del club (703, 707, 711, ...)
CREATE SEQUENCE SEQ_COD_CLUB
    START WITH 703
    INCREMENT BY 4
    NOCACHE;
 
CREATE TABLE ESCUELA_FORMATIVA (
    cod_escuela      NUMBER(6)     NOT NULL,
    nombre_escuela   VARCHAR2(30)  NOT NULL,
    capacidad        NUMBER(6)     NOT NULL,
    fecha_fundacion  DATE          NOT NULL,
    CONSTRAINT PK_ESCUELA_FORMATIVA PRIMARY KEY (cod_escuela),
    CONSTRAINT CK_ESCUELA_FORMATIVA_CAPACIDAD CHECK (capacidad > 0)
);
 
CREATE TABLE IDIOMA (
    cod_idioma     NUMBER(6)     NOT NULL,
    nombre_idioma  VARCHAR2(20)  NOT NULL,
    CONSTRAINT PK_IDIOMA PRIMARY KEY (cod_idioma),
    CONSTRAINT UN_IDIOMA_NOMBRE UNIQUE (nombre_idioma)
);
 
-- Tablas con claves foraneas
CREATE TABLE COMUNA (
    cod_comuna     NUMBER(4)     NOT NULL,
    nombre_comuna  VARCHAR2(50)  NOT NULL,
    cod_region     NUMBER(4)     NOT NULL,
    CONSTRAINT PK_COMUNA PRIMARY KEY (cod_comuna),
    CONSTRAINT FK_COMUNA_REGION FOREIGN KEY (cod_region)
        REFERENCES REGION (cod_region)
);
 
CREATE TABLE TRABAJADORES (
    cod_inscripcion      NUMBER(9)     NOT NULL,
    rut                  NUMBER(8)     NOT NULL,
    dv                   CHAR(1)       NOT NULL,
    pnombre              VARCHAR2(20)  NOT NULL,
    snombre              VARCHAR2(20),
    apaterno             VARCHAR2(20)  NOT NULL,
    amaterno             VARCHAR2(20)  NOT NULL,
    sueldo_base          NUMBER(10)    DEFAULT 0 NOT NULL,
    fecha_de_nacimiento  DATE          NOT NULL,
    genero               CHAR(1)       NOT NULL,
    estado_civil         VARCHAR2(30)  NOT NULL,
    email                VARCHAR2(50)  NOT NULL,
    telefono_movil       NUMBER(12)    NOT NULL,
    direccion            VARCHAR2(50)  NOT NULL,
    cod_comuna           NUMBER(4)     NOT NULL,
    CONSTRAINT PK_TRABAJADORES PRIMARY KEY (cod_inscripcion),
    CONSTRAINT UN_TRABAJADORES_RUT UNIQUE (rut),
    CONSTRAINT CK_TRABAJADORES_GENERO CHECK (genero IN ('M','F','O')),
    CONSTRAINT CK_TRABAJADORES_SUELDO CHECK (sueldo_base >= 0),
    CONSTRAINT FK_TRABAJADORES_COMUNA FOREIGN KEY (cod_comuna)
        REFERENCES COMUNA (cod_comuna)
);
 
CREATE TABLE JUGADORES (
    cod_inscripcion          NUMBER(9)     NOT NULL,
    posicion_de_campo        VARCHAR2(20)  NOT NULL,
    monto_acumulado_premios  NUMBER(12)    DEFAULT 0,
    anio_fin_amateurismo     NUMBER(4),
    cod_escuela              NUMBER(6),
    cod_asociacion           NUMBER(6)     NOT NULL,
    CONSTRAINT PK_JUGADORES PRIMARY KEY (cod_inscripcion),
    CONSTRAINT CK_JUGADORES_PREMIOS CHECK (monto_acumulado_premios >= 0),
    CONSTRAINT CK_JUGADORES_ANIO_FIN CHECK (anio_fin_amateurismo >= 1900),
    CONSTRAINT FK_JUGADORES_TRABAJADORES FOREIGN KEY (cod_inscripcion)
        REFERENCES TRABAJADORES (cod_inscripcion),
    CONSTRAINT FK_JUGADORES_ESCUELA FOREIGN KEY (cod_escuela)
        REFERENCES ESCUELA_FORMATIVA (cod_escuela),
    CONSTRAINT FK_JUGADORES_ASOCIACION FOREIGN KEY (cod_asociacion)
        REFERENCES ASOCIACION (cod_asociacion)
);
 
CREATE TABLE PERSONAL_DE_PLANTA (
    cod_inscripcion            NUMBER(9)  NOT NULL,
    cantidad_horas_trabajadas  NUMBER(4)  DEFAULT 0,
    valor_horas_extras         NUMBER(6)  DEFAULT 0,
    CONSTRAINT PK_PERSONAL_DE_PLANTA PRIMARY KEY (cod_inscripcion),
    CONSTRAINT FK_PERSONAL_PLANTA_TRAB FOREIGN KEY (cod_inscripcion)
        REFERENCES TRABAJADORES (cod_inscripcion)
);
 
CREATE TABLE PERMANENCIA_CLUB (
    cod_club         NUMBER(6)  NOT NULL,
    cod_inscripcion  NUMBER(9)  NOT NULL,
    fecha_inicio     DATE       DEFAULT SYSDATE NOT NULL,
    fecha_termino    DATE,
    CONSTRAINT PK_PERMANENCIA_CLUB PRIMARY KEY (cod_club, cod_inscripcion, fecha_inicio),
    CONSTRAINT CK_PERMANENCIA_CLUB_FECHAS
        CHECK (fecha_termino IS NULL OR fecha_termino >= fecha_inicio),
    CONSTRAINT FK_PERMANENCIA_CLUB_CLUB FOREIGN KEY (cod_club)
        REFERENCES CLUB_FUTBOL (cod_club),
    CONSTRAINT FK_PERMANENCIA_CLUB_TRAB FOREIGN KEY (cod_inscripcion)
        REFERENCES TRABAJADORES (cod_inscripcion)
);
 
CREATE TABLE JUGADOR_IDIOMA (
    cod_inscripcion  NUMBER(9)     NOT NULL,
    cod_idioma       NUMBER(6)     NOT NULL,
    nivel_dominio    VARCHAR2(20)  NOT NULL,
    CONSTRAINT PK_JUGADOR_IDIOMA PRIMARY KEY (cod_inscripcion, cod_idioma),
    CONSTRAINT FK_JUGADOR_IDIOMA_JUGADORES FOREIGN KEY (cod_inscripcion)
        REFERENCES JUGADORES (cod_inscripcion),
    CONSTRAINT FK_JUGADOR_IDIOMA_IDIOMA FOREIGN KEY (cod_idioma)
        REFERENCES IDIOMA (cod_idioma)
);
 
-- ---------------------------------------------------------------------
-- 2) MODIFICACIONES DEL MODELO FISICO
--    NACIONALIDAD se relaciona con TRABAJADORES (opcional)
-- ---------------------------------------------------------------------
ALTER TABLE TRABAJADORES ADD (cod_nacionalidad NUMBER(6));
 
ALTER TABLE TRABAJADORES ADD CONSTRAINT FK_TRABAJADORES_NACIONALIDAD
    FOREIGN KEY (cod_nacionalidad) REFERENCES NACIONALIDAD (cod_nacionalidad);
    
    -- 3) POBLAMIENTO (orden de dependencia)
-- ---------------------------------------------------------------------
 
-- REGION (incluye 8 y 16, usadas por las comunas de Concepcion y Chillan)
INSERT INTO REGION (cod_region, nombre_region) VALUES (1,  'ARICA Y PARINACOTA Y TARAPACA');
INSERT INTO REGION (cod_region, nombre_region) VALUES (2,  'ANTOFAGASTA');
INSERT INTO REGION (cod_region, nombre_region) VALUES (3,  'ATACAMA Y COQUIMBO');
INSERT INTO REGION (cod_region, nombre_region) VALUES (5,  'VALPARAISO');
INSERT INTO REGION (cod_region, nombre_region) VALUES (8,  'BIOBIO');
INSERT INTO REGION (cod_region, nombre_region) VALUES (13, 'METROPOLITANA');
INSERT INTO REGION (cod_region, nombre_region) VALUES (16, 'ÑUBLE');
 
-- COMUNA
INSERT INTO COMUNA (cod_comuna, nombre_comuna, cod_region) VALUES (101, 'Santiago',   13);
INSERT INTO COMUNA (cod_comuna, nombre_comuna, cod_region) VALUES (102, 'Valparaíso',  5);
INSERT INTO COMUNA (cod_comuna, nombre_comuna, cod_region) VALUES (103, 'Concepción',  8);
INSERT INTO COMUNA (cod_comuna, nombre_comuna, cod_region) VALUES (104, 'Antofagasta', 2);
INSERT INTO COMUNA (cod_comuna, nombre_comuna, cod_region) VALUES (105, 'Chillán',    16);
 
-- ASOCIACION
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (25, 'Asociación de Fútbol de Santiago', TO_DATE('15-05-2001','DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (26, 'Asociación Nacional de Fútbol Amateur', TO_DATE('10-03-1998','DD-MM-YYYY'), 'A');
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (27, 'Asociación de Fútbol de Valparaíso', TO_DATE('21-07-1987','DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (28, 'Asociación de Fútbol de Concepción', TO_DATE('30-11-1995','DD-MM-YYYY'), 'A');
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (29, 'Asociación de Fútbol de Antofagasta', TO_DATE('25-06-2003','DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (30, 'Asociación de Fútbol de Temuco', TO_DATE('12-01-2010','DD-MM-YYYY'), 'A');
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (31, 'Asociación de Fútbol de Rancagua', TO_DATE('08-09-1999','DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (32, 'Asociación de Fútbol de Puerto Montt', TO_DATE('20-04-2005','DD-MM-YYYY'), 'A');
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (33, 'Asociación de Fútbol de La Serena', TO_DATE('14-08-2012','DD-MM-YYYY'), 'P');
INSERT INTO ASOCIACION (cod_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
VALUES (34, 'Asociación de Fútbol de Chillán', TO_DATE('01-12-2018','DD-MM-YYYY'), 'A');
 
-- NACIONALIDAD (el IDENTITY genera 210, 212, 214, 216, 218)
INSERT INTO NACIONALIDAD (nombre_nacionalidad) VALUES ('Chilena');
INSERT INTO NACIONALIDAD (nombre_nacionalidad) VALUES ('Argentina');
INSERT INTO NACIONALIDAD (nombre_nacionalidad) VALUES ('Peruana');
INSERT INTO NACIONALIDAD (nombre_nacionalidad) VALUES ('Boliviana');
INSERT INTO NACIONALIDAD (nombre_nacionalidad) VALUES ('Brasileña');
 
-- CLUB_FUTBOL (la secuencia genera 703, 707, 711, 715, 719)
INSERT INTO CLUB_FUTBOL (cod_club, nombre_club, patrimonio_moneda_nac, direccion, tipo_club)
VALUES (SEQ_COD_CLUB.NEXTVAL, 'Colo-Colo', 500000000, 'Av. Marathon 5300', 'Profesional');
INSERT INTO CLUB_FUTBOL (cod_club, nombre_club, patrimonio_moneda_nac, direccion, tipo_club)
VALUES (SEQ_COD_CLUB.NEXTVAL, 'Universidad de Chile', 450000000, 'Av. El Parrón 0931', 'Profesional');
INSERT INTO CLUB_FUTBOL (cod_club, nombre_club, patrimonio_moneda_nac, direccion, tipo_club)
VALUES (SEQ_COD_CLUB.NEXTVAL, 'Deportes Antofagasta', 180000000, 'Avenida Angamos 01606', 'Profesional');
INSERT INTO CLUB_FUTBOL (cod_club, nombre_club, patrimonio_moneda_nac, direccion, tipo_club)
VALUES (SEQ_COD_CLUB.NEXTVAL, 'Huachipato', 220000000, 'Avenida Desiderio García 909', 'Profesional');
INSERT INTO CLUB_FUTBOL (cod_club, nombre_club, patrimonio_moneda_nac, direccion, tipo_club)
VALUES (SEQ_COD_CLUB.NEXTVAL, 'Ñublense', 170000000, 'Avenida Pedro Aguirre Cerda 1003', 'Profesional');
 
COMMIT;
 
 --Fase 4: Recuperacion de datos
-- =====================================================================
 
-- Informe 1: Asociaciones de futbol profesional (tipo P, creadas despues del 2000,
--            ordenadas por fecha de creacion descendente)
SELECT cod_asociacion || ' ' || nombre_asociacion AS "ASOCIACION",
       TO_CHAR(fecha_creacion, 'DD-MM-YYYY')      AS "FECHA_CREACION",
       tipo_asociacion                            AS "TIPO_ASOCIACION"
FROM   ASOCIACION
WHERE  tipo_asociacion = 'P'
AND    EXTRACT(YEAR FROM fecha_creacion) > 2000
ORDER  BY fecha_creacion DESC;
 
-- Informe 2: Patrimonio de clubes en pesos y dolares (tipo de cambio $955)
--            Nombre con la letra a, patrimonio > 200.000.000, tipo profesional,
--            ordenados por codigo de club descendente
SELECT cod_club                                   AS "COD_CLUB",
       nombre_club                                AS "NOMBRE_CLUB",
       patrimonio_moneda_nac                      AS "PATRIMONIO_PESOS",
       ROUND(patrimonio_moneda_nac / 955, 2)      AS "PATRIMONIO_DOLARES"
FROM   CLUB_FUTBOL
WHERE  UPPER(nombre_club) LIKE '%A%'
AND    patrimonio_moneda_nac > 200000000
AND    tipo_club = 'Profesional'
ORDER  BY cod_club DESC;
