# ejercicio_en_clase_1

## Integrantes
- Anthony Fajardo  
- Gabriela Coloma  
- Mateo Vivanco  
- Sebastian Encalada  
- Luis Eduardo Zaldumbide  

---

## Contexto
Este proyecto utiliza el dataset **TPCH_SF1000** disponible en Snowflake.  
Se asume que los datos fuente ya se encuentran **limpios y curados (Silver Layer)**, por lo que el alcance del trabajo se centra exclusivamente en el **diseño e implementación de la capa GOLD**, orientada a análisis analítico y de negocio.

El diseño de la capa GOLD se realizó siguiendo un enfoque **bottom-up**, partiendo de las **preguntas de negocio** que debían ser respondidas, y no desde una reproducción completa del modelo relacional original.  
Este enfoque permitió seleccionar únicamente las entidades necesarias para satisfacer los requerimientos analíticos, evitando complejidad innecesaria y priorizando claridad, rendimiento y alineación con el análisis requerido.

---

## Proceso de selección del modelo dimensional

### 1. Identificación del nivel de análisis (grain)
Las preguntas de negocio requieren analizar métricas de ventas, descuentos, producto y tiempos de despacho a nivel detallado.  
Por esta razón, se definió como granularidad:

> **1 fila por línea de orden**, representada mediante `lineitem_id`.

Este nivel de detalle permite:
- Analizar revenue neto
- Evaluar descuentos
- Estudiar mix de producto
- Medir desempeño logístico

---

### 2. Identificación de la tabla de hechos
A partir del análisis del modelo TPCH, se determinó que la información central de negocio se obtiene de la relación entre:

- `LINEITEM` (detalle transaccional)
- `ORDERS` (fecha de orden y cliente)

Como resultado, se definió la tabla de hechos **FactOrder**, la cual:
- Representa cada línea de orden
- Contiene métricas de revenue
- Se relaciona con cliente y producto/logística

---

### 3. Análisis de las preguntas de negocio
Las preguntas solicitadas se agrupan en los siguientes ejes analíticos:

- Ingresos por región y mes del cliente
- Evolución temporal del revenue neto
- Top clientes
- Mix de producto
- Desempeño logístico

A partir de este análisis se determinó que **toda la información necesaria** podía organizarse eficientemente en **una tabla de hechos y dos dimensiones**, sin necesidad de replicar la normalización completa del modelo original.

---

## Gold Layer – Star Schema

### Fact Table
### **FactOrder**

**Grain (Granularidad):**  
> 1 fila representa **una línea de orden**, identificada por `lineitem_id`, asociada a un cliente.

**Campos principales:**
- **PK:** mezcla  
- **FK:** customer_id  
- **FK:** lineitem_id  
- O_ORDERDATE  
- O_TOTALPRICE  

Esta tabla concentra las métricas de negocio y actúa como el núcleo analítico del modelo.

---

## Dimensiones Utilizadas

Para este modelo se decidió utilizar **dos dimensiones**, las cuales concentran toda la información necesaria para responder las consultas planteadas.

---

### **DimCustomer**
La dimensión **DimCustomer** centraliza la información del cliente y su contexto comercial y geográfico.

**Incluye:**
- customer_id (PK)
- C_NAME
- N_NAME (nación)
- R_NAME (región)

**Justificación:**
Aunque el modelo original separa `CUSTOMER`, `NATION` y `REGION`, en la capa GOLD esta información se conceptualiza como **un único contexto del cliente**, ya que las consultas analíticas se enfocan en:
- El cliente como entidad de negocio
- Su ubicación regional para análisis de revenue

**Permite responder:**
- Ingresos por región y mes
- Evolución del revenue por región del cliente
- Top clientes por revenue neto

---

### **DimLineItem**
La dimensión **DimLineItem** concentra la información operativa, logística y de producto asociada a cada línea de orden.

**Incluye:**
- lineitem_id (PK)
- L_SHIPDATE
- L_SHIPMODE
- P_BRAND
- P_MFGR
- L_DISCOUNT

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

## Enfoque del modelo
El resultado es un **esquema estrella simplificado**, diseñado específicamente para análisis de negocio:

- La tabla de hechos concentra métricas y fechas clave
- Las dimensiones encapsulan contexto analítico relevante
- Se reduce la complejidad estructural sin sacrificar capacidad analítica

Este enfoque permite responder eficientemente las preguntas planteadas, manteniendo el modelo claro, coherente y alineado con los objetivos del ejercicio.

---

## Consultas Analíticas (Business Queries)

Las consultas implementadas permiten responder:

1. **Ingresos por región y mes (cliente)**  
2. **Evolución del revenue neto por mes y región del cliente**  
3. **Top 10 clientes por revenue neto en un año específico**  
4. **Mix de producto por brand y manufacturer**  
5. **Efecto del descuento por región y su relación con el revenue neto**  
6. **Desempeño logístico por ship mode y volumen despachado**

---

## Diagrama
El diagrama fue elaborado en **draw.io** y exportado como imagen (PNG/PDF).  
Incluye:
- La capa GOLD
- El esquema estrella
- La granularidad del hecho
- Las dimensiones y sus relaciones
