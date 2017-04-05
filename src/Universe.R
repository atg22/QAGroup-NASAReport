# ------------------------------------------------------
# LIMPIAR LOS OBJETOS DE EJECUCIONES ANTERIORES
# ------------------------------------------------------
rm(list=ls())


# -------------------------------------
# LIBRERIAS
# -------------------------------------
library("optparse")         # Para gestionar los argumentos de entrada al script
library("curl")             # Para descarga de archivos
library("jsonlite")         # Para conexiones api rest
library("ReporteRsjars")    # Para usar ReporteRS y generar informes en pptx, docx...
library("ReporteRs")
library("ggplot2")          # Para generar graficos
library("lubridate")        # Para gestion de fechas
library("ggmap")            # Para dibujar mapas
library("png")              # Para gestion de imagenes
library("grid")


# ------------------------------------------------------
# FUNCION: CONTROL DE ERROR DE ARGUMENTOS
# ------------------------------------------------------
args_err <- function(opt) {
  
  # WORKING_DIRECTORY is mandatory
  if (opt$WORKING_DIRECTORY=="") {
    print("ERROR! WORKING_DIRECTORY argument is mandatory!")
    q()
  }
}



###################################################################################################
# MAIN
###################################################################################################

# ----------------------------------------------------------
# ARGUMENTOS DE ENTRADA AL SCRIPT 
# ----------------------------------------------------------
# (*) Valores por defecto
# - para ejecutar desde RStudio hay que dar un valor a esta variable. Definira el path del working directory
# - para ejecutar con Rscript desde linea de comandos habra que incluir la opcion -w con el working directory
default_working_directory <- "C:/Users/cliente/Documents/SourceTreeReposGITHUB/gr-R_curso_gr"

# (*) Recibir valores
option_list <- list(
  make_option(c("-w", "--WORKING_DIRECTORY"), action="store", default=default_working_directory,
              type="character",
              help=paste("Directorio donde el codigo esta instalado. OBLIGATORIO."))
)
opt <- parse_args(OptionParser(option_list=option_list))
args_err(opt)


# ----------------------------------------------------------
# CAMBIAR EL WORKING DIRECTORY
# ----------------------------------------------------------
setwd(opt$WORKING_DIRECTORY)


# ----------------------------------------------------------
# INCLUIR OTROS FICHEROS CON CODIGO ADICIONAL
# ----------------------------------------------------------
# Fichero con funciones para procesar los datos de entrada
source("src/Universe_process_inputs.R")
# Fichero con funciones varias
source("src/Universe_functions.R")




# --------------------------------------------------------------
# LECTURA Y ALMACENAMIENTO DE LOS DATOS DE ENTRADA
# --------------------------------------------------------------
# Crear el directorio "input" si no existe
dir.create("input", showWarnings=FALSE)

# Llamada a las funciones que conectan con las web de NASA y descargan la info
meteoritos_df <- get_CSV_nasa_meteoritos()
meteoritos_spain_df <- get_spain_meteorites(meteoritos_df)
images_info <- get_API_nasa_Satellite_DC_images()



# --------------------------------------------------------------
# CREACION DEL DOCUMENTO PPTx
# --------------------------------------------------------------
# ReporteRS: Crear el documento pptx
mydoc <- pptx(title="Universe", template="templates/Universe_template.pptx")


#slide.layouts(mydoc) # comprobar nombres de los layouts del template
#slide.layouts(mydoc, <nombre_layout>) # comprobar nombres de los marcadores dentro de un layout



# --------------------------------------------------------------
# PAGINA DE PORTADA
# --------------------------------------------------------------
# (*) Incluir layout:
mydoc <- addSlide(mydoc, "Title")

# (*) Incluir marcador de titulo:
mydoc <- addTitle(mydoc, "INFORME DE DATOS DE LA NASA")

