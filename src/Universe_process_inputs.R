###################################################################################################
# FUNCTIONS
###################################################################################################


# --------------------------------------------------------------
# CONECTA CON NASA Y DESCARGA FICHERO .CSV DE METEORITOS
# --------------------------------------------------------------
get_CSV_nasa_meteoritos <- function() {

  # (*) Descarga del fichero .CSV de NASA
  download.file('https://data.nasa.gov/api/views/gh4g-9sfh/rows.csv?accessType=DOWNLOAD', 'input/meteoritos.csv', method="curl")
  
  # (*) Cargar el fichero en un dataframe
  #meteoritos_df <- read.csv('https://data.nasa.gov/api/views/gh4g-9sfh/rows.csv?accessType=DOWNLOAD', sep=",", stringsAsFactors=FALSE) 
  meteoritos_df <- read.csv('input/meteoritos.csv', sep=",", stringsAsFactors=FALSE)
  
  # (*) Formatear valor de la columna 'year' de 'dd/MM/yyyy HH:mm:ss AM/PM' a 'yyyy'
  meteoritos_df$year <- substr(meteoritos_df$year, 7, 10)
  
  # (*) Convertir el valor de la columna de masa a numerico
  meteoritos_df$mass..g. <- as.numeric(meteoritos_df$mass..g.)
  
  return(meteoritos_df)
  
}

# -------------------------------------------------------------
# GENERA UN NUEVO DATAFRAME CON LOS METEORITOS DE ESPANA
# -------------------------------------------------------------
get_spain_meteorites <- function(meteoritos_df) {
  
  # (*) Inicialmente filtramos por cercania a la geolocalizacion de Espana
  #     (para elegir la longitud/latitud nos hemos ayudado con https://www.mapdevelopers.com/reverse_geocode_tool.php)
  meteoritos_spain_df <- meteoritos_df[!(is.na(meteoritos_df$reclat)) & as.numeric(meteoritos_df$reclat)<=44 & as.numeric(meteoritos_df$reclat)>=35 &
                                         !(is.na(meteoritos_df$reclong)) & as.numeric(meteoritos_df$reclong)>=-10 & as.numeric(meteoritos_df$reclong)<=4.5, ]
  
  # (*) De los meteoritos que estimamos de Espana o cercanos a ella, hallamos la direccion verdadera via API de Google
  #     https://developers.google.com/maps/documentation/geocoding/intro
  
  # - inicializar las nuevas columnas del dataframe
  meteoritos_spain_df$locality <- ""
  meteoritos_spain_df$area <- ""
  meteoritos_spain_df$country <- ""

  # - para cada fila del dataframe de meteoritos potencialmente de Espana...
  for (i in 1:nrow(meteoritos_spain_df)) {
    
    # ... extraer la fila
    met_sp <- meteoritos_spain_df[i,]
    
    # ... dormir 0.15 segundos para que todas las peticiones a la API de Google sean respondidas y gestionadas
    Sys.sleep(0.15) 
    
    # ... conectar con Google para hacer la resolucion de latitude/longitude a direccion geografica
    location_df <- get_location_from_geolocation(met_sp$reclat, met_sp$reclong)
    
    # ... incluir la informacion en las nuevas columnas de nuestro dataframe
    meteoritos_spain_df[i, ]$locality <- ifelse(nrow(location_df[location_df$types=="c(\"locality\", \"political\")", ])==0, 
                                                "", 
                                                location_df[location_df$types=="c(\"locality\", \"political\")", ]$long_name)
    meteoritos_spain_df[i, ]$area <- ifelse(nrow(location_df[location_df$types=="c(\"administrative_area_level_1\", \"political\")", ])==0,
                                            "", 
                                            location_df[location_df$types=="c(\"administrative_area_level_1\", \"political\")", ]$long_name)
    meteoritos_spain_df[i, ]$country <- ifelse(nrow(location_df[location_df$types=="c(\"country\", \"political\")", ])==0,
                                               "",
                                               location_df[location_df$types=="c(\"country\", \"political\")", ]$long_name)
  }
  
  # (*) Filtramos los que realmente son de Espana
  meteoritos_spain_df <- meteoritos_spain_df[meteoritos_spain_df$country=="Spain", ]
  
  # (*) Cambiamos el encoding (los nombres y lugares de Espana pueden llevar caracteres especiales: tildes...)
  meteoritos_spain_df <- change_dataframe_encoding(meteoritos_spain_df, "utf-8", "windows-1252")
  
  # (*) Convertimos de nuevo la masa a numerico (ha pasado a tipo 'character' con el cambio de encoding)
  meteoritos_spain_df$mass..g. <- as.numeric(meteoritos_spain_df$mass..g.)
  
  return (meteoritos_spain_df)
}


# ------------------------------------------------------------------------
# CONECTA VIA API REST CON NASA PARA DESCARGAR IMAGENES SATELITALES
# (Astronomic Picture Of the Day)
# ------------------------------------------------------------------------
get_API_nasa_Satellite_DC_images <- function(nasa_key) {
  
  # Parametros
  DC_longitude <- "-3.66436260"
  DC_latitude <- "40.5136436"
  currentdate <- format(Sys.Date(), "%Y-%m-%d")
  lastyeardate <- format(Sys.Date()-years(1), "%Y-%m-%d")
  
  # Conectar via API REST y conseguir las fechas para las cuales hay imagenes disponibles.
  # (el satélite pasa por un mismo punto de la Tierra cada 16 dias aproximadamente)
  #Sys.sleep(60)
  dates_list <- fromJSON(paste("https://api.nasa.gov/planetary/earth/assets?lon=",
                               DC_longitude, "&lat=", DC_latitude, 
                               "&begin=", lastyeardate, "&end=", currentdate, 
                               "&api_key=", nasa_key, sep=""))
  dates_df <- dates_list$results
  dates <- substr(dates_df$date, 0, 10)
  dates <- sort(dates)
  
  # Descargar la primera imagen disponible que no este nublada
  for (date in dates) {
    
    #Sys.sleep(60)
    first_image_info <- fromJSON(paste("https://api.nasa.gov/planetary/earth/imagery?lon=",
                                 DC_longitude, "&lat=", DC_latitude, 
                                 "&date=", date, "&cloud_score=True&api_key=", nasa_key, sep=""))
    
    if (!(is.null(first_image_info$cloud_score))) {
      if (as.numeric(first_image_info$cloud_score)<0.25) {
        #Sys.sleep(60)
        download.file(first_image_info$url, 'input/DC1.jpg', mode='wb')
        break
      }
    }
    
  }  
  
  # Descargar la ultima imagen disponible que no este nublada
  for (date in rev(dates)) {
    
    #Sys.sleep(60)
    second_image_info <- fromJSON(paste("https://api.nasa.gov/planetary/earth/imagery?lon=",
                                       DC_longitude, "&lat=", DC_latitude, 
                                       "&date=", date, "&cloud_score=True&api_key=", nasa_key, sep=""))
    
    if (!(is.null(second_image_info$cloud_score))) {
      if (as.numeric(second_image_info$cloud_score)<0.25) {
        #Sys.sleep(60)
        download.file(second_image_info$url, 'input/DC2.jpg', mode='wb')
        break
      }
    }
    
  }  
  
  images_info <- list("first"=first_image_info, "second"=second_image_info)
  return (images_info)
  
}
