# Ejercicio en Clase 1 - Data Warehouse (Star Schema)

## Integrantes
- Anthony Fajardo
- Gabriela Coloma
- Mateo Vivanco
- Sebastian Encalada
- Luis Eduardo Zaldumbide

---

## Requisitos Previos

- Acceso a **Snowflake** con permisos para crear bases de datos y tablas
- Dataset **TPCH_SF1000** disponible en `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000`

### Configuración de Base de Datos

```sql
CREATE DATABASE SAMPLE_STAR_SCHEMA;
CREATE SCHEMA SAMPLE_STAR_SCHEMA.GOLD;
USE SCHEMA SAMPLE_STAR_SCHEMA.GOLD;
```

---

## Contexto

Este proyecto utiliza el dataset **TPCH_SF1000** disponible en Snowflake.
Se asume que los datos fuente ya se encuentran **limpios y curados (Silver Layer)**, por lo que el alcance del trabajo se centra exclusivamente en el **diseño e implementación de la capa GOLD**, orientada a análisis analítico y de negocio.

El diseño de la capa GOLD se realizó siguiendo un enfoque **bottom-up**, partiendo de las **preguntas de negocio** que debían ser respondidas, y no desde una reproducción completa del modelo relacional original.
Este enfoque permitió seleccionar únicamente las entidades necesarias para satisfacer los requerimientos analíticos, evitando complejidad innecesaria y priorizando claridad, rendimiento y alineación con el análisis requerido.

---

## Proceso de Selección del Modelo Dimensional

### 1. Identificación del Nivel de Análisis (Grain)

Las preguntas de negocio requieren analizar métricas de ventas, descuentos, producto y tiempos de despacho a nivel detallado.
Por esta razón, se definió como granularidad:

> **1 fila por línea de orden**, representada mediante `lineitem_id`.

Este nivel de detalle permite:
- Analizar revenue neto
- Evaluar descuentos
- Estudiar mix de producto
- Medir desempeño logístico

### 2. Identificación de la Tabla de Hechos

A partir del análisis del modelo TPCH, se determinó que la información central de negocio se obtiene de la relación entre:

- `LINEITEM` (detalle transaccional)
- `ORDERS` (fecha de orden y cliente)

Como resultado, se definió la tabla de hechos **FactOrder**, la cual:
- Representa cada línea de orden
- Contiene métricas de revenue
- Se relaciona con cliente y producto/logística

### 3. Análisis de las Preguntas de Negocio

Las preguntas solicitadas se agrupan en los siguientes ejes analíticos:

- Ingresos por región y mes del cliente
- Evolución temporal del revenue neto
- Top clientes
- Mix de producto
- Desempeño logístico

A partir de este análisis se determinó que **toda la información necesaria** podía organizarse eficientemente en **una tabla de hechos y dos dimensiones**, sin necesidad de replicar la normalización completa del modelo original.

---

## Gold Layer - Star Schema

### Diagrama del Modelo

![Diagrama Star Schema](dm_ejercicicio_en_clase.drawio.png)

```
┌──────────────────┐         ┌─────────────────────┐         ┌──────────────────┐
│  DimCustomer     │         │    FactOrder        │         │  DimLineItem     │
├──────────────────┤         ├─────────────────────┤         ├──────────────────┤
│ PK customer_id   │◄────────│ PK mezcla           │────────►│ PK lineitem_id   │
│ C_NAME           │         │ FK customer_id      │         │ L_SHIPDATE       │
│ N_NAME           │         │ FK lineitem_id      │         │ L_SHIPMODE       │
│ R_NAME           │         │ O_ORDERDATE         │         │ P_BRAND          │
└──────────────────┘         │ O_TOTALPRICE        │         │ P_MFGR           │
                             └─────────────────────┘         │ L_DISCOUNT       │
                                                             └──────────────────┘
```

---

## Tabla de Hechos

### FactOrder

**Grain (Granularidad):**
> 1 fila representa **una línea de orden**, identificada por `lineitem_id`, asociada a un cliente.

**Campos principales:**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| mezcla | PK | Clave primaria |
| customer_id | FK | Referencia a DimCustomer |
| lineitem_id | FK | Referencia a DimLineItem |
| O_ORDERDATE | DATE | Fecha de la orden |
| O_TOTALPRICE | DECIMAL | Precio total de la orden |

**Script de creación (`fact_order.sql`):**
```sql
CREATE TABLE FactOrder AS
SELECT *
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.ORDERS
```

Esta tabla concentra las métricas de negocio y actúa como el núcleo analítico del modelo.

---

## Dimensiones

### DimCustomer

La dimensión **DimCustomer** centraliza la información del cliente y su contexto comercial y geográfico.

**Campos principales:**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| customer_id | PK | Clave primaria del cliente |
| C_NAME | VARCHAR | Nombre del cliente |
| N_NAME | VARCHAR | Nación del cliente |
| R_NAME | VARCHAR | Región del cliente |

**Script de creación (`dim_customer.sql`):**
```sql
CREATE TABLE DimCustomer AS
SELECT *
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.CUSTOMER
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.NATION
  ON CUSTOMER.C_NATIONKEY = NATION.N_NATIONKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.REGION
  ON NATION.N_REGIONKEY = REGION.R_REGIONKEY
```