# (*) Incluir marcador de subtitulo:
current_date <- format(Sys.Date(), "%d de %B de %Y")
current_date <- ifelse(grepl("^0", current_date), substring(current_date, 2), current_date)
mydoc <- addSubtitle(mydoc, current_date)


# --------------------------------------------------------------
# PAGINA DE SECCION DE METEORITOS
# --------------------------------------------------------------
# (*) Incluir layout:
mydoc <- addSlide(mydoc, "Section")

# (*) Titulo:
mydoc <- addTitle(mydoc, "Meteoritos")

# (*) Subtitulo:
mydoc <- addSubtitle(mydoc, "\"Pensamos que los meteoritos viven poco. Para nosotros ellos nacen en el momento que empiezan a quemarse.\"")
mydoc <- addParagraph(mydoc, "Valeriu Butulescu, Vivir")



# --------------------------------------------------------------
# METEORITOS - PAGINA DE INFORMACION (TEXTO, LISTAS...)
# --------------------------------------------------------------
# (*) Definir propiedades de los textos:
default_defprop <- textProperties(color="#585858", font.size=22, font.family="Calibri", font.style="italic")
hyperlink_defprop <- chprop(default_defprop, underline=TRUE, font.weight="bold", font.style="italic")  # los colores se cambian en el template (en el Slide Master > cuadro de Background > Colors: Customize colors)
default_textprop <- textProperties(color="#0B0B3B", font.size=20, font.family="Calibri")

# (*) Crear el parrafo
# - Definicion:
def <- pot("Un ", default_defprop) +
  pot("meteorito ", chprop(default_defprop, font.weight="bold")) +
  pot("es un ", default_defprop) +
  pot("meteoroide ", hyperlink="https://es.wikipedia.org/wiki/Meteoroide", hyperlink_defprop) +
  pot("que alcanza la superficie de un planeta debido a que no se desintegra por completo en la atm\u00F3sfera. La luminosidad dejada al desintegrarse se denomina ", default_defprop) +
  pot("meteoro.", hyperlink="https://es.wikipedia.org/wiki/Meteoro_(astronom%C3%ADa)", hyperlink_defprop)

# - Informacion general de la base de datos utilizada
met_lastyear <- max(as.numeric(meteoritos_df[meteoritos_df$year<=format(Sys.Date(), "%Y") &
                                               !is.na(meteoritos_df$year) &
                                               meteoritos_df$year!="", ]$year))
text1 <- pot("\nLos datos usados en este an\u00E1lisis han sido proporcionados por ", default_textprop) +
  pot("NASA", chprop(default_textprop, font.weight="bold")) +
  pot(" y son gestionados por ", default_textprop) +
  pot("The Meteoritical Society", chprop(default_textprop, font.weight="bold")) +
  pot(paste(". Recogen informaci\u00F3n sobre los meteoritos ca\u00EDdos o encontrados hasta ", met_lastyear, ".", sep=""), default_textprop)

# - Numero total de meteoritos registrados
met_num <- nrow(meteoritos_df)
list1 <- pot( paste("N\u00FAmero total de meteoritos: ", met_num, ".", sep=""), default_textprop)

# - Meteorito mas pesado
met_heaviest <- meteoritos_df[!is.na(meteoritos_df$mass..g.) & meteoritos_df$mass..g.==max(meteoritos_df[!is.na(meteoritos_df$mass..g.), ]$mass..g.), ]
met_heaviest_geoloc_df <- get_location_from_geolocation(met_heaviest$reclat, met_heaviest$reclong)
met_heaviest_geoloc <- paste(met_heaviest_geoloc_df[met_heaviest_geoloc_df$types=="c(\"administrative_area_level_1\", \"political\")", ]$long_name,
                             " (",
                             met_heaviest_geoloc_df[met_heaviest_geoloc_df$types=="c(\"country\", \"political\")", ]$long_name,
                             ")", sep="")

