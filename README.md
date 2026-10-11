# ANFP – Base de Datos de Fútbol Profesional y Amateur

**Evaluación Final Transversal (EFT) – Semana 9 · PRY2204 Modelamiento de Bases de Datos**
Duoc UC · Analista Programador Computacional

Solución de base de datos relacional normalizada para la **Asociación Nacional de Fútbol Profesional (ANFP)**, que centraliza la información de trabajadores (jugadores y personal de planta), clubes, escuelas formativas, asociaciones, idiomas y datos geográficos, eliminando la duplicidad e inconsistencia de las planillas independientes usadas actualmente.

---

## Contenido

- [Contexto](#contexto)
- [Tecnologías](#tecnologías)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Modelo de datos](#modelo-de-datos)
- [Decisiones de diseño](#decisiones-de-diseño)
- [Implementación física](#implementación-física)
- [Cómo ejecutar el script](#cómo-ejecutar-el-script)
- [Informes SQL](#informes-sql)
- [Entregables](#entregables)
- [Autor](#autor)

---

## Contexto

La ANFP administra las competencias de fútbol profesional en Chile. Su información se almacena hoy en planillas independientes, lo que genera duplicidad de datos, inconsistencias y dificultades para gestionar contratos y tomar decisiones.

Este proyecto diseña e implementa una base de datos que modela:

- Trabajadores de un club, clasificados en **jugadores** y **personal de planta**.
- **Historial de permanencia** de cada trabajador en los clubes a lo largo del tiempo.
- **Idiomas** que domina cada jugador y su nivel de dominio.
- **Escuelas formativas** de origen y año de egreso del amateurismo.
- **Asociaciones** que gestionan los campeonatos (profesionales y amateur).
- Datos geográficos (**región** y **comuna**) y **nacionalidad**.

## Tecnologías

| Herramienta | Uso |
|---|---|
| Oracle SQL Developer Data Modeler | Modelo Entidad-Relación Extendido (notación Barker) y Modelo Relacional |
| Oracle Database 19c Express Edition (o superior) | Motor de base de datos |
| Oracle SQL Developer | Ejecución del script y consultas |

## Estructura del repositorio

```text
.
├── README.md
├── PRY2204_EFT_S9_Script_Fase3.sql   # DDL, poblamiento y consultas (Fases 3 y 4)
├── <modelo>.zip                      # Archivo .dmd del Data Modeler + carpeta de recursos
└── <documento>.docx                  # Formato de respuesta con las capturas de los modelos
```

> Reemplaza `<modelo>.zip` y `<documento>.docx` por los nombres reales de tus archivos.

## Modelo de datos

El desarrollo se organizó en cuatro fases:

1. **Fase 1 – MER-E normalizado** en notación Barker.
2. **Fase 2 – Modelo Relacional (MR) normalizado** (1FN, 2FN y 3FN).
3. **Fase 3 – Implementación física** (DDL y poblamiento).
4. **Fase 4 – Recuperación de datos** mediante consultas `SELECT`.

### Tablas

| Tabla | Descripción | Clave primaria |
|---|---|---|
| `REGION` | Regiones de Chile | `cod_region` |
| `COMUNA` | Comunas, asociadas a una región | `cod_comuna` |
| `ASOCIACION` | Asociaciones gestoras de campeonatos (tipo `P` profesional / `A` amateur) | `cod_asociacion` |
| `NACIONALIDAD` | Nacionalidades (clave `IDENTITY`: inicia en 210, incremento 2) | `cod_nacionalidad` |
| `CLUB_FUTBOL` | Clubes con patrimonio y tipo (código por secuencia: inicia en 703, incremento 4) | `cod_club` |
| `ESCUELA_FORMATIVA` | Escuelas de fútbol donde se formaron los jugadores | `cod_escuela` |
| `IDIOMA` | Catálogo de idiomas | `cod_idioma` |
| `TRABAJADORES` | Supertipo con los datos comunes de todo trabajador | `cod_inscripcion` |
| `JUGADORES` | Subtipo de `TRABAJADORES` (posición, premios, escuela, asociación) | `cod_inscripcion` |
| `PERSONAL_DE_PLANTA` | Subtipo de `TRABAJADORES` (horas trabajadas y horas extras) | `cod_inscripcion` |
| `PERMANENCIA_CLUB` | Historial de permanencia de un trabajador en un club | `cod_club`, `cod_inscripcion`, `fecha_inicio` |
| `JUGADOR_IDIOMA` | Idiomas que domina cada jugador y su nivel | `cod_inscripcion`, `cod_idioma` |

## Decisiones de diseño

- **Supertipo y subtipos.** `TRABAJADORES` concentra los datos comunes. `JUGADORES` y `PERSONAL_DE_PLANTA` heredan su clave (`cod_inscripcion`), que es a la vez PK y FK.
- **Historial de clubes.** La relación trabajador–club es muchos a muchos en el tiempo, por lo que se resolvió con la entidad asociativa `PERMANENCIA_CLUB`. La clave incluye `fecha_inicio`, de modo que un trabajador pueda volver a un mismo club en otro período. Una `fecha_termino` vacía indica el club actual.
- **Idiomas.** El atributo multivalorado se resolvió con la entidad asociativa `JUGADOR_IDIOMA`, que almacena `nivel_dominio`.
- **Escuela formativa opcional.** Un jugador puede no provenir de una escuela, por lo que `cod_escuela` y `anio_fin_amateurismo` admiten nulos.
- **Región y comuna.** La comuna de residencia determina la región, por lo que ésta se obtiene a través de `COMUNA`, evitando dependencias transitivas (3FN).
- **Nacionalidad.** La tabla se incorpora en la implementación física como modificación del modelo, y se relaciona de forma opcional con `TRABAJADORES` mediante una clave foránea.

### Normalización

- **1FN:** atributos atómicos; los atributos multivalorados (idiomas y clubes) se movieron a tablas propias.
- **2FN:** los atributos de las entidades asociativas dependen de la clave completa (`nivel_dominio`, `fecha_termino`).
- **3FN:** sin dependencias transitivas (región obtenida vía comuna).

## Implementación física

El script crea las tablas **en orden de dependencia** e incorpora:

- Claves primarias, foráneas y únicas con nombres representativos (`PK_`, `FK_`, `UN_`, `CK_` + tabla).
- Restricciones de validación (`CHECK`), entre ellas:
  - `ASOCIACION.fecha_creacion` igual o posterior al 31-12-1980.
  - `ASOCIACION.tipo_asociacion` solo `'P'` o `'A'`.
  - `CLUB_FUTBOL.tipo_club` solo `'Profesional'` o `'Amateur'`.
  - `PERMANENCIA_CLUB.fecha_termino` posterior o igual a `fecha_inicio`.
- Nombre de club **único** (`UN_CLUB_FUTBOL_NOMBRE`).
- Valores predeterminados (`DEFAULT`) en premios, horas, sueldo base y fecha de inicio.
- **Columna `IDENTITY`** en `NACIONALIDAD` (inicio 210, incremento 2).
- **Secuencia** `SEQ_COD_CLUB` para el código del club (inicio 703, incremento 4).

Se puebla únicamente `REGION`, `COMUNA`, `ASOCIACION`, `NACIONALIDAD` y `CLUB_FUTBOL`, respetando la integridad referencial.

## Cómo ejecutar el script

**Requisitos:** Oracle Database 19c XE o superior (o Oracle Cloud) y Oracle SQL Developer.

1. Conéctate como `SYS` o `SYSTEM` (o `ADMIN` en Oracle Cloud) y ejecuta `PRY2204_EFT_S9_Script_crea_usuario.sql` para crear el usuario `PRY2204_S9`.
2. Crea una conexión llamada **`PRY2204_S9`** con ese usuario.
3. Abre `PRY2204_EFT_S9_Script_Fase3.sql` en esa conexión.
4. Ejecuta el archivo completo con **F5** (*Ejecutar secuencia de comandos*), sin texto seleccionado.
5. Revisa en la pestaña *Salida de script* que no existan errores.

El script comienza con un bloque de limpieza que elimina las tablas y la secuencia si ya existen, por lo que puede **ejecutarse repetidamente** sin errores.

### Verificación

Tras la ejecución:

- `CLUB_FUTBOL` debe tener los códigos **703, 707, 711, 715 y 719**.
- `NACIONALIDAD` debe tener los códigos **210, 212, 214, 216 y 218**.
- `REGION` incluye las regiones 8 (Biobío) y 16 (Ñuble), necesarias para las comunas de Concepción y Chillán.

## Informes SQL

Ejecuta cada consulta por separado con **Ctrl + Enter**.

**Informe 1 – Asociaciones de fútbol profesional:** tipo profesional (`P`), creadas después del año 2000, ordenadas por fecha de creación descendente.
Resultado esperado: La Serena (2012), Antofagasta (2003) y Santiago (2001).

**Informe 2 – Patrimonio de clubes en pesos y dólares** (tipo de cambio $955 por dólar): nombre con la letra *a*, patrimonio superior a $200.000.000, tipo profesional, ordenados por código descendente.
Resultado esperado: Huachipato (715) y Universidad de Chile (707).

## Entregables

- Documento Word con las capturas del MER-E (notación Barker) y del Modelo Relacional.
- Archivo `.zip` con el modelo `.dmd` y su carpeta de recursos.
- Script `.sql` con la implementación del modelo físico.
- Video de presentación (máximo 7 minutos): `<enlace al video>`

## Autor

**Carlos Carmona** · Analista Programador Computacional, Duoc UC
GitHub: [@carcarmona-prog](https://github.com/carcarmona-prog)
