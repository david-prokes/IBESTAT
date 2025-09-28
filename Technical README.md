\# Entorno de trabajo: Python y R



Este entorno está configurado para trabajar con Python 3.13.3, R 4.5.0 y Visual Studio Code, integrando todas las herramientas necesarias para un flujo de trabajo profesional y reproducible.



---



\## 📦 Requisitos del entorno



\- Python: \[Descargar Python 3.13.3](https://www.python.org/downloads/)

\- R: \[Descargar R 4.5.0](https://cran.r-project.org/)

\- Visual Studio Code: \[Descargar VS Code](https://code.visualstudio.com/download)

\- Miniforge (gestor de entornos recomendado): \[Miniforge Conda - lightweight environment manager](https://github.com/conda-forge/miniforge?tab=readme-ov-file)



> ⚠️ Se recomienda usar la consola dedicada de \*\*Miniforge Prompt\*\* para gestionar entornos con `conda`, especialmente si deseas evitar configuraciones adicionales en terminales estándar de Windows.



> ⚠️ Para cambiar a la unidad de trabajo (ya que generalmente se empieza en `C:`) en consola desde Miniforge Prompt e ir al directorio de trabajo:



```bash

G:

cd G:\\Enquestes\\Privat\\DAVID

```



---



\## 🛠️ Configuración del entorno Conda (Miniforge Prompt)



1\. Crear entorno virtual con dependencias necesarias (solo la primera vez):



```bash

conda create -n ibestat python=3.13.3

conda activate ibestat

G:

cd G:\\Enquestes\\Privat\\DAVID

pip install -r requirements.txt

```



2\. Activar el entorno (siempre que trabajes desde consola):



```bash

conda activate ibestat

```



---



\## 🧠 Vincular el entorno a Jupyter Notebook en VS Code



1\. Abre tu archivo `.ipynb` en VS Code.  

2\. Haz clic en la parte superior donde aparece \*\*Select Kernel\*\*.  

3\. Elige el entorno \*\*Python 3.13.3 ('ibestat')\*\*.



Si no aparece, puedes registrarlo con:



```bash

python -m ipykernel install --user --name=ibestat

```



---



\# 🔁 Flujo de trabajo: Proyección de SUTs para IBESTAT



El proceso completo de proyección de las Tablas de Oferta y Utilización (SUTs) para IBESTAT está dividido en varias fases interconectadas, combinando scripts en \*\*SAS\*\* y \*\*Python\*\* para garantizar precisión y trazabilidad en cada paso.



---



\## 🧾 1. Extracción de datos desde SAS



\- Se realizan las \*\*consultas SQL desde SAS\*\* para extraer las matrices necesarias en formato tabular.

\- El script utilizado es `SUT-RAS-INE-DATA`, contenido en el proyecto SAS `SUT-RAS.egp`.

\- Las tablas generadas se exportan a la carpeta:



```

Data\\IBESTAT\_2014

```



\*\*Nomenclatura esperada:\*\*



| Tipo de archivo        | Ejemplo           | Significado                                 |

|------------------------|-------------------|---------------------------------------------|

| Año base               | `b2014\_PROD.csv`  | `b` = base year, `2014` = año base          |

| Año proyectado (target)| `d2015\_TPROD.csv` | `d` = datos target, `T` = target             |



---



\## 📓 2. Preparación de datos en Python



Se realiza desde el notebook:



```

data\_preparation.ipynb

```



\### ⚙️ 2.1 DATA TREATMENT



\- \*\*Carga del año base\*\*:  

&nbsp; Se usa `load\_and\_export\_SUTS()` para generar los archivos `TO.csv` (tabla de oferta) y `TD.csv` (tabla de destino).



\- \*\*Ajuste manual en Excel\*\*:  

&nbsp; Se copian los datos en un archivo `SUT 2014.xlsx` y se ajustan los desbalances entre oferta y demanda según este orden de prioridad, si no hay nulos:



```

MARG > IMPU > IMPOR > Industrias de PROD

```



\- \*\*Extracción de tablas corregidas\*\*:  

&nbsp; Se ejecuta `load\_and\_export\_tabs()` para exportar las matrices corregidas y sobrescribir las versiones originales.



\- \*\*Carga de datos proyectados (target)\*\*:  

&nbsp; La función `load\_and\_export\_targets()` importa los datos proyectados, asegurando que:



&nbsp; - `TMARG` sea cero.

&nbsp; - Las categorías de demanda final estén renombradas como `F1`, `F2`, ..., `Fn`.

&nbsp; - Cualquier descuadre entre oferta y demanda totales se redistribuya en `IMPOR`.



---



\## 📐 3. Proyección con SAS (INE Macro)



Desde el proyecto SAS:



1\. Importar las tablas corregidas.

2\. Ejecutar `Macro\_SUT\_RAS` (adaptada con tolerancia e iteraciones).

3\. Ejecutar `SUT-RAS-INE-EXECUTION` para cada año proyectado, generando los siguientes archivos:



```

DATA1.csv, DATA2.csv, ..., en este orden habitual:

PROD, IMPOR, MARG, IMPU, CI, DEMF

```



---



\## 🧪 4. Evaluación en Python



\### ⚙️ 2.2 EVALUATION



1\. \*\*Reconstrucción de TO y TD\*\* proyectadas desde los archivos `DATA\*.csv` generados por SAS.



2\. \*\*Ajuste en Excel del año proyectado\*\* (`SUT 2015.xlsx`, por ejemplo), usando el mismo criterio que en el año base.



3\. \*\*Carga final en Python\*\* con `load\_and\_export\_projected\_tabs()`.



4\. \*\*Aplicación de métricas de evaluación\*\* estructural, que generan los siguientes archivos:



| Archivo generado                            | Descripción                                      |

|---------------------------------------------|--------------------------------------------------|

| `structural\_metrics.csv`                    | Índices de Theil y métricas de ajuste            |

| `cosine\_similarity\_products.csv`            | Similitud coseno por productos                   |

| `cosine\_similarity\_industries.csv`          | Similitud coseno por industrias                  |

| `cosine\_similarity\_products\_describe.csv`   | Estadísticos resumen por productos               |

| `cosine\_similarity\_industries\_describe.csv` | Estadísticos resumen por industrias              |



---



\## 📊 5. Resultados finales



En la carpeta `Results` se realiza el procesamiento final:



\- \*\*Cálculo de las IOTs\*\* por industrias y por productos (Modelos B y D).

\- \*\*Ajuste de precios\*\* de adquisición a precios básicos.