list2 <- pot(paste("El meteorito m\u00E1s pesado que ha ca\u00EDdo sobre la superficie de la Tierra se llama ",
                   met_heaviest$name, ". Cay\u00F3 en ", met_heaviest_geoloc, " en el a\u00F1o ", met_heaviest$year,
                   ". Pesa ", met_heaviest$mass..g./1000, " kg. y est\u00E1 compuesto principalmente de ", met_heaviest$recclass,
                   ".", sep=""), default_textprop)

# - Ultimo anio con caidas de meteoritos registradas
met_fell_lastyear <- max(as.numeric(meteoritos_df[meteoritos_df$year<=format(Sys.Date(), "%Y") &
                                                    !is.na(meteoritos_df$year) &
                                                    meteoritos_df$year!="" &
                                                    meteoritos_df$fall=="Fell", ]$year))
met_fell_lastyear_df <- meteoritos_df[meteoritos_df$year==met_fell_lastyear & meteoritos_df$fall=="Fell", ]
list3 <- pot(paste("El \u00FAltimo a\u00F1o registrado con ca\u00EDdas de meteoritos fue ", met_fell_lastyear, ". ",
                   ifelse(nrow(met_fell_lastyear_df)==1, "\u00DAnicamente cay\u00F3 un meteorito:", paste("Cayeron", nrow(met_fell_lastyear_df), "meteoritos:")),
                   sep=""), default_textprop)

for (i in 1:nrow(met_fell_lastyear_df)) {
  met <- met_fell_lastyear_df[i,]
  
  met_geoloc_df <- get_location_from_geolocation(met$reclat, met$reclong)
  met_geoloc <- paste(met_geoloc_df[met_geoloc_df$types=="c(\"administrative_area_level_1\", \"political\")", ]$long_name,
                      " (",
                      met_geoloc_df[met_geoloc_df$types=="c(\"country\", \"political\")", ]$long_name,
                      ")", sep="")
  
  list31_pot <- pot(paste("Meteorito '", met$name, "', con ", met$mass..g./1000, " kg. de peso y ca\u00EDdo sobre ", met_geoloc, sep=""),
                    default_textprop)
  if (i==1) { list31 <- list31_pot }
  else { list31 <- c(list31, list31_pot) }
}


# - Ultimo anio con caidas de meteoritos registradas en Espana
met_sp_lastyear <- max(meteoritos_spain_df[meteoritos_spain_df$year<=format(Sys.Date(), "%Y") & meteoritos_spain_df$fall=="Fell", ]$year)
met_sp_lastyear_df <- meteoritos_spain_df[meteoritos_spain_df$year==met_sp_lastyear & meteoritos_spain_df$fall=="Fell", ]
list4 <- pot(paste("El \u00FAltimo a\u00F1o con ca\u00EDdas de meteoritos en Espa\u00F1a fue ", met_sp_lastyear, ". ",
                   ifelse(nrow(met_sp_lastyear_df)==1, "\u00DAnicamente cay\u00F3 un meteorito:", paste("Cayeron", nrow(met_sp_lastyear_df), "meteoritos:")),
                   sep=""), default_textprop)

for (i in 1:nrow(met_sp_lastyear_df)) {
  met_sp <- met_sp_lastyear_df[i,]
  
  met_sp_geoloc_df <- get_location_from_geolocation(met_sp$reclat, met_sp$reclong)
  met_sp_geoloc <- paste( met_sp_geoloc_df[met_sp_geoloc_df$types=="c(\"locality\", \"political\")", ]$long_name,
                          ", ",
                          met_sp_geoloc_df[met_sp_geoloc_df$types=="c(\"administrative_area_level_1\", \"political\")", ]$long_name,
                          sep="")
  
  list41_pot <- pot(paste("Meteorito '", met_sp$name, "', con ", met_sp$mass..g./1000, " kg. de peso y ca\u00EDdo sobre ", met_sp_geoloc, sep=""),
                    default_textprop)
  if (i==1) { list41 <- list41_pot }
  else { list41 <- c(list41, list41_pot) }
}