**Justificación:**
Aunque el modelo original separa `CUSTOMER`, `NATION` y `REGION`, en la capa GOLD esta información se conceptualiza como **un único contexto del cliente**, ya que las consultas analíticas se enfocan en:
- El cliente como entidad de negocio
- Su ubicación regional para análisis de revenue

**Permite responder:**
- Ingresos por región y mes
- Evolución del revenue por región del cliente
- Top clientes por revenue neto

---

### DimLineItem

La dimensión **DimLineItem** concentra la información operativa, logística y de producto asociada a cada línea de orden.

**Campos principales:**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| lineitem_id | PK | Clave primaria |
| L_SHIPDATE | DATE | Fecha de envío |
| L_SHIPMODE | VARCHAR | Modo de envío |
| P_BRAND | VARCHAR | Marca del producto |
| P_MFGR | VARCHAR | Fabricante del producto |
| L_DISCOUNT | DECIMAL | Descuento aplicado |

**Script de creación (`dim_line_item.sql`):**
```sql
CREATE TABLE DimLineItem AS
SELECT *
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.LINEITEM
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.PART
  ON LINEITEM.L_PARTKEY = PART.P_PARTKEY
```

**Justificación:**
Esta dimensión agrupa atributos necesarios para:
- Analizar el mix de producto
- Evaluar el impacto del descuento
- Medir tiempos y modos de despacho

**Permite responder:**
- Mix de producto (brands y manufacturers)
- Efecto del descuento sobre el revenue
- Performance logístico por ship mode y volumen

---

## Relaciones

El modelo sigue un **esquema estrella**, donde:

- `FactOrder` se relaciona con:
  - `DimCustomer` mediante `customer_id`
  - `DimLineItem` mediante `lineitem_id`

Las relaciones son de tipo **1 → N** desde las dimensiones hacia la tabla de hechos, optimizando el desempeño de las consultas analíticas.

---

## Consultas Analíticas

### Question 1: Ingresos por Región y Mes

**Archivo:** `question_1.sql`
**Objetivo:** Analizar los ingresos por región geográfica y mes del cliente

```sql
SELECT YEAR(f.o_orderdate) AS year,
       MONTH(f.o_orderdate) AS month,
       c.r_name AS REGION,
       SUM(f.o_totalprice) AS net_revenue
FROM FACTORDER f
INNER JOIN DIMCUSTOMER c ON f.o_custkey = c.c_custkey
GROUP BY YEAR(f.o_orderdate), MONTH(f.o_orderdate), REGION
ORDER BY year, month, region
LIMIT 10;
```

**Resultado:** Ver `question_1.csv`

---

### Question 2: Evolución del Revenue Neto

**Archivo:** `question_2.sql`
**Objetivo:** Análisis completo de la evolución temporal del revenue neto por mes y región

```sql
SELECT YEAR(f.o_orderdate) AS year,
       MONTH(f.o_orderdate) AS month,
       c.r_name AS REGION,
       SUM(f.o_totalprice) AS net_revenue
FROM FACTORDER f
INNER JOIN DIMCUSTOMER c ON f.o_custkey = c.c_custkey
GROUP BY YEAR(f.o_orderdate), MONTH(f.o_orderdate), REGION
ORDER BY year, month, region;
```

**Resultado:** Ver `question_2.jpeg`

---

### Question 3: Mix de Producto

**Archivo:** `question_3.sql`
**Objetivo:** Análisis del mix de producto por marca y fabricante (Top 15)

```sql
SELECT p.p_brand,
       p.p_mfgr AS manufacturer,
       SUM(p.l_quantity) AS units_sold,
       SUM(p.L_EXTENDEDPRICE * (1 - p.L_DISCOUNT) * (1 + p.l_tax)) AS net_revenue
FROM DIMLINEITEM AS p
GROUP BY p.p_brand, manufacturer
ORDER BY units_sold DESC
LIMIT 15;
```

**Resultado:** Ver `question_3.jpeg`

---

### Question 4: Efecto del Descuento por Región

**Archivo:** `question_4.sql`
**Objetivo:** Analizar el efecto del descuento por región y su relación con el revenue neto

```sql
SELECT c.r_name AS region,
       AVG(l.l_discount) AS avg_discount,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
FROM DIMLINEITEM l
INNER JOIN FACTORDER o ON l.l_orderkey = o.o_orderkey
INNER JOIN DIMCUSTOMER c ON o.o_custkey = c.c_custkey
GROUP BY c.r_name
ORDER BY avg_discount DESC;
```

**Resultado:** Ver `question_4.jpeg`

---

## Resultados

Los resultados de las consultas analíticas se encuentran en los siguientes archivos:

| Consulta | Archivo de Resultado | Formato |
|----------|---------------------|---------|
| Question 1 | question_1.csv | CSV |
| Question 2 | question_2.jpeg | Imagen |
| Question 3 | question_3.jpeg | Imagen |
| Question 4 | question_4.jpeg | Imagen |


---

## Tecnologías Utilizadas

- **Base de datos:** Snowflake
- **Dataset:** TPCH_SF1000 (Snowflake Sample Data)
- **Modelado:** Star Schema (Esquema Estrella)
- **Diagramación:** draw.io
