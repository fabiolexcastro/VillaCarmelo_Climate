

# Load libraries ----------------------------------------------------------
require(pacman)
pacman::p_load(raster, rgdal, rgeos, stringr, sf, tidyverse, gtools)

g <- gc(reset = TRUE)
rm(list = ls())

# Functions to use --------------------------------------------------------
calc_difference <- function(vr, gc){
  
  # vr <- vrs[1]
  # gc <- gcm[1]
  
  cat('\tCurrent')
  cr <- grep(vr, crn, value = T)
  cr <- stack(cr)
  
  cat('\tFuture')
  fr <- paste0('../datos/raster/climate/ipcc/rcp85/2030s/', gc) 
  fr <- list.files(fr, full.names = T, pattern = '.tif$') 
  fr <- grep(vr, fr, value = T)
  fr <- mixedsort(fr)
  fr <- stack(fr)
  
  cat('\tDifference')
  df <- fr - cr
  pr <- df / cr * 100
  
  cat('\tTo write')
  Map('writeRaster', x = unstack(df), filename = paste0('../datos/output/climate/difference/2030s/', gc, '_', vr, '_', 1:12, '_dfr.tif'), overwrite = TRUE)
  Map('writeRaster', x = unstack(pr), filename = paste0('../datos/output/climate/difference/2030s/', gc, '_', vr, '_', 1:12, '_prc.tif'), overwrite = TRUE)
  
}

# Load data ---------------------------------------------------------------
shp <- shapefile('../datos/shapefiles/base/AOP/Area_estudio.shp')

# Project the shapefile
shp <- spTransform(x = shp, CRSobj = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')

# Read climate data -------------------------------------------------------
vrs <- c('prec', 'tmax', 'tmean', 'tmin')

# Current 
crn <- list.files('../datos/raster/climate/worldclim/villamontes', full.names = T, pattern = '.tif$') %>% 
  mixedsort()
gcm <- list.files('../datos/raster/climate/ipcc/rcp85/2030s')

# To calculating the difference -------------------------------------------
lapply(1:length(gcm), function(k){
  
  print(gcm[k])
  calc_difference(vr = 'tmax', gc = gcm[k])
  
})