# (*) DIAPOSITIVA: Se incluye en la PPTX toda la informacion calculada previamente
mydoc <- addSlide(mydoc, "Title and Content")
mydoc <- addTitle(mydoc, "Meteoritos, ¿Qu\u00E9 son?")
mydoc <- addParagraph(mydoc, def)
mydoc <- addParagraph(mydoc, text1, append=TRUE)
mydoc <- addParagraph(mydoc, list1, append=TRUE,
                      par.properties=parProperties(list.style="unordered", level=1))
mydoc <- addParagraph(mydoc, list2, append=TRUE,
                      par.properties=parProperties(list.style="unordered", level=1))
mydoc <- addParagraph(mydoc, list3, append=TRUE,
                      par.properties=parProperties(list.style="unordered", level=1))
mydoc <- addParagraph(mydoc, list31, append=TRUE,
                      par.properties=parProperties(list.style="unordered", level=2))
mydoc <- addParagraph(mydoc, list4, append=TRUE,
                      par.properties=parProperties(list.style="unordered", level=1))
mydoc <- addParagraph(mydoc, list41, append=TRUE,
                      par.properties=parProperties(list.style="unordered", level=2))

# - Pie de pagina:
mydoc <- addFooter(mydoc, "Datos proporcionados por 'NASA's Data Portal' (https://data.nasa.gov/)")
mydoc <- addDate(mydoc, format(Sys.Date(), "%d-%m-%Y"))
mydoc <- addPageNumber(mydoc)



# --------------------------------------------------------------
# METEORITOS - PAGINA DE METEORITOS EN LOS ULTIMOS 'X' ANIOS
# --------------------------------------------------------------

# (*) Data:
# - seleccionar el numero de anios a analizar
lastyears_num <- 50

# - Filtrar informacion de esos ultimos anios
lastyears_df <- meteoritos_df[ meteoritos_df$year>=met_lastyear-lastyears_num & 
                                 meteoritos_df$year<=met_lastyear, ]

# - seleccionar unicamente las columnas que usaremos
lastyears_df <- lastyears_df[, c("name", "mass..g.", "fall", "year")]

# - Construir el dataframe solo de meteoritos que se hayan visto caer 
lastyears_fell_df <- lastyears_df[lastyears_df$fall=="Fell", ]

# - Incluir nueva columna para catalogar el peso: Menos de 1kg. / De 1kg a 10kg / De 10kg a 100kg / Mas de 100kg
lastyears_fell_df$mass..class. <- ifelse(is.na(lastyears_fell_df$mass..g.) | lastyears_fell_df$mass..g.=="", "Sin masa registrada",
                                         ifelse(as.numeric(lastyears_fell_df$mass..g.)>=100000, "M\u00E1s de 100kg.",
                                                ifelse(as.numeric(lastyears_fell_df$mass..g.)>=10000 & as.numeric(lastyears_fell_df$mass..g.)<100000, "De 10kg. a 100kg.",
                                                       ifelse(as.numeric(lastyears_fell_df$mass..g.)>=1000 & as.numeric(lastyears_fell_df$mass..g.)<10000, "De 1kg. a 10kg.",
                                                              "Menos de 1kg."))))
lastyears_fell_df$mass..class. <- factor(lastyears_fell_df$mass..class., levels=c("Sin masa registrada", "Menos de 1kg.", "De 1kg. a 10kg.", "De 10kg. a 100kg.", "M\u00E1s de 100kg."))

# - Incluir secuencia numerica agrupando por anio (se diferencia por name). 
#   Previamente se ordena por anio y masa para que luego se pinten los puntos por anio y de menos a mas masa
lastyears_fell_df <- lastyears_fell_df[order(lastyears_fell_df$year, lastyears_fell_df$mass..class., decreasing=FALSE), ]
lastyears_fell_df$num <- ave(lastyears_fell_df$name, lastyears_fell_df$year, FUN=seq_along)

