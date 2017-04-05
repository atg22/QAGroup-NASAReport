# QAGroup-NASAReport
Código en R para la generación de un informe sobre datos de NASA (https://data.nasa.gov/developer y https://api.nasa.gov/api.html) en formato Powerpoint (mediante el uso del paquete ReporteRS).


## Ejecución del código:

### Desde RStudio:

#### Entorno Windows:
1) Comprobar el path absoluto del directorio donde nos hemos descargado este repositorio, por ejemplo:
```
C:\Users\user1\Documents\QAGroup-NASAReport
```

2) En src/Universe.R, dar valor a la variable default_working_directory con el directorio del paso1:

```
default_working_directory <- "C:/Users/user1/Documents/QAGroup-NASAReport"
```
OJO!! las barras del path son en esta dirección "/"


3) Lanzar el código


4) El informe quedará almacenado en:
```
C:/Users/user1/Documents/QAGroup-NASAReport/out
```


#### Entorno Linux:
1) Comprobar el path absoluto del directorio donde nos hemos descargado este repositorio, por ejemplo:
```
/home/user1/QAGroup-NASAReport
```


2) En src/Universe.R, dar valor a la variable default_working_directory con el directorio del paso1:

```
default_working_directory <- "/home/user1/QAGroup-NASAReport"
```

3) Lanzar el código


4) El informe quedará almacenado en:
```
/home/user1/QAGroup-NASAReport/out
```


### Desde línea de comandos:

#### Entorno Windows:
Siendo:
- R_Script_command="C:\Program Files\R\R-3.2.3\bin\x64\RScript"

(depende del directorio de instalación de R en tu ordenador, comprobarlo y cambiarlo si es necesario)

- R_Script="C:\Users\user1\Documents\QAGroup-NASAReport\src\Universe.R"

(habiendo elegido "C:\Users\user1\Documents\QAGroup-NASAReport" como directorio donde hemos descargado el contenido del repositorio)


Se puede lanzar con:
```
set R_Script_command="C:\Program Files\R\R-3.2.3\bin\x64\RScript"
set R_Script="C:\Users\user1\Documents\QAGroup-NASAReport\src\Universe.R"
%R_Script_command% %R_Script% -w C:\Users\user1\Documents\QAGroup-NASAReport
```
Además, se pueden incluir las líneas anteriores en un .bat y lanzar únicamente ese .bat desde la línea de comandos.

El informe quedará almacenado en:
```
C:/Users/user1/Documents/QAGroup-NASAReport/out
```


#### Entorno Linux:
Habiendo elegido "/home/user1/QAGroup-NASAReport" como directorio donde hemos descargado el contenido del repositorio)


Se puede lanzar con:
```
Rscript "/home/user1/QAGroup-NASAReport/src/Universe.R" -w "/home/user1/QAGroup-NASAReport"
```

El informe quedará almacenado en:
```
/home/user1/QAGroup-NASAReport/out
```



