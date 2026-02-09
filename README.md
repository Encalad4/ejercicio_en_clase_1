# ejercicio_en_clase_1
## Contexto
Este proyecto utiliza el dataset **TPCH_SF1000** disponible en Snowflake.  
Se asume que los datos fuente ya se encuentran **limpios y curados (Silver Layer)**, por lo que el alcance del trabajo se centra exclusivamente en el **diseño e implementación de la capa GOLD**, orientada a análisis analítico y de negocio.

El diseño de la capa GOLD se realizó siguiendo un enfoque **bottom-up**, partiendo de las **preguntas de negocio** que debían ser respondidas, y no desde una reproducción completa del modelo relacional original.  
Este enfoque permitió seleccionar únicamente las entidades necesarias para satisfacer los requerimientos analíticos, evitando complejidad innecesaria.

---

### Proceso de selección del modelo dimensional

El proceso de modelado se desarrolló en los siguientes pasos:

1. **Identificación del nivel de análisis (grain)**  
   Todas las preguntas de negocio requieren analizar métricas de ventas, descuentos y tiempos de despacho a nivel detallado.  
   Por esta razón, se definió como granularidad:
   
   > **1 fila por línea de orden**, identificada por `(L_ORDERKEY, L_LINENUMBER)`  
   
   lo que corresponde naturalmente a la tabla `LINEITEM`.

2. **Identificación de la tabla de hechos**  
   Dado que `LINEITEM` contiene:
   - Cantidades
   - Precios
   - Descuentos
   - Impuestos
   - Fechas de despacho
   - Modos de envío  
   
   esta tabla fue seleccionada como la base de la **tabla de hechos (`FACT_SALES`)**, siendo enriquecida con atributos de `ORDERS` (fecha de orden y cliente).

3. **Análisis de las preguntas de negocio**  
   Las preguntas solicitadas se agrupan en cinco ejes:
   - Ingresos por región y mes del cliente
   - Evolución temporal del revenue
   - Top clientes
   - Mix de producto
   - Desempeño logístico

   A partir de este análisis se determinó que **toda la información necesaria** podía organizarse en dos dimensiones principales.

---

### Justificación de las dimensiones seleccionadas

#### DIM_CUSTOMER
La dimensión **DIM_CUSTOMER** fue seleccionada para centralizar toda la información relacionada con el cliente y su contexto comercial.

Esta dimensión permite responder directamente:
- Ingresos por región y mes
- Evolución del revenue por región del cliente
- Top clientes por revenue neto

Aunque el modelo original separa `CUSTOMER`, `NATION` y `REGION`, en la capa GOLD esta información se **conceptualiza como un único contexto del cliente**, ya que las consultas analíticas se enfocan en el cliente como entidad de negocio y no en la normalización geográfica.

---

#### FACT_SALES (LINEITEM enriquecido)
La información relacionada con:
- Producto (brand, manufacturer)
- Descuentos
- Fechas de orden y despacho
- Modo de envío
- Volumen y métricas operativas

se mantiene directamente en la **tabla de hechos**, derivada de `LINEITEM` y enriquecida con `ORDERS`.

Este diseño permite:
- Analizar mix de producto sin joins innecesarios
- Evaluar el efecto del descuento directamente sobre el revenue
- Calcular métricas logísticas como tiempos de despacho y volumen movido

---

### Enfoque del modelo
El resultado es un **esquema estrella simplificado**, donde:

- La tabla de hechos concentra las métricas y atributos operativos
- La dimensión de cliente concentra el contexto de análisis comercial
- Se prioriza rendimiento, claridad y alineación con las preguntas de negocio

Este enfoque evita la proliferación de dimensiones que no aportan valor analítico directo y mantiene el modelo alineado con los objetivos del ejercicio.

---