# - Incluir una nueva columna con el texto del eje del grafico: 'anio (nº meteoritos vistos en ese anio)'
lastyears_fell_df$yearnum <- paste(lastyears_fell_df$year, " (", 
                                   tapply(as.numeric(lastyears_fell_df$num), lastyears_fell_df$year, max)[lastyears_fell_df$year],
                                   ")", sep="")

# - Incluir filas 'falsas' para anios en los que no cayeron meteoritos (queremos que aparezcan pero sin valores)
for (year in seq(met_lastyear-lastyears_num, met_lastyear)) {
  if (nrow(lastyears_fell_df[lastyears_fell_df$year==year, ])==0) {
    lastyears_fell_df <- rbind(lastyears_fell_df, c("none", "none", "Fell", year, "Sin masa registrada", -1, paste(year, " (0)", sep="")))
  }
}



# (*) Texto principal:
# - Definir propiedades para el texto:
default_textprop <- textProperties(color="#0B0B3B", font.size=20, font.family="Calibri")
# - Crear el texto
main_text <- pot("De los ", default_textprop) +
  pot(nrow(lastyears_df), chprop(default_textprop, font.weight="bold")) +
  pot(" meteoritos registrados en los \u00FAltimos ", default_textprop) + 
  pot(lastyears_num, chprop(default_textprop, font.weight="bold")) +
  pot(paste(" a\u00F1os hasta ", met_lastyear, ", \u00FAnicamente se han visto caer ", sep=""), default_textprop) +
  pot(nrow(lastyears_fell_df), chprop(default_textprop, font.weight="bold")) +
  pot(".", default_textprop)


# (*) Grafico de 'caidos'
# - Crear grafico de puntos unidos hacia abajo
lastyears_fell_plot <- ggplot(lastyears_fell_df, aes(x=yearnum, y=-1*(as.numeric(num)))) + 
  geom_point(aes(color=mass..class.), size=2)

# - Configuracion de la leyenda y colores de los puntos
lastyears_fell_plot <- lastyears_fell_plot + theme(legend.position="right",
                                                   legend.background=element_blank(),
                                                   legend.key=element_blank(),
                                                   legend.title=element_text(size=10, face="bold"),
                                                   legend.text=element_text(size=10))
lastyears_fell_plot <- lastyears_fell_plot + scale_color_manual(paste("Peso de los ", nrow(lastyears_fell_df), " meteoritos", sep=""),
                                                                values=c("#FFFF00", "#FFBF00", "#FF8000", "#FF4000", "#FF0000"))

# - Configuracion de los ejes: eliminar nombres, lineas, textos del eje Y y ticks de ambos ejes
lastyears_fell_plot <- lastyears_fell_plot + theme(axis.title=element_blank(),
                                                   axis.line=element_blank(),
                                                   axis.text.y=element_blank(),
                                                   axis.ticks=element_blank())
# - Configuracion del plot: eliminar margenes del grafico
lastyears_fell_plot <- lastyears_fell_plot + theme(plot.background=element_blank(),
                                                   plot.margin=unit(c(0,0,0,0), "cm"))
# - Configuracion del panel: eliminar color de fondo
lastyears_fell_plot <- lastyears_fell_plot + theme(panel.background=element_blank(),
                                                   panel.margin=unit(c(0,0,0,0), "cm"),
                                                   panel.grid=element_blank())


# - Formato de los textos del eje X: 
# --- tamanio del texto para que quepa y no se superponga sobre el eje
# --- cambiar angulo de los textos del eje X para que al hacerlo circular se visualicen correctamente
lastyears_fell_plot <- lastyears_fell_plot + theme(axis.text.x=element_text(size=8.5,
                                                                            angle= 360/(2*pi) * rev( pi/2 + seq(pi/lastyears_num, 2*pi-pi/lastyears_num, len=lastyears_num))))

