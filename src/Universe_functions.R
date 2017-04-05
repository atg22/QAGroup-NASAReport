###################################################################################################
# FUNCTIONS
###################################################################################################

# ------------------------------------------------------------------------------------
# GEOLOCALIZACION: DEVOLVER DATAFRAME CON INFORMACION DE LA DIRECCION
#                  A PARTIR DEL PUNTO DE GEOLOCALIZACION
# ------------------------------------------------------------------------------------
get_location_from_geolocation <- function(lat, long) {

  # Consultar el API de Google para resolver el nombre
  # https://developers.google.com/maps/documentation/geocoding/intro
  location_json <- fromJSON(paste("http://maps.googleapis.com/maps/api/geocode/json?latlng=",
                                        lat, ",", long, "&sensor=false", sep=""))
  
  # Devolver el dataframe del nivel 1 del json resultante (tiene toda la informacion)
  location_df <- location_json$results$address_components[[1]]
  location_df <- data.frame(lapply(location_df, as.character), stringsAsFactors=FALSE)
  
  return(location_df)
  
} 

# -------------------------------------
# CHANGE DATAFRAME ENCODING
# -------------------------------------
change_dataframe_encoding <- function(df, encfrom, encto) {
  
  for (row_i in 1:nrow(df)) { 
    for (col_j in 1:ncol(df)) { 
      df[row_i, col_j] = iconv(df[row_i, col_j], from=encfrom, to=encto)
    }
  }
  
  return(df)
}