# - Dejar espacio abajo para que quede espacio en el centro al construir el circulo
lastyears_fell_plot <- lastyears_fell_plot + scale_y_continuous(limits=c(-1*max(as.numeric(lastyears_fell_df$num))-10, 0))

# - Construir el grafico circular
lastyears_fell_plot <- lastyears_fell_plot + coord_polar()



# (*) Texto sobre el meteorito 'Chelyabinsk':
# - data
chelyabinsk <- meteoritos_df[meteoritos_df$name=="Chelyabinsk", ]
chelyabinsk_geoloc_df <- get_location_from_geolocation(chelyabinsk$reclat, chelyabinsk$reclong)
chelyabinsk_geoloc <- chelyabinsk_geoloc_df[chelyabinsk_geoloc_df$types=="c(\"country\", \"political\")", ]$long_name
# - definir propiedades para el texto:
chelyabinsk_textprop <- textProperties(color="#0B0B3B", font.size=18, font.family="Calibri", font.style="italic")
# - texto
chelyabinsk_text <- pot(paste("En ", chelyabinsk$year, " el meteorito 'Chelyabinsk', con ",
                              as.numeric(chelyabinsk$mass..g.)/1000, " kg. de peso cayó sobre ",
                              chelyabinsk_geoloc, ". Estas son algunas de las grabaciones que se conservan:", sep=""),
                        chelyabinsk_textprop)

# (*) Texto del link a youtube con los vídeos de 'Chelyabinsk':
# - definir propiedades para el texto:
chelyabinsk_youtubeprop <- textProperties(color="#0B0B3B", font.size=16, font.family="Calibri")
# - texto
chelyabinsk_youtubetext <- pot("Para ver los v\u00EDdeos en YouTube hacer clik ", chelyabinsk_youtubeprop) + 
  pot("aqu\u00ED", hyperlink="https://www.youtube.com/results?search_query=Chelyabinsk+meteor", chelyabinsk_youtubeprop)



# (*) DIAPOSITIVA: Se incluye en la PPTX toda la informacion calculada previamente
mydoc <- addSlide(mydoc, "Content and Multimedia")
mydoc <- addTitle(mydoc, paste("Meteoritos en los \u00FAltimos ", lastyears_num, " a\u00F1os hasta ", met_lastyear, sep=""))
mydoc <- addParagraph(mydoc, main_text)
mydoc <- addPlot(mydoc, fun = function() print(lastyears_fell_plot), vector.graphic=FALSE)
mydoc <- addImage(mydoc, "images/earth.png")
mydoc <- addParagraph(mydoc, chelyabinsk_text)
mydoc <- addImage(mydoc, "images/Chelyabinsk.jpg")
mydoc <- addImage(mydoc, "images/YouTube_icon.png")
mydoc <- addParagraph(mydoc, chelyabinsk_youtubetext)


# Pie de pagina:
mydoc <- addFooter(mydoc, "Gr\u00E1fico basado en la idea de Tiffany Farrant (http://www.tiffanyfarrant.com/work/#/meteorites/)")
mydoc <- addDate(mydoc, format(Sys.Date(), "%d-%m-%Y"))
mydoc <- addPageNumber(mydoc)


# --------------------------------------------------------------
# METEORITOS - PAGINA DE ESPANIA (MAPA Y TABLA)
# --------------------------------------------------------------
# (*) Numerar los meteoritos segun el anio de caida/encontrado
map_df <- meteoritos_spain_df[order(meteoritos_spain_df$year, decreasing=TRUE), ]
map_df["year_number"] <- seq(1, nrow(map_df))

# (*) Crear mapa
map <- get_map(location="Spain", zoom=6, maptype="terrain")
my_map <- ggmap(map, extent="device", legend="topright")

# (*) Pintar el punto donde cayo o se encontro cada meteorito
my_map <- my_map + geom_point(data=map_df,
                              aes(x=as.numeric(reclong), y=as.numeric(reclat), color=fall),
                              shape=21, size=5, fill="white", stroke=1.5,
                              alpha=1)

# (*) Incluir el número de cada meteorito en el interior del punto
my_map <- my_map + geom_text(data=map_df,
                             aes(x=as.numeric(reclong), y=as.numeric(reclat),
                                 label=year_number, hjust=0.5, vjust=0.5),
                             size=3)

# (*) Cambiar la leyenda de idioma
map_df$fall <- factor(map_df$fall, levels=c("Fell", "Found"))
my_map <- my_map + scale_colour_discrete("Tipo de hallazgo", labels=c("Ca\u00EDdo","Encontrado"))
# (*) Dar formato a la leyenda
my_map <- my_map + theme(legend.background=element_rect(size=1, color="#969696", fill="#FAFAFA"),
                         legend.key=element_rect(color="#FAFAFA", fill="#FAFAFA"), # same color as background make it transparent
                         legend.title=element_text(size=10, face="bold"),
                         legend.text=element_text(size=10),
                         plot.title=element_text(size=12, face="bold"))


# (*) Crear tabla
# - Data
ft_df <- meteoritos_spain_df[order(meteoritos_spain_df$year, decreasing=TRUE), ]
ft_df["year_number"] <- seq(1, nrow(ft_df))
ft_df <- head(ft_df[, c("year_number", "year", "fall", "name", "locality", "area")],10)
ft_df[ft_df$fall=="Fell", ]$fall <- "Ca\u00EDdo"
ft_df[ft_df$fall=="Found", ]$fall <- "Encontrado"
names(ft_df) <- c("ID", "Fecha", "Tipo de hallazgo", "Nombre", "Localidad", "Area")


# - Generar las propiedades 'base' de texto/parrafo/celda para celdas normales (body) y cabecera (header)
base_text_body <- textProperties(font.family="Calibri", font.size=12, color="black")
base_par_body <- parProperties(text.align="center")
base_text_header <- textProperties(font.family="Calibri", font.size=14, color="white", font.weight="bold")
base_par_header <- parProperties(text.align="center")
base_cell <- cellProperties(vertical.align ='middle', border.color="white", padding.top=1, padding.bottom=1)

# - Crear la tabla en base a las propiedades anteriores
my_ft <- FlexTable(data=ft_df,
                   header.columns=TRUE,
                   header.text.props=base_text_header,
                   header.par.props=base_par_header,
                   header.cell.props=chprop(base_cell, background.color="#969696"),
                   body.text.props=base_text_body,
                   body.par.props= base_par_body,
                   body.cell.props=base_cell)

# - Incluir propiedades de los bordes
my_ft <- setFlexTableBorders( my_ft,
                              inner.vertical=borderProperties(width=0),
                              inner.horizontal=borderProperties(width=0),
                              outer.vertical=borderProperties(style="solid", width=1, color="#969696"),
                              outer.horizontal=borderProperties(style="solid", width=1, color="#969696"))


# - Incluir Zebra Style
my_ft <- setZebraStyle(my_ft, odd="#EBEBEB", even="white")


# - Cambiar la anchura de las columnas (unidad: pulgadas)
my_ft <- setFlexTableWidths(my_ft, widths=c(0.5, 0.5, 1.25, 1.8, 1.8, 1.8))

# - Cambiar las propiedades de texto para algunas celdas
my_ft[,1] <- chprop(base_text_body, font.weight="bold")



# (*) DIAPOSITIVA: Se incluye en la PPTX toda la informacion calculada previamente
mydoc <- addSlide(mydoc, "Title and Content with table")
mydoc <- addTitle(mydoc, paste("Meteoritos registrados en Espa\u00F1a hasta ", met_lastyear))
mydoc <- addPlot(mydoc, fun = function() print(my_map), vector.graphic=FALSE)
mydoc <- addFlexTable(mydoc, my_ft)
mydoc <- addParagraph(mydoc, "Top 10 de meteoritos espa\u00F1oles m\u00E1s actuales")

# - Pie de pagina:
mydoc <- addFooter(mydoc, "Datos proporcionados por 'NASA's Data Portal' (https://data.nasa.gov/)")
mydoc <- addDate(mydoc, format(Sys.Date(), "%d-%m-%Y"))
mydoc <- addPageNumber(mydoc)



# --------------------------------------------------------------
# PAGINA DE SECCION DE SATELITES
# --------------------------------------------------------------
# (*) Incluir layout:
mydoc <- addSlide(mydoc, "Section")

# (*) Titulo:
mydoc <- addTitle(mydoc, "Sat\u00E9lites")

# (*) Subtitulo:
mydoc <- addSubtitle(mydoc, "\"Seg\u00FAn la NASA, hay unos 5.600 sat\u00E9lites artificiales que giran alrededor de nuestro planeta, pero apunta que solamente unos 800 permanecen en activo.\"")
mydoc <- addParagraph(mydoc, pot("¿Cu\u00E1ntos artefactos est\u00E1n orbitando la Tierra a la vez?", hyperlink="http://www.quo.es/tecnologia/cuantos-artefactos-estan-orbitando-la-tierra-a-la-vez") +
                        pot(", QUO.es, 21/09/2015"))


# --------------------------------------------------------------
# IMAGEN SATELITAL
# --------------------------------------------------------------
# (*) Incluir layout:
mydoc <- addSlide(mydoc, "Two Contents with headers")

# (*) Titulo:
mydoc <- addTitle(mydoc, "Imagen satelital de Distrito Telef\u00F3nica")

# (*) Primera imagen:
mydoc <- addImage(mydoc, "input/DC1.jpg")

# (*) Segunda imagen:
mydoc <- addImage(mydoc, "input/DC2.jpg")

# (*) Cabecera de la primera imagen:
h1_pot <- pot(format(as.Date(substr(images_info$first$date, 0, 10), format="%Y-%m-%d"), format="%d-%m-%Y"),
              textProperties(color="#0B0B3B", font.size=20, font.weight="bold", font.family = "Calibri"))
mydoc <- addParagraph(mydoc, h1_pot, par.properties=parProperties(text.align="left"))

# (*) Cabecera de la segunda imagen:
h2_pot <- pot(format(as.Date(substr(images_info$second$date, 0, 10), format="%Y-%m-%d"), format="%d-%m-%Y"),
              textProperties(color="#0B0B3B", font.size=20, font.weight="bold", font.family = "Calibri"))
mydoc <- addParagraph(mydoc, h2_pot, par.properties=parProperties(text.align="left"))


# (*) Pie de pagina:
mydoc <- addFooter(mydoc, "Im\u00E1genes de la NASA cedidas por 'Google Earth Engine' (https://api.nasa.gov/api.html#earth)")
mydoc <- addDate(mydoc, format(Sys.Date(), "%d-%m-%Y"))
mydoc <- addPageNumber(mydoc)



# --------------------------------------------------------------
# PORTADA FINAL
# --------------------------------------------------------------
# (*) Incluir layout:
mydoc <- addSlide(mydoc, "Section")

# (*) Titulo:
mydoc <- addTitle(mydoc, "FIN")

# (*) Subtitulo:
mydoc <- addSubtitle(mydoc, "\"Hemos averiguado que vivimos en un insignificante planeta, de una triste estrella perdida, en una galaxia metida en una esquina olvidada de un universo, en el cual hay muchas mas galaxias que personas\"")
mydoc <- addParagraph(mydoc, pot("Carl Sagan", hyperlink="https://es.wikipedia.org/wiki/Carl_Sagan"))


# --------------------------------------------------------------
# WRITE PPTX
# --------------------------------------------------------------
# Crear el directorio "out" si no existe
dir.create("out", showWarnings=FALSE)

# ReporteRS: escribir el documento a disco
writeDoc(mydoc, "out/Universe.pptx")



